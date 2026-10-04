extends Node2D

var background: Texture2D

func _ready() -> void:
	background = load("res://assets/environment/crossroads-night.png")
	queue_redraw()

func _draw() -> void:
	if not background:
		return
	# Repaint only objects that visually sit in front of the character.
	for region in [
		Rect2(0, 442, 272, 206),
		Rect2(585, 463, 505, 185),
		Rect2(1050, 250, 102, 398)
	]:
		draw_texture_rect_region(background, region, region)
