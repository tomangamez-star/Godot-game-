extends Node2D

const DIRECTIONS := ["down", "left", "right", "up"]
const SPEED := 210.0
const DEADZONE := 0.15
const CHARACTER_SCALE := 0.55
const ATTACK_DURATION := 0.58
const ATTACK_ENDS := [0.09, 0.15, 0.20, 0.25, 0.31, 0.38, 0.46, 0.58]
const ATTACK2_DURATION := 0.82
const ATTACK2_ENDS := [0.07, 0.12, 0.18, 0.24, 0.31, 0.38, 0.45, 0.53, 0.59, 0.65, 0.71, 0.82]
const ATTACK2_FRAMES := [0, 1, 2, 3, 4, 5, 6, 7, 3, 4, 6, 7]
const IDLE_SIDE_SEQUENCE := [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]
const IDLE_VERTICAL_SEQUENCE := [0, 1, 2, 3, 2, 1]
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
var pose_anchors: Dictionary = {}
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
var attack2_center := Vector2(929, 447)
var mouse_joystick := false
var sprite := Sprite2D.new()
var reflection := Sprite2D.new()
var pose_material := ShaderMaterial.new()
var attack_buffered := false
var queued_attack := ""

func _ready() -> void:
	var environment := Node2D.new()
	environment.set_script(load("res://crossroads.gd"))
	environment.z_index = -10
	add_child(environment)
	for action in ["idle", "run", "attack1"]:
		sheets[action] = {}
		anchors[action] = {}
		pose_anchors[action] = {}
		for direction in DIRECTIONS:
			var folder: String = {"idle": "IDLE", "run": "RUN", "attack1": "ATTACK_1"}[action]
			var texture: Texture2D = load("res://assets/%s/%s_%s.png" % [folder, action, direction])
			sheets[action][direction] = texture
			anchors[action][direction] = _measure_foot_anchors(texture)
			pose_anchors[action][direction] = anchors[action][direction].duplicate()
			if (action == "run" and direction in ["left", "right"]) or (action == "idle" and direction in ["up", "down"]):
				for frame in range(8):
					var stable_anchor: Vector2 = pose_anchors[action][direction][frame]
					stable_anchor.x = _measure_torso_x(texture, frame)
					pose_anchors[action][direction][frame] = stable_anchor
	# Attack 2 deliberately reuses the clean character art. Its second strike,
	# timing, lunge and layered energy are authored in code, keeping this patch tiny.
	sheets["attack2"] = sheets["attack1"]
	anchors["attack2"] = anchors["attack1"]
	pose_anchors["attack2"] = pose_anchors["attack1"]
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

func _measure_torso_x(texture: Texture2D, frame: int) -> float:
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	var total_x := 0.0
	var samples := 0
	# Head/torso only: legs alternate widely during side runs and must never
	# control horizontal placement.
	for y in range(42, 166):
		for x in range(36, 220):
			if image.get_pixel(frame * 256 + x, y).a > 0.62:
				total_x += x
				samples += 1
	return total_x / maxf(samples, 1)

func _pose_anchor(action: String, direction: String, frame: int) -> Vector2:
	return pose_anchors[action][direction][frame]

func _attack() -> void:
	if not state.begins_with("attack"):
		state = "attack1"
		clock = 0.0
	elif state == "attack1" and clock > ATTACK_DURATION - 0.16:
		attack_buffered = true

func _attack2() -> void:
	if not state.begins_with("attack"):
		state = "attack2"
		clock = 0.0
	elif clock > 0.38:
		queued_attack = "attack2"

func _update_joystick(point: Vector2) -> void:
	var raw := ((point - joystick_center) / 70.0).limit_length(1.0)
	joystick_vector = Vector2.ZERO if raw.length() < DEADZONE else raw.normalized() * inverse_lerp(DEADZONE, 1.0, raw.length())

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		joystick_vector = Vector2.ZERO
		joystick_id = -1
		mouse_joystick = false
		attack_buffered = false
		queued_attack = ""

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.distance_to(joystick_center) < 105 and joystick_id == -1:
				joystick_id = event.index
				_update_joystick(event.position)
			elif event.position.distance_to(attack_center) < 70:
				_attack()
			elif event.position.distance_to(attack2_center) < 55:
				_attack2()
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
			elif event.position.distance_to(attack2_center) < 55:
				_attack2()
		else:
			mouse_joystick = false
			if joystick_id == -1:
				joystick_vector = Vector2.ZERO
	elif event is InputEventMouseMotion and mouse_joystick:
		_update_joystick(event.position)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_attack()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_attack2()

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
	if state.begins_with("attack"):
		var duration := ATTACK2_DURATION if state == "attack2" else ATTACK_DURATION
		if clock >= duration:
			state = "idle"
			clock = 0.0
			if queued_attack == "attack2":
				queued_attack = ""
				_attack2()
			elif attack_buffered:
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
		var idle_sequence: Array = IDLE_VERTICAL_SEQUENCE if facing in ["up", "down"] else IDLE_SIDE_SEQUENCE
		frame = idle_sequence[int(idle_clock * 5.0) % idle_sequence.size()]
	elif state == "attack2":
		var step := 0
		while step < ATTACK2_ENDS.size() - 1 and clock >= ATTACK2_ENDS[step]:
			step += 1
		frame = ATTACK2_FRAMES[step]
	else:
		while frame < 7 and clock >= ATTACK_ENDS[frame]:
			frame += 1
	var anchor: Vector2 = _pose_anchor(state, facing, frame)
	var placement := position_on_screen - (anchor - Vector2(128, 128)) * CHARACTER_SCALE
	if state == "attack2":
		var direction_vector: Vector2 = {"right": Vector2.RIGHT, "down": Vector2.DOWN, "left": Vector2.LEFT, "up": Vector2.UP}[facing]
		placement += direction_vector * sin(clampf(clock / ATTACK2_DURATION, 0.0, 1.0) * PI) * 8.0
	sprite.texture = sheets[state][facing]
	sprite.frame = frame
	sprite.position = placement
	sprite.scale = Vector2.ONE * CHARACTER_SCALE
	reflection.texture = sprite.texture
	reflection.frame = frame
	reflection.position = Vector2(placement.x, position_on_screen.y + (anchor.y - 128.0) * 0.16 + 3)
	pose_material.set_shader_parameter("attack_pose", state.begins_with("attack"))
	pose_material.set_shader_parameter("breath", 0.0)

func _draw() -> void:
	var pulse := 0.96 + sin(idle_clock * 2.0) * 0.025 if state == "idle" else 1.0
	draw_set_transform(position_on_screen - Vector2(0, 2), 0, Vector2(pulse, 0.30))
	draw_circle(Vector2.ZERO, 25, Color(0.005, 0.015, 0.025, 0.56))
	draw_set_transform(Vector2.ZERO)
	if state == "attack1":
		_draw_slash()
	elif state == "attack2":
		_draw_attack2()

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

func _draw_attack2() -> void:
	var progress := clampf(clock / ATTACK2_DURATION, 0.0, 1.0)
	var direction_angle: float = {"right": 0.0, "down": PI / 2.0, "left": PI, "up": -PI / 2.0}[facing]
	var center := position_on_screen - Vector2(0, 47)
	# Two opposing crescents form a fast cross-cut, then collapse into a flash.
	for cut_index in range(2):
		var local := clampf((progress - float(cut_index) * 0.26) / 0.56, 0.0, 1.0)
		if local <= 0.0 or local >= 1.0:
			continue
		var points := PackedVector2Array()
		var sweep_sign := 1.0 if cut_index == 0 else -1.0
		var tip := direction_angle + sweep_sign * (-2.0 + local * 4.8)
		for i in range(29):
			var angle := tip - sweep_sign * float(28 - i) / 28.0 * 1.55
			points.append(center + Vector2(cos(angle) * 104, sin(angle) * 58))
		var strength := sin(local * PI)
		draw_polyline(points, Color(0.28, 0.05, 0.75, 0.20 * strength), 21, true)
		draw_polyline(points, Color(0.23, 0.56, 1.0, 0.68 * strength), 9, true)
		draw_polyline(points, Color(0.88, 0.98, 1.0, strength), 3, true)
	if progress > 0.57 and progress < 0.88:
		var burst := sin(inverse_lerp(0.57, 0.88, progress) * PI)
		draw_circle(center, 9 + burst * 19, Color(0.55, 0.90, 1.0, 0.34 * burst))
		draw_arc(center, 25 + burst * 44, 0, TAU, 48, Color(0.43, 0.28, 1.0, 0.76 * burst), 5, true)
