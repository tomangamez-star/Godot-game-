extends Node2D

const MAX_HEALTH := 100
const MOVE_SPEED := 112.0
const CHASE_RANGE := 470.0
const ATTACK_RANGE := 70.0
const ATTACK_DURATION := 0.82
const ATTACK_COOLDOWN := 0.72
const FRAME_COUNT := 15

var game: Node
var sprite := Sprite2D.new()
var textures: Dictionary = {}
var health := MAX_HEALTH
var state := "idle"
var facing_row := 5
var animation_clock := 0.0
var cooldown := 0.0
var hit_player := false
var spawn_position := Vector2(810, 272)

func _ready() -> void:
	game = get_parent()
	textures = {
		"idle": load("res://assets/enemy/knight/Idle.png"),
		"run": load("res://assets/enemy/knight/Run.png"),
		"attack": load("res://assets/enemy/knight/Melee.png"),
		"hurt": load("res://assets/enemy/knight/TakeDamage.png"),
		"dead": load("res://assets/enemy/knight/Die.png")
	}
	position = spawn_position
	sprite.hframes = FRAME_COUNT
	sprite.vframes = 8
	sprite.position = Vector2(0, -43)
	sprite.scale = Vector2.ONE * 0.88
	add_child(sprite)
	_update_sprite()

func _direction_row(direction: Vector2) -> int:
	if direction.length_squared() < 0.001:
		return facing_row
	var sector := int(round(direction.angle() / (PI / 4.0)))
	return {0: 3, 1: 4, 2: 5, 3: 6, 4: 7, -4: 7, -3: 0, -2: 1, -1: 2}.get(sector, 5)

func _set_state(next_state: String) -> void:
	if next_state == state:
		return
	state = next_state
	animation_clock = 0.0
	if state == "attack":
		hit_player = false

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	animation_clock += delta
	cooldown = maxf(0.0, cooldown - delta)
	if state == "dead":
		if animation_clock >= 2.0:
			respawn()
		_update_sprite()
		queue_redraw()
		return
	if state == "hurt":
		if animation_clock >= 0.34:
			_set_state("idle")
		_update_sprite()
		queue_redraw()
		return
	var to_player: Vector2 = game.position_on_screen - position
	var distance := to_player.length()
	if state == "attack":
		facing_row = _direction_row(to_player)
		if not hit_player and animation_clock >= 0.31 and distance <= ATTACK_RANGE + 18.0:
			hit_player = true
			game._damage_player(10, to_player.normalized())
		if animation_clock >= ATTACK_DURATION:
			cooldown = ATTACK_COOLDOWN
			_set_state("idle")
	elif distance <= ATTACK_RANGE and cooldown <= 0.0:
		facing_row = _direction_row(to_player)
		_set_state("attack")
	elif distance <= CHASE_RANGE and distance > ATTACK_RANGE - 8.0:
		var direction := to_player.normalized()
		facing_row = _direction_row(direction)
		var motion := direction * MOVE_SPEED * delta
		var x_target := position + Vector2(motion.x, 0)
		if game._can_stand(x_target) and x_target.distance_to(game.position_on_screen) > 50.0:
			position.x = x_target.x
		var y_target := position + Vector2(0, motion.y)
		if game._can_stand(y_target) and y_target.distance_to(game.position_on_screen) > 50.0:
			position.y = y_target.y
		_set_state("run")
	else:
		_set_state("idle")
	_update_sprite()
	queue_redraw()

func _update_sprite() -> void:
	sprite.texture = textures[state]
	var fps: float = {"idle": 8.0, "run": 14.0, "attack": 18.0, "hurt": 20.0, "dead": 11.0}[state]
	var frame := mini(int(animation_clock * fps), FRAME_COUNT - 1)
	if state in ["idle", "run"]:
		frame = int(animation_clock * fps) % FRAME_COUNT
	sprite.frame = facing_row * FRAME_COUNT + frame
	sprite.modulate = Color(1.35, 0.62, 0.62) if state == "hurt" and int(animation_clock * 30.0) % 2 == 0 else Color.WHITE

func take_damage(amount: int, knock_direction: Vector2) -> void:
	if state == "dead":
		return
	health = maxi(0, health - amount)
	if health <= 0:
		_set_state("dead")
	else:
		var target := position + knock_direction.normalized() * 18.0
		if game._can_stand(target):
			position = target
		_set_state("hurt")
	queue_redraw()

func respawn() -> void:
	health = MAX_HEALTH
	position = spawn_position
	facing_row = 5
	cooldown = 0.5
	_set_state("idle")

func _draw() -> void:
	if state == "dead":
		return
	var width := 58.0
	var top := Vector2(-width / 2.0, -91)
	draw_rect(Rect2(top - Vector2(2, 2), Vector2(width + 4, 10)), Color(0.015, 0.02, 0.025, 0.88), true)
	draw_rect(Rect2(top, Vector2(width, 6)), Color(0.18, 0.035, 0.045, 0.96), true)
	draw_rect(Rect2(top, Vector2(width * float(health) / MAX_HEALTH, 6)), Color(0.93, 0.17, 0.21, 1.0), true)
