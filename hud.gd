extends Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var game = get_parent()
	var joystick: Vector2 = game.joystick_center
	var attack: Vector2 = game.attack_center
	var attack2: Vector2 = game.attack2_center
	draw_circle(joystick, 82, Color(0.02, 0.06, 0.10, 0.64))
	draw_arc(joystick, 82, 0, TAU, 64, Color(0.54, 0.83, 0.94, 0.68), 2, true)
	draw_circle(joystick + game.joystick_vector * 55, 32, Color(0.71, 0.84, 0.89, 0.84))
	draw_circle(attack, 61, Color(0.02, 0.06, 0.11, 0.90))
	draw_arc(attack, 61, 0, TAU, 64, Color(0.05, 0.76, 1.0), 3, true)
	if game.state == "attack1":
		draw_arc(attack, 67, -PI / 2, -PI / 2 + TAU * game.clock / game.ATTACK_DURATION, 48, Color("d9ffff"), 3, true)
	draw_string(ThemeDB.fallback_font, attack + Vector2(-31, 6), "ATTACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	draw_circle(attack2, 44, Color(0.055, 0.025, 0.13, 0.92))
	draw_arc(attack2, 44, 0, TAU, 48, Color(0.45, 0.34, 1.0), 3, true)
	if game.state == "attack2":
		draw_arc(attack2, 49, -PI / 2, -PI / 2 + TAU * game.clock / game.ATTACK2_DURATION, 40, Color(0.70, 0.92, 1.0), 3, true)
	draw_string(ThemeDB.fallback_font, attack2 + Vector2(-22, 6), "ATK 2", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(31, 48), "NIGHT CROSSROADS / v0.0.9", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.82, 0.92, 1.0, 0.86))
	draw_rect(Rect2(31, 62, 164, 12), Color(0.01, 0.02, 0.03, 0.86), true)
	draw_rect(Rect2(34, 65, 158, 6), Color(0.18, 0.035, 0.045, 0.95), true)
	draw_rect(Rect2(34, 65, 158.0 * float(game.player_health) / 100.0, 6), Color(0.08, 0.82, 0.94, 1.0), true)
	draw_string(ThemeDB.fallback_font, Vector2(202, 73), "HP %d" % game.player_health, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
