extends SceneTree

var _game: Node3D
var _target: Food
var _level := 0
var _last_level := 3
var _elapsed := 0.0
var _previous_tick := 0
var _next_progress := 15.0
var _next_capture := 2.0
var _frames := PackedFloat64Array()
var _results: Array[Dictionary] = []
var _jumps: Array[Dictionary] = []
var _tier := 0
var _ending := false
var _skipped := {}
var _last_position := Vector3.ZERO
var _progress_age := 0.0
var _stalled := 0.0
var _last_volume := 0.0
var _growth_age := 0.0
var _limit := 900.0
var _output := "res://builds/level-routes.json"
var _simulation_clock := false
var _route_seed := 0
var _route_rng := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("_begin")

func _begin() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--start="):
			_level = int(arg.trim_prefix("--start="))
		elif arg.begins_with("--last="):
			_last_level = int(arg.trim_prefix("--last="))
		elif arg.begins_with("--limit="):
			_limit = float(arg.trim_prefix("--limit="))
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg == "--simulation-clock":
			_simulation_clock = true
		elif arg.begins_with("--seed="):
			_route_seed = int(arg.trim_prefix("--seed="))
	_route_rng.seed = _route_seed
	if _simulation_clock:
		Engine.max_fps = 0
	DirAccess.make_dir_recursive_absolute(_output.get_base_dir())
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	if _level != 0:
		_game.start_level(_level)
	if not is_equal_approx(_game.hud.movement_speed, 1.0):
		push_error("Route timings require the default saved speed")
		quit(1)
		return
	_previous_tick = Time.get_ticks_usec()

func _process(delta: float) -> bool:
	if _game == null or _ending:
		return false
	var now := Time.get_ticks_usec()
	var wall_delta := (now - _previous_tick) / 1000000.0
	_previous_tick = now
	_elapsed += delta if _simulation_clock else wall_delta
	if _elapsed > 2.0:
		_frames.append(wall_delta)
	_record_progress()
	if _elapsed >= _next_capture:
		_next_capture = INF
		if DisplayServer.get_name() != "headless":
			_capture_view()
	if _game._won or _elapsed >= _limit:
		_ending = true
		_finish_level.call_deferred()
		return false
	_check_stall(delta if _simulation_clock else wall_delta)
	if not _game.world.is_edible(_target, _game.goo.radius):
		_choose_target()
	_steer(_destination())
	return false

func _record_progress() -> void:
	if _game._tier != _tier:
		_tier = _game._tier
		_next_capture = _elapsed + 2.0
		_jumps.append({"tier": _tier, "seconds": _elapsed, "radius": _game.goo.radius})
		print("ROUTE_JUMP ", JSON.stringify(_jumps[-1]))
		_checkpoint()

	if _elapsed >= _next_progress:
		_next_progress += 15.0
		print("ROUTE_PROGRESS level=", _level, " seconds=", _elapsed, " radius=", _game.goo.radius,
			" at=", _game.goo.global_position, " target=", _target.title if is_instance_valid(_target) else "pool")
		_checkpoint()

func _capture_view() -> void:
	await RenderingServer.frame_post_draw
	var path := _output.get_basename() + "-level-%d-tier-%d.png" % [_level, _tier]
	root.get_texture().get_image().save_png(path)

func _check_stall(delta: float) -> void:
	_growth_age += delta
	if _game._volume > _last_volume + 0.0000001:
		_last_volume = _game._volume
		_growth_age = 0.0
	_progress_age += delta
	if _progress_age < 1.0:
		return
	if _game.goo.global_position.distance_to(_last_position) < maxf(0.08, _game.goo.radius * 0.15):
		_stalled += _progress_age
	else:
		_stalled = 0.0
	_last_position = _game.goo.global_position
	_progress_age = 0.0
	if (_stalled > 2.0 or _growth_age > 15.0) and is_instance_valid(_target):
		print("ROUTE_BLOCKED ", _target.title, " at=", _target.center())
		_skipped[_target.get_instance_id()] = _elapsed + 15.0
		_target = null
		_stalled = 0.0
		_growth_age = 0.0

func _choose_target() -> void:
	var nearest := INF
	_target = null
	for food in _game.world.foods:
		if not _game.world.is_edible(food, _game.goo.radius) or _skipped.get(food.get_instance_id(), 0.0) > _elapsed:
			continue
		var distance: float = food.center().distance_squared_to(_game.goo.global_position)
		if _route_seed != 0:
			distance *= _route_rng.randf_range(0.75, 1.25)
		if distance < nearest:
			nearest = distance
			_target = food

func _destination() -> Vector3:
	if is_instance_valid(_target):
		return _target.center()
	var destination: Vector3 = _game.goo.global_position
	var distance := INF
	for pool in _game.world.pools:
		if not pool.is_edible(_game._tier, _game.goo.radius):
			continue
		var point: Vector3 = pool.closest_point(_game.goo.global_position)
		var candidate := point.distance_squared_to(_game.goo.global_position)
		if candidate < distance:
			distance = candidate
			destination = point
	return destination

func _steer(destination: Vector3) -> void:
	var direction: Vector3 = destination - _game.goo.global_position
	direction.y = 0.0
	direction = direction.normalized()
	var right: Vector3 = _game.rig.camera.global_basis.x
	var up: Vector3 = _game.rig.camera.global_basis.y
	right.y = 0.0
	up.y = 0.0
	var movement := Vector2(direction.dot(right.normalized()), -direction.dot(up.normalized()))
	for entry in [["move_left", -movement.x], ["move_right", movement.x], ["move_up", -movement.y], ["move_down", movement.y]]:
		Input.action_release(entry[0])
		if entry[1] > 0.0:
			Input.action_press(entry[0], entry[1])

func _checkpoint() -> void:
	var report := {"completed": _results, "current": {"level": _level, "seconds": _elapsed,
		"clock": "simulation" if _simulation_clock else "wall",
		"route_seed": _route_seed,
		"jumps": _jumps, "radius": _game.goo.radius, "position": str(_game.goo.global_position)}}
	FileAccess.open(_output, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))

func _finish_level() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	_frames.sort()
	var seconds := 0.0
	for frame in _frames:
		seconds += frame
	var result := {"level": _level, "title": _game.world.config.title, "won": _game._won,
		"clock": "simulation" if _simulation_clock else "wall",
		"route_seed": _route_seed,
		"play_seconds": _elapsed, "jumps": _jumps.duplicate(true), "radius": pow(_game._volume, 1.0 / 3.0),
		"frames": _frames.size(), "measured_seconds": seconds, "average_fps": _frames.size() / seconds,
		"p95_ms": _frames[int(_frames.size() * 0.95)] * 1000.0, "viewport": str(root.get_visible_rect().size),
		"renderer": RenderingServer.get_current_rendering_method(), "speed_multiplier": _game.hud.movement_speed}
	result["display_server"] = DisplayServer.get_name()
	_results.append(result)
	print("ROUTE_RESULT ", JSON.stringify(result))
	_checkpoint()
	if _level == _last_level:
		_game._shutdown()
		return
	_level += 1
	_game.start_level(_level)
	_elapsed = 0.0
	_next_progress = 15.0
	_next_capture = 2.0
	_frames.clear()
	_jumps.clear()
	_tier = 0
	_previous_tick = Time.get_ticks_usec()
	_target = null
	_skipped.clear()
	_stalled = 0.0
	_last_volume = 0.0
	_growth_age = 0.0
	_ending = false
