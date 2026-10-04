extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.enemy.set_process(false)
	assert(scene.sheets.size() == 4)
	for action in scene.sheets:
		for direction in scene.sheets[action]:
			assert(scene.sheets[action][direction].get_size() == Vector2(2048, 256))
	for direction in scene.DIRECTIONS:
		scene.facing = direction
		scene.state = "idle"
		scene.idle_clock = 0.40
		scene._update_pose()
		assert(scene.sprite.frame in (scene.IDLE_VERTICAL_SEQUENCE if direction in ["up", "down"] else scene.IDLE_SIDE_SEQUENCE))
		var anchor: Vector2 = scene.pose_anchors["idle"][direction][scene.sprite.frame]
		var rendered_foot: Vector2 = scene.sprite.position + (anchor - Vector2(128, 128)) * float(scene.CHARACTER_SCALE)
		assert(rendered_foot.distance_to(scene.position_on_screen) < 0.1)
		scene._attack()
		assert(scene.state == "attack1")
		var start: Vector2 = scene.position_on_screen
		for i in range(14):
			scene._process(0.05)
		assert(scene.state == "idle")
		assert(scene.position_on_screen == start)
		scene._attack2()
		assert(scene.state == "attack2")
		for i in range(18):
			scene._process(0.05)
		assert(scene.state == "idle")
		assert(scene.position_on_screen == start)
	# The vertical idle uses one planted source drawing plus shader breathing.
	assert(scene.IDLE_VERTICAL_SEQUENCE == [0])
	# Side-run horizontal placement follows the torso instead of alternating feet.
	for direction in ["left", "right"]:
		for frame in range(8):
			assert(absf(scene.pose_anchors["run"][direction][frame].x - 128.0) < 18.0)
	# Eight-direction Knight sheets, facing map and combat loop.
	assert(scene.enemy.textures.size() == 5)
	for texture in scene.enemy.textures.values():
		assert(texture.get_size() == Vector2(1920, 1024))
	assert(scene.enemy._direction_row(Vector2.RIGHT) == 3)
	assert(scene.enemy._direction_row(Vector2.DOWN) == 5)
	assert(scene.enemy._direction_row(Vector2.LEFT) == 7)
	assert(scene.enemy._direction_row(Vector2.UP) == 1)
	scene.position_on_screen = Vector2(576, 365)
	scene.facing = "right"
	scene.enemy.position = Vector2(650, 365)
	scene.state = "attack1"
	scene.clock = 0.20
	scene.attack_hit_done = false
	scene._resolve_attack_hit()
	assert(scene.enemy.health == 80)
	scene.state = "attack2"
	scene.clock = 0.30
	scene.attack_hit_done = false
	scene._resolve_attack_hit()
	assert(scene.enemy.health == 45)
	scene._damage_player(10, Vector2.LEFT)
	assert(scene.player_health == 90)
	scene.enemy.take_damage(999, Vector2.RIGHT)
	assert(scene.enemy.state == "dead")
	scene.enemy.respawn()
	assert(scene.enemy.health == 100 and scene.enemy.state == "idle")
	# Joystick movement, diagonal normalization, bounds, release, focus reset.
	scene.state = "idle"
	scene.clock = 0.0
	scene.position_on_screen = Vector2(576, 365)
	scene._update_joystick(scene.joystick_center + Vector2(70, 0))
	scene._process(0.05)
	assert(scene.facing == "right" and scene.state == "run")
	assert(scene.position_on_screen.x > 576)
	scene._update_joystick(scene.joystick_center)
	scene._process(0.05)
	assert(scene.state == "idle")
	assert(not scene._can_stand(Vector2(1120, 500)))
	# Solid prop blocker: the left wreck cannot be walked through.
	scene.position_on_screen = Vector2(250, 245)
	scene._move_with_collisions(Vector2(-20, 0))
	assert(scene.position_on_screen == Vector2(250, 245))
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(scene.joystick_vector == Vector2.ZERO)
	print("PASS: planted idle, eight-direction Knight combat, two attacks, collisions, focus reset")
	quit(0)
