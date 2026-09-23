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
var _chased: Food
var _last_volume := 0.0
var _growth_age := 0.0
# A level with no growth for this long is stuck; ending it saves minutes of an idle goo.
const GIVE_UP_SECONDS := 30.0
var _grew_at := 0.0
var _limit := 900.0
var _output := "res://builds/level-routes.json"
var _simulation_clock := false
var _route_seed := 0
var _route_rng := RandomNumberGenerator.new()
var _speed := 1.0
var _body := ""
# Contact measures. A contact lasts from the first physics tick the goo surface touches a
# visible food footprint until the tick it stops touching.
var _contacts := {}
var _pending: Array[Food] = []
var _missed := 0
var _missed_then_eaten := 0
var _looks_blocked := 0
var _looks_uneaten := 0
var _missed_titles := {}
var _looks_titles := {}
var _forward_speed := 0.0
var _stall_run := 0.0
var _stalls: Array[float] = []
var _long_stalls: Array[Dictionary] = []
var _abandoned: Array[Dictionary] = []
# Momentum measures, one entry per view: meals (frames in which the goo grew), the longest gap
# between meals (from the level's start, and to its end), credited to the view where it ends, and
# seconds with no edible target within MOMENTUM_SECONDS of travel.
const MOMENTUM_SECONDS := 4.0
var _views: Array[Dictionary] = []
var _meal_volume := 0.0
var _meal_at := 0.0

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
		elif arg.begins_with("--speed="):
			_speed = float(arg.trim_prefix("--speed="))
		elif arg.begins_with("--body="):
			_body = arg.trim_prefix("--body=")
	if _speed <= 0.0 or _body not in ["", "shell", "procedural"]:
		push_error("Use --speed=<positive multiplier> and --body=shell|procedural")
		quit(2)
		return
	_route_rng.seed = _route_seed
	if _simulation_clock:
		Engine.max_fps = 0
		OS.low_processor_usage_mode = false
		OS.low_processor_usage_mode_sleep_usec = 0
	DirAccess.make_dir_recursive_absolute(_output.get_base_dir())
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	# Speed and body are set for this run only, never saved, so routes do not depend on the owner's settings.
	if not _body.is_empty():
		_game.hud.body_kind = _body
	if _level != 0 or not _body.is_empty():
		_game.start_level(_level)
	_game.hud.movement_speed = _speed
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
	_record_momentum(delta if _simulation_clock else wall_delta)
	_record_progress()
	if _elapsed >= _next_capture:
		_next_capture = INF
		if DisplayServer.get_name() != "headless":
			_capture_view()
	if _game._won or _elapsed >= _limit or _elapsed - _grew_at >= GIVE_UP_SECONDS:
		_ending = true
		_finish_level.call_deferred()
		return false
	_check_stall(delta if _simulation_clock else wall_delta)
	if not _game.world.is_edible(_target, _game.goo.radius):
		_choose_target()
	_steer(_destination())
	return false

# SceneTree runs this before any node's physics, so it sees exactly the goo and food state
# that the game's _consume_foods is about to judge; each verdict is read one tick later.
func _physics_process(delta: float) -> bool:
	if _game == null or _ending or not is_instance_valid(_game.world):
		return false
	_measure_contacts()
	_measure_stall(delta)
	return false

func _measure_contacts() -> void:
	for food in _pending:
		if is_instance_valid(food) and food.active:
			_missed += 1
			_missed_titles[food.title] = _missed_titles.get(food.title, 0) + 1
			_contacts[food.get_instance_id()].missed = true
	_pending.clear()
	var touching := {}
	var goo: GooBody = _game.goo
	for food in _game.world.nearby(goo.global_position, goo.radius * 3.0):
		if not food.active or food.detail_hidden or food.model_name.is_empty() or not goo.touches(food.center(), food.radius):
			continue
		var id: int = food.get_instance_id()
		var contact: Dictionary = _contacts.get(id, {"judged": false, "missed": false, "looks": false})
		touching[id] = contact
		if _game.world.is_edible(food, goo.radius):
			if not contact.judged:
				contact.judged = true
				_pending.append(food)
		elif food.radius < goo.radius and not contact.looks:
			contact.looks = true
			_looks_titles[food.title] = _looks_titles.get(food.title, 0) + 1
			if food.collider_radius > 0.0:
				_looks_blocked += 1
			else:
				_looks_uneaten += 1
	for id in _contacts:
		var food := instance_from_id(id) as Food
		if _contacts[id].missed and not touching.has(id) and not (is_instance_valid(food) and food.active):
			_missed_then_eaten += 1
	_contacts = touching

# A stall is drive input into a touched obstacle while smoothed forward speed stays under a
# tenth of the commanded speed; runs shorter than half a second are ordinary contact.
func _measure_stall(delta: float) -> void:
	var goo: GooBody = _game.goo
	var commanded: float = goo._speed * goo._drive.length()
	var heading: Vector3 = goo._drive.normalized()
	_forward_speed = lerpf(_forward_speed, goo.velocity.dot(heading), 1.0 - exp(-8.0 * delta))
	var pressing := false
	if commanded > 0.0:
		for solid in _game.world.get_obstacles(goo.global_position, goo.radius * 1.1):
			var axis := Vector3(solid.center.x, clampf(goo.global_position.y, solid.bottom, solid.top), solid.center.z)
			var toward := axis - goo.global_position
			toward.y = 0.0
			if toward.dot(heading) > 0.0 and goo.touches(axis, float(solid.radius) * 1.05):
				pressing = true
				break
	if pressing and _forward_speed < commanded * 0.1:
		_stall_run += delta
	else:
		_end_stall()

func _end_stall() -> void:
	if _stall_run >= 0.5:
		_stalls.append(_stall_run)
	if _stall_run > 2.0:
		var goo: GooBody = _game.goo
		_long_stalls.append({"seconds": _elapsed, "duration": _stall_run, "position": str(goo.global_position),
			"radius": goo.radius, "target": _target.title if is_instance_valid(_target) else "pool",
			"target_at": str(_destination()), "obstacles_within_reach": _obstacles_near(goo)})
	_stall_run = 0.0

func _contact_report() -> Dictionary:
	_end_stall()
	var longest := 0.0
	var total := 0.0
	var over_two := 0
	for stall in _stalls:
		longest = maxf(longest, stall)
		total += stall
		over_two += int(stall > 2.0)
	return {"missed_edible_contacts": _missed, "missed_then_eaten_in_contact": _missed_then_eaten,
		"missed_titles": _missed_titles, "edible_looking_blocked": _looks_blocked,
		"edible_looking_uneaten": _looks_uneaten, "edible_looking_titles": _looks_titles,
		"stalls": _stalls.size(), "stall_seconds": total, "longest_stall": longest,
		"stalls_over_two_seconds": over_two, "long_stalls": _long_stalls.duplicate(true),
		"abandoned_targets": _abandoned.duplicate(true)}

# Runs before the jump is recorded, so the meal that crosses a jump closes a gap in the view it ends.
func _record_momentum(delta: float) -> void:
	if _views.is_empty():
		_views.append(_view_entry())
		_meal_volume = _game._volume
	var view: Dictionary = _views[-1]
	if _game._volume > _meal_volume + 0.0000001:
		_meal_volume = _game._volume
		view.meals += 1
		if _elapsed - _meal_at > view.longest_meal_gap:
			view.longest_meal_gap = _elapsed - _meal_at
			view.longest_gap_end = {"seconds": _elapsed, "at": str(_game.goo.global_position)}
		_meal_at = _elapsed
	var goo: GooBody = _game.goo
	var reach: float = MOMENTUM_SECONDS * _game.BODY_LENGTHS_PER_SECOND * goo.radius * 2.0 * _game.hud.movement_speed
	var target: Food = _game.world.nearest_edible(goo.global_position, goo.radius)
	var in_reach := is_instance_valid(target) and target.center().distance_to(goo.global_position) <= reach
	for pool in _game.world.pools:
		in_reach = in_reach or (pool.is_edible(_game._tier, goo.radius)
			and pool.closest_point(goo.global_position).distance_to(goo.global_position) <= reach)
	if not in_reach:
		view.no_target_seconds += delta

func _view_entry() -> Dictionary:
	return {"tier": _game._tier, "start": _elapsed, "meals": 0, "longest_meal_gap": 0.0, "longest_gap_end": {},
		"no_target_seconds": 0.0}

func _record_progress() -> void:
	if _game._tier != _tier:
		_tier = _game._tier
		_views.append(_view_entry())
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

# Stall and growth ages measure the chase of one target, so they restart with each new target and
# do not run while the goo waits with nothing to eat.
func _check_stall(delta: float) -> void:
	if _game._volume > _last_volume + 0.0000001:
		_last_volume = _game._volume
		_growth_age = 0.0
		_grew_at = _elapsed
	if _target != _chased or not is_instance_valid(_target):
		_chased = _target if is_instance_valid(_target) else null
		_last_position = _game.goo.global_position
		_progress_age = 0.0
		_stalled = 0.0
		_growth_age = 0.0
		return
	_growth_age += delta
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
		_abandoned.append(_abandon_evidence())
		_skipped[_target.get_instance_id()] = _elapsed + 15.0
		_target = null
		_stalled = 0.0
		_growth_age = 0.0

func _abandon_evidence() -> Dictionary:
	var goo: GooBody = _game.goo
	return {"seconds": _elapsed, "reason": "stalled" if _stalled > 2.0 else "no growth for 15 seconds",
		"position": str(goo.global_position), "radius": goo.radius, "tier": _tier,
		"target": _target.title, "target_at": str(_target.center()), "target_radius": _target.radius,
		"target_moving": not _target.freeze, "target_distance": _target.center().distance_to(goo.global_position),
		"obstacles_within_reach": _obstacles_near(goo)}

func _obstacles_near(goo: GooBody) -> Array:
	var obstacles := []
	for solid in _game.world.get_obstacles(goo.global_position, goo.radius * 2.2):
		var food: Food = solid.get("body", null)
		obstacles.append({"radius": solid.radius, "center": str(solid.center),
			"distance": Vector2(solid.center.x - goo.global_position.x, solid.center.z - goo.global_position.z).length(),
			"title": food.title if food != null else ""})
	return obstacles

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
		"stuck": _elapsed - _grew_at >= GIVE_UP_SECONDS, "position": str(_game.goo.global_position),
		"clock": "simulation" if _simulation_clock else "wall",
		"route_seed": _route_seed,
		"play_seconds": _elapsed, "jumps": _jumps.duplicate(true), "radius": pow(_game._volume, 1.0 / 3.0),
		"frames": _frames.size(), "measured_seconds": seconds, "average_fps": _frames.size() / seconds,
		"p95_ms": _frames[int(_frames.size() * 0.95)] * 1000.0, "viewport": str(root.get_visible_rect().size),
		"renderer": RenderingServer.get_current_rendering_method(), "speed_multiplier": _game.hud.movement_speed, "body": _game.hud.body_kind}
	result["display_server"] = DisplayServer.get_name()
	if not _views.is_empty():
		_views[-1].longest_meal_gap = maxf(_views[-1].longest_meal_gap, _elapsed - _meal_at)
	var longest_gap := 0.0
	var idle := 0.0
	for view in _views:
		longest_gap = maxf(longest_gap, view.longest_meal_gap)
		idle += view.no_target_seconds
	result.merge({"views": _views.duplicate(true), "longest_meal_gap": longest_gap, "no_target_seconds": idle,
		"momentum_ok": longest_gap <= MOMENTUM_SECONDS})
	result.merge(_contact_report())
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
	_chased = null
	_skipped.clear()
	_stalled = 0.0
	_last_volume = 0.0
	_growth_age = 0.0
	_grew_at = 0.0
	_contacts.clear()
	_pending.clear()
	_missed = 0
	_missed_then_eaten = 0
	_looks_blocked = 0
	_looks_uneaten = 0
	_missed_titles = {}
	_looks_titles = {}
	_forward_speed = 0.0
	_stalls.clear()
	_long_stalls.clear()
	_abandoned.clear()
	_views.clear()
	_meal_volume = 0.0
	_meal_at = 0.0
	_ending = false
