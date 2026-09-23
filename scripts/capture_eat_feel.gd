extends SceneTree

# Captures the eat-moment evidence in a native window: a small and a large arrow, frame series
# of a small and a large meal, and a ring of objects that signal together when one meal grows
# the goo past their size. Fixtures are ordinary foods placed beside the idle goo in Tide Pool.
# Output: --output=<dir>. Run muted with --audio-driver Dummy.

var _output := "res://builds/eat-feel/frames"
var _game: Node3D

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
	_game.start_level(1)
	await create_timer(2.0).timeout
	var down: Vector3 = _game.rig.camera.global_basis.y * -1.0
	down.y = 0.0
	down = down.normalized()
	var right: Vector3 = _game.rig.camera.global_basis.x
	right.y = 0.0
	right = right.normalized()

	# The arrow follows the real nearest target, which lends it a speck's and then a feast's volume.
	var target: Food = _game._highlighted_target
	var own_volume := target.volume
	for arrow in [["small", _game._volume * 0.002], ["large", _game._volume * 0.3]]:
		target.volume = arrow[1]
		await create_timer(1.0).timeout
		print("ARROW ", arrow[0], " target=", _game._highlighted_target.title, " reward=", _game._reward(target.remaining_volume()), " scale=", _game.hud.pointer.scale_factor)
		await _shot("arrow-%s" % arrow[0], false)
	target.volume = own_volume

	for meal in [["small", "plankton", 0.35, 0.003], ["large", "sea_star", 0.95, 0.3]]:
		await create_timer(1.5).timeout
		var size: float = _game.goo.radius * float(meal[2])
		var food := _fixture(meal[1], right * (2.1 + float(meal[2]) * 0.5), float(meal[2]), float(meal[3]), "Meal " + meal[0])
		print("MEAL ", meal[0], " reward=", _game._reward(_game._volume * float(meal[3])), " size=", size)
		Input.action_press("move_right")
		while food.active:
			await physics_frame
		Input.action_release("move_right")
		await _series("meal-%s" % meal[0], [0.03, 0.07, 0.12, 0.2, 0.3, 0.45])

	await create_timer(2.0).timeout
	var reach: float = _game.goo.radius * GameWorld.EAT_MARGIN
	var ring: Array[Food] = []
	for index in 7:
		var angle := PI * 0.15 + index * PI * 0.28
		var at: Vector3 = (right * cos(angle) - down * sin(angle)) * _game.goo.radius * 4.2
		ring.append(_fixture("sea_star", at / _game.goo.radius, reach * 1.05 / _game.goo.radius, 0.02, "Ring"))
	await create_timer(0.8).timeout
	# One meal worth 40% of the goo lifts its radius about 12%, past the ring's 5% margin.
	_fixture("rock", down * 1.3, 0.5, 0.4, "Growth meal")
	print("SIGNAL ring_radius=", ring[0].radius, " goo=", _game.goo.radius)
	await _series("signal", [0.1, 0.25, 0.4, 0.55, 0.7, 0.85, 1.0, 1.3], 1.0)
	print("SIGNAL after goo=", _game.goo.radius, " edible=", ring.filter(func(food): return _game.world.is_edible(food, _game.goo.radius)).size())
	print("EAT_FEEL_CAPTURE_DONE")
	_game._shutdown()

# Places a food beside the goo; offset and size are in goo radii, volume is a share of the goo.
func _fixture(kind: String, offset: Vector3, size: float, share: float, label: String) -> Food:
	var at: Vector3 = _game.goo.global_position + offset * _game.goo.radius
	return _game.world._add_food(kind, Vector2(at.x, at.z), _game.goo.radius * size, _game._volume * share, label)

func _series(name: String, times: Array, crop_scale: float = 0.6) -> void:
	var start := Time.get_ticks_msec()
	for index in times.size():
		while Time.get_ticks_msec() - start < float(times[index]) * 1000.0:
			await process_frame
		await _shot("%s-%d-%03dms" % [name, index, Time.get_ticks_msec() - start], true, crop_scale)

func _shot(name: String, crop: bool, crop_scale: float = 0.6) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if crop:
		var side := int(image.get_height() * crop_scale)
		var center: Vector2 = _game.rig.camera.unproject_position(_game.goo.global_position)
		var corner := (center - Vector2(side, side) * 0.5).clamp(Vector2.ZERO, Vector2(image.get_width() - side, image.get_height() - side))
		image = image.get_region(Rect2i(Vector2i(corner), Vector2i(side, side)))
	image.save_png(_output.path_join(name + ".png"))
