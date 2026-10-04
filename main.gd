extends Node2D

const DIRECTIONS := ["down", "left", "right", "up"]
const SPEED := 230.0
const DEADZONE := 0.15
const ATTACK_DURATION := 0.58
const ATTACK_ENDS := [0.09, 0.15, 0.20, 0.25, 0.31, 0.38, 0.46, 0.58]
var sheets: Dictionary = {}
var position_on_screen := Vector2(576, 350)
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
var pose_material := ShaderMaterial.new()
var attack_buffered := false
var run_offsets: Dictionary = {}

func _ready() -> void:
	var environment := Node2D.new()
	environment.set_script(load("res://crossroads.gd"))
	environment.z_index = -10
	add_child(environment)
	for action in ["idle", "run", "attack1"]:
		sheets[action] = {}
		for direction in DIRECTIONS:
			var folder: String = {"idle": "IDLE", "run": "RUN", "attack1": "ATTACK_1"}[action]
			sheets[action][direction] = load("res://assets/%s/%s_%s.png" % [folder, action, direction])
	for direction in DIRECTIONS:
		var source: Image = sheets["run"][direction].get_image()
		if source.is_compressed():
			source.decompress()
		var anchors: Array[Vector2] = []
		for frame in range(8):
			anchors.append(_head_anchor(source, frame))
		var offsets: Array[Vector2] = []
		for anchor in anchors:
			offsets.append(anchors[0] - anchor)
		run_offsets[direction] = offsets
	pose_material.shader = load("res://character.gdshader")
	sprite.material = pose_material
	sprite.hframes = 8
	sprite.scale = Vector2.ONE * 0.67
	add_child(sprite)
	_update_pose()

func _head_anchor(source: Image, frame: int) -> Vector2:
	# Measure the opaque head, not the coat or swinging feet. Read-only: the
	# original artwork is preserved. Limit scan to the upper part of each cell.
	var top := 0
	for y in range(100):
		var count := 0
		for x in range(24, 232):
			var pixel := source.get_pixel(frame * 256 + x, y)
			if pixel.a > 0.85 and maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.65:
				count += 1
		if count >= 8:
			top = y
			break
	var total := 0.0
	var samples := 0
	for y in range(top, mini(top + 40, 256)):
		for x in range(24, 232):
			var pixel := source.get_pixel(frame * 256 + x, y)
			if pixel.a > 0.85 and maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.65:
				total += x
				samples += 1
	return Vector2(total / maxf(samples, 1), top)

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

func _process(delta: float) -> void:
	# Prevent a large movement jump after returning to a suspended browser tab.
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
			# Hysteresis prevents direction flicker near diagonals.
			if absf(movement.x) > absf(movement.y) * 1.15:
				facing = "right" if movement.x > 0 else "left"
			elif absf(movement.y) > absf(movement.x) * 1.15:
				facing = "down" if movement.y > 0 else "up"
			elif (facing == "left" and movement.x > 0) or (facing == "right" and movement.x < 0):
				facing = "right" if movement.x > 0 else "left"
			elif (facing == "up" and movement.y > 0) or (facing == "down" and movement.y < 0):
				facing = "down" if movement.y > 0 else "up"
			var previous := position_on_screen
			position_on_screen = (position_on_screen + movement * SPEED * delta).clamp(Vector2(88, 160), Vector2(1064, 580))
			run_phase += position_on_screen.distance_to(previous) / 150.0 * 8.0
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
	elif state == "attack1":
		while frame < 7 and clock >= ATTACK_ENDS[frame]:
			frame += 1
	# Stable source pose; breathe only at the shoulders, never rescale the feet.
	sprite.texture = sheets[state][facing]
	sprite.frame = frame
	sprite.position = position_on_screen - Vector2(0, 79)
	if state == "run":
		sprite.position += run_offsets[facing][frame] * sprite.scale.x
		sprite.position.y -= sin(run_phase * PI / 2.0) * 0.8
	pose_material.set_shader_parameter("attack_pose", state == "attack1")
	pose_material.set_shader_parameter("breath", sin(idle_clock * 2.4) * 0.9 if state == "idle" else 0.0)

func _draw() -> void:
	draw_set_transform(position_on_screen - Vector2(0, 4), 0, Vector2(1, 0.32))
	draw_circle(Vector2.ZERO, 34, Color(0.025, 0.06, 0.08, 0.30))
	draw_set_transform(Vector2.ZERO)
	if state == "attack1":
		_draw_slash()
	_draw_controls()

func _draw_slash() -> void:
	var progress := clampf((clock - 0.09) / 0.33, 0.0, 1.0)
	if progress <= 0.0 or progress >= 1.0:
		return
	var direction_angle: float = {"right": 0.0, "down": PI / 2.0, "left": PI, "up": -PI / 2.0}[facing]
	var tip := direction_angle - 1.8 + progress * 5.2
	var points := PackedVector2Array()
	var center := position_on_screen - Vector2(0, 65)
	for i in range(33):
		var angle := tip - float(32 - i) / 32.0 * 1.9
		points.append(center + Vector2(cos(angle) * 116, sin(angle) * 66))
	var strength := sin(progress * PI)
	draw_polyline(points, Color(0.03, 0.8, 1.0, 0.12 * strength), 22, true)
	draw_polyline(points, Color(0.08, 0.82, 1.0, 0.48 * strength), 10, true)
	draw_polyline(points, Color(0.78, 0.99, 1.0, 0.95 * strength), 3, true)

func _draw_controls() -> void:
	draw_circle(joystick_center, 82, Color(0.04, 0.10, 0.13, 0.56))
	draw_arc(joystick_center, 82, 0, TAU, 64, Color(0.65, 0.84, 0.83, 0.55), 2, true)
	draw_circle(joystick_center + joystick_vector * 55, 32, Color(0.63, 0.82, 0.81, 0.8))
	draw_circle(attack_center, 61, Color(0.04, 0.12, 0.17, 0.88))
	draw_arc(attack_center, 61, 0, TAU, 64, Color(0, 0.75, 0.95), 3, true)
	if state == "attack1":
		draw_arc(attack_center, 67, -PI / 2, -PI / 2 + TAU * clock / ATTACK_DURATION, 48, Color("d9ffff"), 3, true)
	draw_string(ThemeDB.fallback_font, attack_center + Vector2(-31, 6), "ATTACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(35, 55), "CROSSROADS / v0.0.6", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e4eada"))
