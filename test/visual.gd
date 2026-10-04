extends SceneTree
var game: Node
var count := 0

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/crossroads-idle.png")
	game.state = "attack1"
	game.facing = "left"
	game.clock = 0.18
	game._update_pose()
	game.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/crossroads-attack.png")
	quit()
