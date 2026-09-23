extends SceneTree

# Frame series for the size jump and the camera look-ahead, from a native window.
# Each level stages the goo just under its first jump, then grows it across the
# threshold through the ordinary game loop. The turn series drives up, then right.
# Output: --output=<dir> with PNGs and camera.json (real seconds, time scale, view size,
# and the camera's frame-to-frame acceleration in screen pixels during the turn).

const ScriptArgs := preload("res://scripts/script_args.gd")

const JUMP_SHOTS := [0.0, 0.2, 0.45, 0.75, 1.1, 1.6, 2.3]
const TURN_SHOTS := [0.0, 0.25, 0.5, 0.75, 1.0, 1.5, 2.2]
var _output := "res://builds/jump-camera"
var _game: Node3D
var _report := {"jumps": [], "turn": {}}
# A PNG write blocks for about 0.3 s, so frames wait in memory until each series ends.
var _images := {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args = ScriptArgs.parse(self, {"--output": _output})
	if args == null:
		return
	_output = args["--output"]
	DirAccess.make_dir_recursive_absolute(_output)
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	_game._music.stop()
	for level in 4:
		await _jump_series(level)
		_flush()
	await _turn_series(1)
	_flush()
	FileAccess.open(_output.path_join("camera.json"), FileAccess.WRITE).store_string(JSON.stringify(_report, "\t"))
	print("JUMP_CAMERA_REPORT ", JSON.stringify(_report))
	_press("")
	_game._shutdown()

func _jump_series(level: int) -> void:
	_game.start_level(level)
	_game._music.stop()
	var threshold := float(_game.world.config.jumps[1].radius)
	# Held still while the view settles, so no meal crosses the threshold before the shot.
	_stage(threshold * 0.9)
	await create_timer(2.0).timeout
	if _game._tier != 0:
		push_error("Level %d jumped during staging" % level)
	await _shot("level-%d-jump-before" % level)
	_press("move_up")
	await create_timer(0.4).timeout
	_stage(threshold * 1.03)
	while _game._tier == 0:
		await process_frame
	var start := Time.get_ticks_usec()
	var samples := []
	for at in JUMP_SHOTS:
		while _seconds_since(start) < at:
			await process_frame
		samples.append({"real_seconds": _seconds_since(start), "time_scale": Engine.time_scale,
			"view_size": _game.rig.camera.size})
		await _shot("level-%d-jump-%.2fs" % [level, at])
	_report.jumps.append({"level": level, "title": _game.world.config.title,
		"tier_name": _game.world.config.tiers[_game._tier], "samples": samples})
	_press("")

func _stage(radius: float) -> void:
	_game._volume = maxf(_game._volume, pow(radius, 3.0))
	_game.goo.grow_to(radius)

func _turn_series(level: int) -> void:
	_game.start_level(level)
	_game._music.stop()
	_press("move_up")
	await create_timer(3.0).timeout
	_press("move_right")
	var start := Time.get_ticks_usec()
	var positions: Array[Vector2] = []
	var next_shot := 0
	var worst := 0.0
	var reversals := 0
	var last_step := Vector2.ZERO
	var trace := []
	while _seconds_since(start) < 2.4:
		await process_frame
		# Camera position in screen pixels; shake shows as large or sign-flipping accelerations.
		var pixels_per_unit: float = root.get_visible_rect().size.y / _game.rig.camera.size
		var camera := Vector2(_game.rig.camera.global_position.x, _game.rig.camera.global_position.z) * pixels_per_unit
		positions.append(camera)
		if positions.size() >= 3:
			var step := positions[-1] - positions[-2]
			var acceleration := step - (positions[-2] - positions[-3])
			worst = maxf(worst, acceleration.length())
			trace.append([snappedf(_seconds_since(start), 0.001), snappedf(step.x, 0.01), snappedf(step.y, 0.01), snappedf(acceleration.length(), 0.01)])
			if step.length() > 0.05 and last_step.length() > 0.05 and step.dot(last_step) < 0.0:
				reversals += 1
			last_step = step
		if next_shot < TURN_SHOTS.size() and _seconds_since(start) >= TURN_SHOTS[next_shot]:
			await _shot("turn-%.2fs" % TURN_SHOTS[next_shot])
			next_shot += 1
	_report.turn = {"level": level, "max_camera_acceleration_px_per_frame2": worst,
		"camera_direction_reversals": reversals, "frames": positions.size(), "trace": trace, "lead": str(_game.rig._lead),
		"goo_screen_offset_px": str(_game.rig.camera.unproject_position(_game.goo.global_position) - root.get_visible_rect().size * 0.5)}
	_press("")

func _press(action: String) -> void:
	for item in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(item)
	if not action.is_empty():
		Input.action_press(action)

func _seconds_since(start: int) -> float:
	return (Time.get_ticks_usec() - start) / 1000000.0

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_images[name] = root.get_texture().get_image()

func _flush() -> void:
	for name in _images:
		_images[name].save_png(_output.path_join(name + ".png"))
	_images.clear()
