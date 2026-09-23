extends SceneTree

const ScriptArgs := preload("res://scripts/script_args.gd")

var _game: Node3D
var _frames := PackedFloat64Array()
var _sample := false
var _previous_tick := 0
var _output := "res://builds/level-views"
var _level := -1
var _tier := -1

func _initialize() -> void:
	call_deferred("_run")

func _process(_delta: float) -> bool:
	var tick := Time.get_ticks_usec()
	if _sample:
		_frames.append((tick - _previous_tick) / 1000000.0)
	_previous_tick = tick
	return false

func _run() -> void:
	var args = ScriptArgs.parse(self, {"--output": _output, "--level": _level, "--tier": _tier})
	if args == null:
		return
	_output = args["--output"]
	_level = args["--level"]
	_tier = args["--tier"]
	if _level < -1 or _level > 3 or _tier < -1 or _tier > 4:
		push_error("Choose a level from 0 to 3 and a tier from 0 to 4")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_output)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	var results: Array[Dictionary] = []
	for level in 4:
		if _level >= 0 and level != _level:
			continue
		_game.start_level(level)
		_game.set_physics_process(false)
		for tier in 5:
			if _tier >= 0 and tier != _tier:
				continue
			results.append(await _inspect_view(level, tier))
	FileAccess.open(_output.path_join("views.json"), FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	print("VIEW_CHECK_DONE count=", results.size())
	_game._shutdown()

func _inspect_view(level: int, tier: int) -> Dictionary:
	var jump: Dictionary = _game.world.config.jumps[tier]
	_game._tier = tier
	_game._volume = pow(float(jump.radius), 3.0)
	_game.world.advance_scale(tier)
	_game.world.player_radius = jump.radius
	_game.goo.grow_to(jump.radius)
	_game.rig.reveal(jump.view_size)
	await create_timer(2.0).timeout
	_frames.clear()
	_sample = true
	await create_timer(3.0).timeout
	_sample = false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_output.path_join("level-%d-tier-%d.png" % [level, tier]))
	_frames.sort()
	var total := 0.0
	for frame in _frames:
		total += frame
	var result := {"level": level, "tier": tier, "title": _game.world.config.title,
		"staged_view": true, "average_fps": _frames.size() / total,
		"p95_ms": _frames[int(_frames.size() * 0.95)] * 1000.0,
		"frames": _frames.size(), "measured_seconds": total,
		"viewport": str(root.get_visible_rect().size), "vsync": "disabled", "fps_cap": 0}
	print("VIEW_RESULT ", JSON.stringify(result))
	return result
