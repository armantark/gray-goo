extends SceneTree

# Captures the HUD states the view inspector cannot reach: the last-meal card,
# the completion card, and the scene menu. Output: --output=<dir>.

var _output := "res://builds/hud-views"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_output)
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.start_level(1)
	await create_timer(2.0).timeout
	game.hud.show_meal("Living polyp", "polyp", Color("f58ca8"))
	await _shot("meal-card")
	game.hud.show_completion()
	await _shot("completion")
	game.hud.completion.hide()
	game.hud.toggle_menu()
	await _shot("menu")
	print("HUD_CAPTURE_DONE")
	game._shutdown()

func _shot(name: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_output.path_join(name + ".png"))
