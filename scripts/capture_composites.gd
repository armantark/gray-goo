extends SceneTree

# Photographs one composite per level: untouched, after the goo eats one part by contact, and
# after it eats the whole. The goo leaves the frame before each photo, so anything left behind
# shows. Output: --output=<dir>. Run muted with --audio-driver Dummy.

const SUBJECTS := [
	{"whole": "Water molecule · H2O", "part": "Hydrogen atom"},
	{"whole": "Coral head", "part": "Living coral branch"},
	{"whole": "Skater", "part": "Skateboard"},
	{"whole": "Spiral galaxy", "part": "Spiral arm"},
]
var _output := "res://builds/composites"
var _game: Node3D
var _marker := Node3D.new()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_output)
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	for level in SUBJECTS.size():
		_game.start_level(level)
		_game.add_child(_marker)
		var whole := _find(SUBJECTS[level].whole)
		var part := _find(SUBJECTS[level].part, whole)
		await _shot(level, whole, "0-untouched")
		await _eat(part, part.radius / GameWorld.EAT_MARGIN * 1.05)
		_check(not part.active and whole.active, "level %d part eaten, whole left" % level)
		await _shot(level, whole, "1-part-eaten")
		await _eat(whole, whole.radius / GameWorld.EAT_MARGIN * 1.05)
		_check(not whole.active, "level %d whole eaten" % level)
		await _shot(level, whole, "2-whole-eaten")
		_game.remove_child(_marker)
	print("COMPOSITE_CAPTURE_DONE")
	_marker.free()
	_game._shutdown()

func _find(title: String, whole: Food = null) -> Food:
	for food in _game.world.foods:
		if food.title == title and (whole == null or whole.is_ancestor_of(food)):
			return food
	push_error("COMPOSITE_CAPTURE_FAIL no " + title)
	return null

# Sets the goo down on the food, so the game's own contact rule decides what it eats.
func _eat(food: Food, radius: float) -> void:
	_marker.global_position = food.global_position
	_place_goo(food.center(), maxf(radius, _game.goo.radius))
	# Meals fly into this goo, so it stays until they land.
	await create_timer(0.6).timeout

func _shot(level: int, whole: Food, name: String) -> void:
	if whole.active:
		_marker.global_position = whole.global_position
	# The goo waits outside the frame so it cannot cover leftovers.
	_place_goo(_marker.global_position + Vector3(_game.rig._view_size * 2.0, 0, 0), _game.goo.radius)
	_game.rig.subject = _marker
	await create_timer(0.8).timeout
	# The game widens the view as the goo grows; zoom frames the composite instead.
	_game.rig.zoom = whole.radius * 5.0 / _game.rig._target_view
	_game.rig._view_size = _game.rig._target_view
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(_output.path_join("level-%d-%s.png" % [level, name]))

func _place_goo(at: Vector3, radius: float) -> void:
	var body_script: Script = _game.goo.get_script()
	_game.goo.free()
	_game.goo = body_script.new()
	_game.add_child(_game.goo)
	_game.goo.configure(at, radius, _game.world.get_ground_height, _game.world.get_obstacles, _game.world.field)
	_game._volume = maxf(_game._volume, pow(radius, 3.0))
	_game.world.player_radius = radius

func _check(condition: bool, label: String) -> void:
	if not condition:
		push_error("COMPOSITE_CAPTURE_FAIL " + label)
