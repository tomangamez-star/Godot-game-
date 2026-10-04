extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	assert(scene.sheets.size() == 3)
	for action in scene.sheets:
		for direction in scene.sheets[action]:
			assert(scene.sheets[action][direction].get_size() == Vector2(2048, 256))
	for direction in scene.DIRECTIONS:
		scene.facing = direction
		scene.state = "idle"
		scene.idle_clock = 0.40
		scene._update_pose()
		assert(scene.sprite.frame > 0)
		var anchor: Vector2 = scene.anchors["idle"][direction][scene.sprite.frame]
		var rendered_foot: Vector2 = scene.sprite.position + (anchor - Vector2(128, 128)) * float(scene.CHARACTER_SCALE)
		assert(rendered_foot.distance_to(scene.position_on_screen) < 0.1)
		scene._attack()
		assert(scene.state == "attack1")
		var start: Vector2 = scene.position_on_screen
		for i in range(14):
			scene._process(0.05)
		assert(scene.state == "idle")
		assert(scene.position_on_screen == start)
	# Joystick movement, diagonal normalization, bounds, release, focus reset.
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
	print("PASS: animated idle foot anchors, attack, road/prop collisions, focus reset")
	quit(0)
