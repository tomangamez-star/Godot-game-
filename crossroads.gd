extends Node2D

var background: Texture2D
var rain: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	background = load("res://assets/environment/crossroads-night.png")
	rng.seed = 707
	for i in range(72):
		rain.append({
			"p": Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648)),
			"speed": rng.randf_range(280.0, 520.0),
			"length": rng.randf_range(5.0, 13.0),
			"alpha": rng.randf_range(0.08, 0.24)
		})
	queue_redraw()

func _process(delta: float) -> void:
	for drop in rain:
		var p: Vector2 = drop.p
		p += Vector2(-40.0, drop.speed) * delta
		if p.y > 654:
			p = Vector2(rng.randf_range(0, 1190), -drop.length)
		drop.p = p
	queue_redraw()

func _draw() -> void:
	if background:
		draw_texture_rect(background, Rect2(0, 0, 1152, 648), false)
	draw_rect(Rect2(0, 0, 1152, 648), Color(0.01, 0.025, 0.055, 0.08))
	for drop in rain:
		var p: Vector2 = drop.p
		draw_line(p, p + Vector2(-1.2, drop.length), Color(0.65, 0.82, 1.0, drop.alpha), 1.0)
