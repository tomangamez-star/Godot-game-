extends Node2D

const DIRECTIONS = ["down", "left", "right", "up"]
const SPEED = 230.0
const DEADZONE = 0.15
var sheets: Dictionary = {}
var position_on_screen = Vector2(576, 324)
var facing = "down"
var state = "idle"
var clock = 0.0
var joystick_id = -1
var joystick_vector = Vector2.ZERO
var joystick_center = Vector2(115, 533)
var attack_center = Vector2(1037, 533)
var mouse_joystick = false
var screen_size = Vector2(1152, 648)

func _ready() -> void:
	for action in ["idle", "run", "attack1"]:
		sheets[action] = {}
		for direction in DIRECTIONS:
			var folder = {"idle": "IDLE", "run": "RUN", "attack1": "ATTACK_1"}[action]
			sheets[action][direction] = load("res://assets/%s/%s_%s.png" % [folder, action, direction])
	get_viewport().size_changed.connect(_resize)
	_resize()

func _resize() -> void:
	screen_size = get_viewport_rect().size
	joystick_center = Vector2(115, screen_size.y - 115)
	attack_center = Vector2(screen_size.x - 115, screen_size.y - 115)
	position_on_screen = position_on_screen.clamp(Vector2(100, 110), screen_size - Vector2(100, 125))
	queue_redraw()

func _attack() -> void:
	if state != "attack1":
		state = "attack1"
		clock = 0.0

func _update_joystick(point: Vector2) -> void:
	joystick_vector = ((point - joystick_center) / 70.0).limit_length(1.0)
	if joystick_vector.length() < DEADZONE:
		joystick_vector = Vector2.ZERO

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
	if not DisplayServer.window_is_focused():
		joystick_vector = Vector2.ZERO
		joystick_id = -1
		mouse_joystick = false
	clock += delta
	var movement = joystick_vector
	var keyboard = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if keyboard.length() > 0:
		movement = keyboard.normalized()
	if state == "attack1":
		if clock >= 8.0 / (100.0 / 6.0):
			state = "idle"
			clock = 0.0
	else:
		var next_state = "run" if movement.length() > 0 else "idle"
		if next_state != state:
			state = next_state
			clock = 0.0
		if movement.length() > 0:
			if abs(movement.x) > abs(movement.y):
				facing = "right" if movement.x > 0 else "left"
			else:
				facing = "down" if movement.y > 0 else "up"
			position_on_screen += movement * SPEED * delta
			position_on_screen = position_on_screen.clamp(Vector2(100, 110), screen_size - Vector2(100, 125))
	queue_redraw()

func _draw() -> void:
	if sheets.is_empty():
		return
	var fps = 12.0 if state == "run" else (100.0 / 6.0 if state == "attack1" else 8.0)
	var frame = int(clock * fps) % 8
	if state == "attack1":
		frame = mini(int(clock * fps), 7)
	var texture: Texture2D = sheets[state][facing]
	draw_texture_rect_region(texture, Rect2(position_on_screen - Vector2(128, 128), Vector2(256, 256)), Rect2(frame * 256, 0, 256, 256))
	draw_circle(joystick_center, 82, Color(0.1, 0.15, 0.2, 0.10))
	draw_arc(joystick_center, 82, 0, TAU, 64, Color(0.15, 0.2, 0.25, 0.35), 3, true)
	draw_circle(joystick_center + joystick_vector * 55, 34, Color(0.15, 0.2, 0.25, 0.55))
	draw_circle(attack_center, 61, Color(0.04, 0.12, 0.17, 0.85))
	draw_arc(attack_center, 61, 0, TAU, 64, Color(0, 0.75, 0.95), 4, true)
	draw_string(ThemeDB.fallback_font, attack_center + Vector2(-31, 6), "ATTACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
