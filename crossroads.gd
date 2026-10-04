extends Node2D
## Deterministic vector scenery: no large background texture.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1152, 648), Color("294039"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 406
	for i in range(720):
		var p := Vector2(rng.randf_range(24, 1128), rng.randf_range(24, 624))
		draw_line(p, p + Vector2(2, -3), Color(0.40, 0.53, 0.35, 0.22), 1)
	draw_rect(Rect2(0, 191, 1152, 266), Color("172a29"))
	draw_rect(Rect2(447, 0, 258, 648), Color("172a29"))
	draw_rect(Rect2(0, 197, 1152, 254), Color("7c8984"))
	draw_rect(Rect2(453, 0, 246, 648), Color("7c8984"))
	for x in range(0, 1152, 32):
		if x < 453 or x > 699:
			draw_line(Vector2(x, 197), Vector2(x, 221), Color("53665f"), 1)
			draw_line(Vector2(x, 427), Vector2(x, 451), Color("53665f"), 1)
	for y in range(0, 648, 32):
		if y < 197 or y > 451:
			draw_line(Vector2(453, y), Vector2(477, y), Color("53665f"), 1)
			draw_line(Vector2(675, y), Vector2(699, y), Color("53665f"), 1)
	draw_rect(Rect2(0, 221, 1152, 206), Color("343e46"))
	draw_rect(Rect2(477, 0, 198, 648), Color("343e46"))
	for i in range(950):
		var p := Vector2(rng.randf_range(0, 1152), rng.randf_range(0, 648))
		if (p.y > 223 and p.y < 425) or (p.x > 479 and p.x < 673):
			draw_circle(p, rng.randf_range(0.4, 1.1), Color(0.6, 0.66, 0.7, 0.065))
	for x in range(0, 1152, 62):
		if x < 360 or x > 735:
			draw_rect(Rect2(x, 322, 30, 4), Color("c6bd89"))
	for y in range(0, 648, 54):
		if y < 135 or y > 465:
			draw_rect(Rect2(574, y, 4, 27), Color("c6bd89"))
	for i in range(7):
		for x in [405, 721]:
			draw_rect(Rect2(x, 237 + i * 25, 27, 13), Color("c8cfbf"))
		for y in [160, 461]:
			draw_rect(Rect2(491 + i * 25, y, 13, 27), Color("c8cfbf"))
	for p in [Vector2(434, 338), Vector2(712, 229)]:
		draw_rect(Rect2(p, Vector2(4, 79)), Color("b7bdb0"))
	for p in [Vector2(486, 191), Vector2(586, 451)]:
		draw_rect(Rect2(p, Vector2(79, 4)), Color("b7bdb0"))
	for p in [Vector2(405, 150), Vector2(746, 150), Vector2(405, 502), Vector2(746, 502)]:
		draw_circle(p + Vector2(4, 6), 25, Color(0.05, 0.12, 0.10, 0.35))
		draw_circle(p, 23, Color("52664c"))
		draw_circle(p + Vector2(-4, -4), 17, Color("66805b"))
		for i in range(6):
			draw_circle(p + Vector2(rng.randf_range(-13, 13), rng.randf_range(-13, 13)), 2, Color("b7b683"))
	draw_rect(Rect2(24, 24, 1104, 600), Color("a4b2a0"), false, 5)
	draw_rect(Rect2(32, 32, 1088, 584), Color(0.14, 0.22, 0.18, 0.6), false, 2)
