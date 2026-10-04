extends Node2D

const DIRECTIONS := ["down", "left", "right", "up"]
const SPEED := 210.0
const DEADZONE := 0.15
const CHARACTER_SCALE := 0.55
const ATTACK_DURATION := 0.58
const ATTACK_ENDS := [0.09, 0.15, 0.20, 0.25, 0.31, 0.38, 0.46, 0.58]
const IDLE_SEQUENCE := [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]
var WALKABLE := PackedVector2Array([
	Vector2(48, 152), Vector2(220, 148), Vector2(292, 190),
	Vector2(420, 157), Vector2(615, 103), Vector2(735, 71),
	Vector2(1078, 88), Vector2(1100, 397), Vector2(1035, 471),
	Vector2(925, 491), Vector2(790, 447), Vector2(681, 420),
	Vector2(603, 421), Vector2(534, 493), Vector2(394, 523),
	Vector2(178, 548), Vector2(54, 441)
])
var BLOCKERS := [
	Rect2(51, 174, 183, 139),  # wrecked SUV and fire
	Rect2(165, 70, 132, 100),  # parked car
	Rect2(893, 101, 104, 111), # road barrier
	Rect2(46, 370, 83, 98)     # lower-left street furniture
]

var sheets: Dictionary = {}
var anchors: Dictionary = {}
var position_on_screen := Vector2(576, 365)
var facing := "down"
var state := "idle"
var clock := 0.0
var run_phase := 0.0
var idle_clock := 0.0
var joystick_id := -1
var joystick_vector := Vector2.ZERO
var joystick_center := Vector2(115, 533)
var attack_center := Vector2(1037, 533)
var mouse_joystick := false
var sprite := Sprite2D.new()
var reflection := Sprite2D.new()
var pose_material := ShaderMaterial.new()
var attack_buffered := false

func _ready() -> void:
	var environment := Node2D.new()
	environment.set_script(load("res://crossroads.gd"))
	environment.z_index = -10
	add_child(environment)
	for action in ["idle", "run", "attack1"]:
		sheets[action] = {}
		anchors[action] = {}
		for direction in DIRECTIONS:
			var folder: String = {"idle": "IDLE", "run": "RUN", "attack1": "ATTACK_1"}[action]
			var texture: Texture2D = load("res://assets/%s/%s_%s.png" % [folder, action, direction])
			sheets[action][direction] = texture
			anchors[action][direction] = _measure_foot_anchors(texture)
	pose_material.shader = load("res://character.gdshader")
	sprite.material = pose_material
	sprite.hframes = 8
	sprite.scale = Vector2.ONE * CHARACTER_SCALE
	sprite.z_index = 0
	add_child(sprite)
	reflection.hframes = 8
	reflection.scale = Vector2(CHARACTER_SCALE, -0.16)
	reflection.modulate = Color(0.32, 0.73, 0.92, 0.11)
	reflection.z_index = -1
	add_child(reflection)
	var foreground := Node2D.new()
	foreground.set_script(load("res://foreground.gd"))
	foreground.z_index = 2
	add_child(foreground)
	var hud := Node2D.new()
	hud.set_script(load("res://hud.gd"))
	hud.z_index = 10
	add_child(hud)
	_update_pose()

func _measure_foot_anchors(texture: Texture2D) -> Array[Vector2]:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	var result: Array[Vector2] = []
	for frame in range(8):
		var bottom := 255
		while bottom > 0:
			var found := false
			for x in range(20, 236):
				if image.get_pixel(frame * 256 + x, bottom).a > 0.35:
					found = true
					break
			if found:
				break
			bottom -= 1
		var total_x := 0.0
		var samples := 0
		for y in range(maxi(0, bottom - 13), bottom + 1):
			for x in range(20, 236):
				if image.get_pixel(frame * 256 + x, y).a > 0.55:
					total_x += x
					samples += 1
		result.append(Vector2(total_x / maxf(samples, 1), bottom))
	return result

func _attack() -> void:
	if state != "attack1":
		state = "attack1"
		clock = 0.0
	elif clock > ATTACK_DURATION - 0.16:
		attack_buffered = true

func _update_joystick(point: Vector2) -> void:
	var raw := ((point - joystick_center) / 70.0).limit_length(1.0)
	joystick_vector = Vector2.ZERO if raw.length() < DEADZONE else raw.normalized() * inverse_lerp(DEADZONE, 1.0, raw.length())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		joystick_vector = Vector2.ZERO
		joystick_id = -1
		mouse_joystick = false
		attack_buffered = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center) < 105 and joystick_id == -1:
				joystick_id = event.index
				_update_joystick(event.position)
			elif event.position.distance_to(attack_center) < 70:
				_attack()
		elif event.index == joystick_id:
			joystick_id = -1
			joystick_vector = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joystick_id:
		_update_joystick(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if event.position.distance_to(joystick_center) < 105:
				mouse_joystick = true
				_update_joystick(event.position)
			elif event.position.distance_to(attack_center) < 70:
				_attack()
		else:
			mouse_joystick = false
			if joystick_id == -1:
				joystick_vector = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_joystick:
		_update_joystick(event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_attack()

func _can_stand(point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, WALKABLE):
		return false
	for blocker in BLOCKERS:
		if blocker.grow(12).has_point(point):
			return false
	return true

func _move_with_collisions(motion: Vector2) -> void:
	var x_target := position_on_screen + Vector2(motion.x, 0)
	if _can_stand(x_target):
		position_on_screen = x_target
	var y_target := position_on_screen + Vector2(0, motion.y)
	if _can_stand(y_target):
		position_on_screen = y_target

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	clock += delta
	idle_clock += delta
	var movement := joystick_vector
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if keyboard.length() > 0:
		movement = keyboard.normalized()
	if state == "attack1":
		if clock >= ATTACK_DURATION:
			state = "idle"
			clock = 0.0
			if attack_buffered:
				attack_buffered = false
				_attack()
	else:
		var next_state := "run" if movement.length() > 0.01 else "idle"
		if next_state != state:
			state = next_state
			clock = 0.0
		if state == "run":
			if absf(movement.x) > absf(movement.y) * 1.15:
				facing = "right" if movement.x > 0 else "left"
			elif absf(movement.y) > absf(movement.x) * 1.15:
				facing = "down" if movement.y > 0 else "up"
			elif (facing == "left" and movement.x > 0) or (facing == "right" and movement.x < 0):
				facing = "right" if movement.x > 0 else "left"
			elif (facing == "up" and movement.y > 0) or (facing == "down" and movement.y < 0):
				facing = "down" if movement.y > 0 else "up"
			var previous := position_on_screen
			_move_with_collisions(movement * SPEED * delta)
			run_phase += position_on_screen.distance_to(previous) / 130.0 * 8.0
			if position_on_screen.is_equal_approx(previous):
				state = "idle"
	_update_pose()
	queue_redraw()

func _update_pose() -> void:
	if sheets.is_empty():
		return
	var frame := 0
	if state == "run":
		frame = int(run_phase) % 8
	elif state == "idle":
		frame = IDLE_SEQUENCE[int(idle_clock * 5.5) % IDLE_SEQUENCE.size()]
	else:
		while frame < 7 and clock >= ATTACK_ENDS[frame]:
			frame += 1
	var anchor: Vector2 = anchors[state][facing][frame]
	var placement := position_on_screen - (anchor - Vector2(128, 128)) * CHARACTER_SCALE
	sprite.texture = sheets[state][facing]
	sprite.frame = frame
	sprite.position = placement
	sprite.scale = Vector2.ONE * CHARACTER_SCALE
	reflection.texture = sprite.texture
	reflection.frame = frame
	reflection.position = Vector2(placement.x, position_on_screen.y + (anchor.y - 128.0) * 0.16 + 3)
	pose_material.set_shader_parameter("attack_pose", state == "attack1")
	pose_material.set_shader_parameter("breath", 0.0)

func _draw() -> void:
	var pulse := 0.96 + sin(idle_clock * 2.0) * 0.025 if state == "idle" else 1.0
	draw_set_transform(position_on_screen - Vector2(0, 2), 0, Vector2(pulse, 0.30))
	draw_circle(Vector2.ZERO, 25, Color(0.005, 0.015, 0.025, 0.56))
	draw_set_transform(Vector2.ZERO)
	if state == "attack1":
		_draw_slash()

func _draw_slash() -> void:
	var progress := clampf((clock - 0.09) / 0.33, 0.0, 1.0)
	if progress <= 0.0 or progress >= 1.0:
		return
	var direction_angle: float = {"right": 0.0, "down": PI / 2.0, "left": PI, "up": -PI / 2.0}[facing]
	var tip := direction_angle - 1.8 + progress * 5.2
	var points := PackedVector2Array()
	var center := position_on_screen - Vector2(0, 47)
	for i in range(33):
		var angle := tip - float(32 - i) / 32.0 * 1.9
		points.append(center + Vector2(cos(angle) * 92, sin(angle) * 52))
	var strength := sin(progress * PI)
	draw_polyline(points, Color(0.03, 0.8, 1.0, 0.12 * strength), 18, true)
	draw_polyline(points, Color(0.08, 0.82, 1.0, 0.48 * strength), 8, true)
	draw_polyline(points, Color(0.78, 0.99, 1.0, 0.95 * strength), 3, true)
