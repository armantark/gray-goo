extends SceneTree

const ScriptArgs := preload("res://scripts/script_args.gd")

const ROUTE_SEED := 439
const WARMUP := 2.0
const ROUTE := [
	[0.0, "warmup", ""],
	[2.0, "move", "move_up"],
	[4.0, "turn", "move_right"],
	[6.0, "idle", ""],
	[12.0, "resume_and_eat", "move_down"],
	[16.0, "final_turn", "move_left"],
]
const ACTIONS := ["move_up", "move_right", "move_down", "move_left"]
var _game: Node3D
var _elapsed := 0.0
var _duration := 18.0
var _output := "/tmp/body-verify-motion.json"
var _phase := ""
var _markers: Array[Dictionary] = []
var _meals: Array[Dictionary] = []
var _pending_foods: Array[Food] = []
var _fixture: Food
var _frames := 0
var _last_usec := 0
var _frame_times := PackedFloat64Array()
var _fixed_frame := false
var _finished := false

func _initialize() -> void:
	_fixed_frame = not Engine.get_write_movie_path().is_empty()
	var args = ScriptArgs.parse(self, {"--duration": _duration, "--output": _output})
	if args == null:
		return
	_duration = args["--duration"]
	_output = args["--output"]
	if _duration < 16.0:
		push_error("Use --duration=<seconds>, at least 16 seconds for the full route")
		quit(2)
		return
	call_deferred("_start")

func _start() -> void:
	seed(ROUTE_SEED)
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	_game.start_level(1)
	# Reproducible comparison overrides are transient; never invoke HUD persistence.
	_game.goo._step_random.seed = ROUTE_SEED
	_game.goo._ooze_phases = Vector3(_game.goo._step_random.randf_range(0.0, TAU), _game.goo._step_random.randf_range(0.0, TAU), _game.goo._step_random.randf_range(0.0, TAU))
	_game.rig.zoom = 0.75
	_pending_foods.assign(_game.world.foods)

func _process(delta: float) -> bool:
	if _game == null or _finished:
		return false
	var now := Time.get_ticks_usec()
	if _elapsed >= WARMUP and _last_usec > 0:
		_frame_times.append((now - _last_usec) / 1000000.0)
	_last_usec = now
	_frames += 1
	_elapsed += delta
	var route_time := _elapsed + 0.0000001
	var current: Array = ROUTE[0]
	for segment in ROUTE:
		if route_time >= float(segment[0]):
			current = segment
	var phase := str(current[1])
	var action := str(current[2])
	if phase != _phase:
		_phase = phase
		_markers.append({"phase": phase, "simulation_seconds": _elapsed, "frame": _frames, "position": str(_game.goo.global_position)})
		if phase == "resume_and_eat":
			_place_fixture()
	for item in ACTIONS:
		Input.action_release(item)
	if not action.is_empty():
		Input.action_press(action)
	for index in range(_pending_foods.size() - 1, -1, -1):
		var food := _pending_foods[index]
		if not food.active:
			# Inactive child parts are not separate meals; only consume() installs a target.
			if is_instance_valid(food._meal_target):
				_meals.append({"title": food.title, "simulation_seconds": _elapsed, "frame": _frames, "phase": phase, "fixture": food == _fixture})
			_pending_foods.remove_at(index)
	if _elapsed >= _duration:
		_finish()
	return false

func _place_fixture() -> void:
	var down: Vector3 = -_game.rig.camera.global_basis.y
	down.y = 0.0
	var at: Vector3 = _game.goo.global_position + down.normalized() * _game.goo.radius * 3.0
	_fixture = _game.world._add_food("plankton", Vector2(at.x, at.z), _game.goo.radius * 0.3, pow(_game.goo.radius, 3.0) * 0.2, "Motion route contact fixture")
	_fixture.rename(_fixture.title, Color(0.95, 0.32, 0.23))
	_pending_foods.append(_fixture)

func _finish() -> void:
	_finished = true
	for action in ACTIONS:
		Input.action_release(action)
	var native_measurement := not _fixed_frame and DisplayServer.get_name() != "headless"
	var ordered := _frame_times.duplicate()
	ordered.sort()
	var seconds := 0.0
	for duration in ordered:
		seconds += duration
	var fixture_eaten := is_instance_valid(_fixture) and not _fixture.active and is_instance_valid(_fixture._meal_target)
	var report := {"scene": "Coral Colony Tide Pool", "seed": ROUTE_SEED,
		"simulation_seconds": _elapsed, "frames": _frames, "warmup_seconds": WARMUP,
		"evidence_kind": "native_wall_clock" if native_measurement else "fixed_frame_visual" if _fixed_frame else "headless_simulation",
		"viewport": str(root.get_visible_rect().size), "renderer": RenderingServer.get_current_rendering_method(),
		"speed_multiplier": _game.hud.movement_speed, "phases": _markers, "meal_count": _meals.size(), "meals": _meals,
		"fixture": "One labeled plankton added three body radii down-screen at resume; ordinary game contact only",
		"fixture_eaten": fixture_eaten, "route_complete": fixture_eaten and _elapsed >= 16.0}
	if native_measurement and not ordered.is_empty():
		report["performance"] = {"measured_seconds": seconds, "frames": ordered.size(), "average_fps": ordered.size() / seconds, "p95_frame_ms": ordered[int(ordered.size() * 0.95)] * 1000.0}
	var file := FileAccess.open(_output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write motion report: " + _output)
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("MOTION_REPORT ", JSON.stringify(report))
	_game._music.stop()
	_game._bite_sound.stop()
	_game._win_sound.stop()
	quit(0 if report.route_complete else 1)
