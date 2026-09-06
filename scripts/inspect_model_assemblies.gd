extends SceneTree

var _only := ""
var _output := "res://builds/model-review/game"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--model="):
			_only = arg.trim_prefix("--model=")
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_output)
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var cases := [{"level": 1, "title": "Hermit crab", "name": "hermit_crab", "tier": 2},
		{"level": 2, "title": "Skater", "name": "skater", "tier": 2},
		{"level": 2, "title": "Skateboard", "name": "skateboard", "tier": 1}]
	for item in cases:
		if not _only.is_empty() and _only != item.name:
			continue
		game.start_level(item.level)
		game.set_physics_process(false)
		game.world.set_physics_process(false)
		game.goo.hide()
		game.goo.set_physics_process(false)
		var target: Food
		for food: Food in game.world.foods:
			food.freeze = true
			food.set_physics_process(false)
			if food.title == item.title and food.parent_food == null and (target == null or item.name == "hermit_crab"):
				target = food
		assert(target != null)
		game.world.advance_scale(item.tier)
		game.rig.subject = target
		game.rig.reveal(game.world.config.jumps[item.tier].view_size)
		await _shot(item.name + "-game-size")
		game.hud.hide()
		# Close views isolate the live assembly without changing its transforms or materials.
		for food: Food in game.world.foods:
			if food != target and not target.is_ancestor_of(food):
				food.hide()
		game.rig.reveal(4.0)
		await _shot(item.name + "-close")
		game.rig.set_process(false)
		var focus: Vector3 = target.global_position + Vector3.UP * 0.6
		game.rig.camera.global_position = focus + Vector3(3, 2, 4)
		game.rig.camera.look_at(focus)
		await _shot(item.name + "-assembly")
		print("MODEL_ASSEMBLY_CAPTURE ", item.name)
	game._shutdown()

func _shot(label: String) -> void:
	await create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_output.path_join(label + ".png"))
