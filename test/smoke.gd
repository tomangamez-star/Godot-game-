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
		scene._update_pose()
		assert(scene.sprite.frame == 0)
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
	scene.position_on_screen = Vector2(1064, 580)
	scene._update_joystick(scene.joystick_center + Vector2(70, 70))
	scene._process(0.05)
	assert(scene.position_on_screen == Vector2(1064, 580))
	scene._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(scene.joystick_vector == Vector2.ZERO)
	print("PASS: sheets, four-direction idle/attack, movement, bounds, focus reset")
	quit(0)
