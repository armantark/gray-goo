extends SceneTree

# Top-down layout capture: the whole field of one level, straight down, in two images. The plain
# image shows the level as built; the map adds each placed object's footprint in its tier's color
# (tier 1 cyan to tier 5 red), each spawn point's source in magenta, live movers in white, and the
# start in black. The level runs --seconds of scene motion first, with the goo idle, so movers show.
# Run in a short native window with --audio-driver Dummy:
# Godot --audio-driver Dummy --path . --script scripts/capture_layout.gd -- --level=1 --output=res://builds/layout/pass-1

const TIER_COLORS := [Color("2ee6ff"), Color("5dff6a"), Color("ffe23d"), Color("ff9a2e"), Color("ff3b3b")]
const WIDTH := 2400
var _output := "res://builds/layout"
var _level := 1
var _seconds := 40.0
var _tier := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_level = int(arg.trim_prefix("--level="))
		elif arg.begins_with("--output="):
			_output = arg.trim_prefix("--output=")
		elif arg.begins_with("--seconds="):
			_seconds = float(arg.trim_prefix("--seconds="))
		elif arg.begins_with("--tier="):
			_tier = int(arg.trim_prefix("--tier="))
	DirAccess.make_dir_recursive_absolute(_output)
	var game: Node3D = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.start_level(_level)
	game.set_physics_process(false)
	game.hud.hide()
	var world: GameWorld = game.world
	world.advance_scale(_tier)
	for tick in int(_seconds * 60.0):
		world._physics_process(1.0 / 60.0)
	var field := world.field
	var view := SubViewport.new()
	view.size = Vector2i(WIDTH, roundi(WIDTH * field.size.y / field.size.x))
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = field.size.y
	camera.far = 600.0
	view.add_child(camera)
	camera.position = Vector3(field.get_center().x, 250.0, field.get_center().y)
	camera.rotation.x = -PI * 0.5
	camera.cull_mask = 1
	_overlay(world, game.goo.global_position)
	await _save(view, "plain.png")
	camera.cull_mask = 3
	await _save(view, "map.png")
	print("LAYOUT_CAPTURE ", _output, " placed=", world.placed.size(), " foods=", world.foods.size(),
		" movers=", world.spawns.map(func(point: Dictionary) -> int: return point.movers.size()))
	game._shutdown()

func _save(view: SubViewport, file: String) -> void:
	for frame in 3:
		await RenderingServer.frame_post_draw
	var error := view.get_texture().get_image().save_png(_output.path_join(file))
	assert(error == OK, "Could not write " + _output.path_join(file))

func _overlay(world: GameWorld, start: Vector3) -> void:
	for food in world.placed:
		_ring(world, food.global_position, food.radius, 0.28, TIER_COLORS[food.tier])
	for point in world.spawns:
		for end in point.from:
			_ring(world, Vector3(end.x, 0.0, end.y), 2.2, 0.7, Color.MAGENTA)
		if point.from.size() > 1:
			var stretch: Vector2 = point.from[1] - point.from[0]
			for step in ceili(stretch.length() / 1.5):
				var at: Vector2 = point.from[0] + stretch.normalized() * step * 1.5
				_ring(world, Vector3(at.x, 0.0, at.y), 0.5, 0.5, Color.MAGENTA)
		for mover in point.movers:
			if is_instance_valid(mover.food) and mover.food.active:
				_ring(world, mover.food.global_position, 0.6, 0.6, Color.WHITE)
	_ring(world, start, 1.6, 1.6, Color.BLACK)

func _ring(world: GameWorld, at: Vector3, radius: float, width: float, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.outer_radius = radius
	mesh.inner_radius = maxf(0.0, radius - width)
	mesh.rings = 48
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.no_depth_test = true
	ring.material_override = material
	ring.layers = 2
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ring)
	ring.global_position = Vector3(at.x, 30.0, at.z)
	ring.scale.y = 0.01
