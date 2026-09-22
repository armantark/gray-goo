extends RefCounted

const Geometry = preload("res://src/levels/atomic_cosmic_geometry.gd")
var world: GameWorld
var supercluster: Food
var fabric: LocalPool
var filament: Node3D
var _stars: Array[Dictionary] = []
var _background: Array[Dictionary] = []
var _galaxies: Array[Food] = []
var _fabric_unlocked := false
var _groups: Array[Dictionary] = []

func definition() -> Dictionary:
	return {"title": "Cosmic Web", "meters_per_unit": 9.4607e15,
		"initial_radius": 0.4, "goal_radius": 9.5, "start_position": Vector3(-36.5, 0, -12.8),
		"accent": Color("e3c393"), "field": Rect2(-180, -155, 360, 270),
		"tiers": ["Stars", "Nebulae and clusters", "Galaxies", "Groups and clusters", "The web"],
		"jumps": [{"radius": 0.4, "view_size": 9.0}, {"radius": 0.85, "view_size": 15.0},
			{"radius": 1.75, "view_size": 25.0, "meters_per_unit": 1e20},
			{"radius": 3.3, "view_size": 39.0, "meters_per_unit": 1e21},
			{"radius": 6.0, "view_size": 180.0, "meters_per_unit": 1e22}],
		"background_color": Color("020407"), "ground_color": Color("0c1017"),
		"key_color": Color("eee5d7"), "fill_color": Color("6c8199"),
		"ground_texture": "res://assets/models/ground_space.png", "visible_ground": false}

func ground_height(_point: Vector3) -> float:
	return 0.0

func build(scene_world: GameWorld) -> void:
	world = scene_world
	filament = Node3D.new()
	filament.name = "VisibleCosmicFilament"
	world.add_child(filament)
	_build_filament()
	supercluster = _whole(Vector2.ZERO, 180.0, 192.0, "Filament supercluster", 4)
	supercluster.context_whole = filament
	supercluster.milestone = true
	_build_supercluster()
	_build_outlying_filaments()
	fabric = world._pool(Vector3(0, 0.035, 0), Vector2(59, 43), Color(0.1, 0.14, 0.2, 0.85), 450.0, 0.0, true)
	fabric.min_tier = 99
	fabric.minimum_radius = 6.0
	_build_background()

func _whole(at: Vector2, size: float, volume: float, label: String, tier: int, parent: Food = null) -> Food:
	var food := world._add_food("", at, size, volume, label, false, tier, parent)
	food.rotation = Vector3.ZERO
	food.height = 0.4
	return food

func _filament_point(t: float) -> Vector3:
	return Vector3(t * 49.0, 0.07, sin(t * 3.7) * 15.0 + t * 8.0)

func _build_filament() -> void:
	var points := PackedVector3Array()
	for index in range(81):
		points.append(_filament_point(index / 40.0 - 1.0))
	_dust_path(filament, points, 1100, 1.5)
	for index in [2, 4, 6]:
		_build_branch(index)

func _dust_path(parent: Node3D, points: PackedVector3Array, count: int, spread: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = plane
	batch.instance_count = count
	for index in count:
		var sample := world._rng.randf_range(0, points.size() - 1.001)
		var point := points[int(sample)].lerp(points[int(sample) + 1], fmod(sample, 1.0))
		point += Vector3(world._rng.randfn(0, spread), 0, world._rng.randfn(0, spread))
		var size := world._rng.randf_range(0.4, 1.7)
		batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), point))
		var tint := Color("8196aa") if index % 3 else Color("c0a88a")
		tint.a = world._rng.randf_range(0.08, 0.25)
		batch.set_instance_color(index, tint)
	var dust := MultiMeshInstance3D.new()
	dust.multimesh = batch
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/star_halo.gdshader")
	material.set_shader_parameter("color", Color.WHITE)
	dust.material_override = material
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(dust)

func _build_supercluster() -> void:
	for index in range(28):
		var point := _group_point(index)
		var group := _whole(Vector2(point.x, point.z), 9.5, 6.3,
			"Galaxy group " + str(index + 1), 3, supercluster)
		group.rotation.y = 0.12 if index == 1 else world._rng.randf_range(-1.8, 1.8)
		_groups.append({"food": group, "home": group.position, "phase": world._rng.randf_range(0, TAU)})
		_build_group(group, index)
		var knot := Geometry.backdrop_model(group.visual, "galaxy_group", Vector3(0, 0.03, 0), 1.8)
		knot.name = "DiffuseGroupHalo"
		group.part_consumed.connect(_group_changed.bind(knot))
	Geometry.backdrop_model(supercluster.visual, "knot", Vector3(0, 0.07, 0), 4.0)

func _build_group(group: Food, index: int) -> void:
	var spiral := _spiral(group, Vector2(-4.2, 0) + _galaxy_offset(), index)
	_galaxies.append(spiral)
	var elliptical := world._add_food("elliptical_galaxy", Vector2(3.4, 3.6) + _galaxy_offset(), 2.3,
		0.375, "Elliptical galaxy", false, 2, group)
	var dwarf := world._add_food("dwarf_galaxy", Vector2(4.0, -4.1) + _galaxy_offset(), 1.4,
		0.33, "Dwarf galaxy", false, 2, group)
	_nonblocking(elliptical)
	_nonblocking(dwarf)
	_galaxies.append_array([elliptical, dwarf])
	for galaxy in [spiral, elliptical, dwarf]:
		galaxy.set_meta("spin", world._rng.randf_range(-0.028, 0.028))
	_nebula(elliptical, Vector2(0.6, 0), 0.8, index * 3 + 1)
	_nebula(dwarf, Vector2.ZERO, 0.7, index * 3 + 2)
	_nebula(elliptical, Vector2(-0.9, -0.5), 0.75, index * 3 + 1)
	_nebula(dwarf, Vector2(0.8, -0.6), 0.6, index * 3 + 2)

func _spiral(group: Food, at: Vector2, seed_index: int) -> Food:
	var galaxy := _whole(at, 4.2, 0.3, "Spiral galaxy", 2, group)
	Geometry.backdrop_model(galaxy.visual, "galaxy_bulge", Vector3.ZERO, 0.92)
	for index in range(3):
		var arm := world._add_food("galaxy_arm", Vector2.ZERO, 3.5, 0.05,
			"Spiral arm", false, 2, galaxy)
		arm.rotation.y = index * TAU / 3.0
		_nonblocking(arm)
		if index < 2:
			_nebula(arm, Vector2(1.7, 0.4), 1.25, seed_index * 3)
	var hole := world._add_food("black_hole", Vector2(0.12, 0.15), 0.35,
		0.045, "Black hole with accretion disk", false, 1, galaxy, 0.7)
	hole.set_meta("accretion_disk", true)
	galaxy.part_consumed.connect(_spiral_changed.bind(galaxy))
	return galaxy

func _nebula(parent: Food, at: Vector2, size: float, index: int) -> void:
	var nebula := world._add_food("nebula", at, size, 0.025, "Stellar nursery nebula", false, 1, parent)
	nebula.rotation = Vector3.ZERO
	_nonblocking(nebula)
	var cluster := _whole(Vector2.ZERO, size * 0.82, 0.0165, "Open star cluster", 1, nebula)
	for star_index in range(9):
		var lobe := Vector2(-0.28, 0.13) if star_index < 6 else Vector2(0.34, -0.22)
		var scatter := Vector2(world._rng.randfn(0, 0.2), world._rng.randfn(0, 0.14))
		var position := (lobe + scatter).limit_length(0.9) * size
		var kind: String = ["red_dwarf", "yellow_star", "blue_giant"][star_index % 3]
		var star_size: float = [0.115, 0.15, 0.2][star_index % 3]
		var star := world._add_food(kind, position,
			star_size, 0.00225, kind.replace("_", " ").capitalize(), false, 0, cluster, 0.025)
		_stars.append({"food": star, "home": star.position, "phase": world._rng.randf_range(0, TAU), "speed": world._rng.randf_range(0.15, 0.3)})

func _spiral_changed(part: Food, galaxy: Food) -> void:
	if part.model_name != "galaxy_arm":
		return
	var arms := 0
	for child in galaxy.parts:
		if is_instance_valid(child) and child.active and child.model_name == "galaxy_arm":
			arms += 1
	galaxy.rename("Bare galactic bulge" if arms == 0 else "Spiral galaxy · " + str(arms) + " arms", Color("cbbfaa"))

func _group_changed(_part: Food, halo: Node3D) -> void:
	if is_instance_valid(halo):
		halo.scale *= 0.86

func _build_background() -> void:
	var background := Node3D.new()
	background.name = "DistantCosmicWeb"
	world.add_child(background)
	_starfield(background)
	for branch in range(5):
		_background_filament(background, branch)
	var fields := [Vector2(-215, -31), Vector2(-205, 155), Vector2(15, 165), Vector2(220, 35), Vector2(39, -198)]
	for index in range(85):
		var center: Vector2 = fields[index % fields.size()]
		var scatter := Vector2(world._rng.randfn(0, 8), world._rng.randfn(0, 7)).limit_length(13)
		var point := Vector3(center.x + scatter.x, world._rng.randf_range(-1, 3), center.y + scatter.y)
		var kind := "yellow_star" if index % 3 == 0 else "red_dwarf"
		var star := Geometry.backdrop_model(background, kind, point, world._rng.randf_range(0.055, 0.14))
		_background.append({"node": star, "speed": 0.006})
	for index in range(13):
		var center: Vector2 = fields[(index + 1) % 3]
		var scatter := Vector2(world._rng.randfn(0, 7), world._rng.randfn(0, 5)).limit_length(10)
		var point := Vector3(center.x + scatter.x, 0.4, center.y + scatter.y)
		var kind := "elliptical_galaxy" if index % 2 == 0 else "dwarf_galaxy"
		var galaxy := Geometry.backdrop_model(background, kind, point, world._rng.randf_range(1.8, 3.4))
		galaxy.rotation.y = world._rng.randf_range(-PI, PI)
		_background.append({"node": galaxy, "speed": world._rng.randf_range(-0.016, 0.016)})
	var overview := Geometry.backdrop_model(background, "galaxy_group", Vector3(-33.3, 0.06, -15.5), 2.1)
	overview.name = "DistantProjectionOfFilamentSupercluster"
	overview.set_meta("represents", supercluster)

func _starfield(parent: Node3D) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = plane
	batch.instance_count = 4800
	for index in batch.instance_count:
		var point := Vector3(world._rng.randf_range(-250, 250), 0.09, world._rng.randf_range(-225, 185))
		var size := world._rng.randf_range(0.035, 0.12)
		batch.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * size), point))
		var tint := Color("f5e3c4") if index % 4 == 0 else Color("cbd8e5")
		tint.a = world._rng.randf_range(0.3, 0.8)
		batch.set_instance_color(index, tint)
	var stars := MultiMeshInstance3D.new()
	stars.multimesh = batch
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/star_halo.gdshader")
	stars.material_override = material
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(stars)

func _background_filament(parent: Node3D, branch: int) -> void:
	var starts := [Vector2(-260, -150), Vector2(-250, 180), Vector2(250, -220), Vector2(-255, -200), Vector2(-300, 30)]
	var ends := [Vector2(-230, 240), Vector2(280, 220), Vector2(240, 235), Vector2(300, -220), Vector2(-245, -260)]
	var points := PackedVector3Array()
	for index in range(61):
		var t := index / 60.0
		var point: Vector2 = starts[branch].lerp(ends[branch], t)
		point += Vector2(sin(t * 7.0 + branch), cos(t * 5.0 - branch)) * 9.0
		points.append(Vector3(point.x, -0.2, point.y))
	_dust_path(parent, points, 650, 2.2)

func step(delta: float) -> void:
	_step_groups(delta)
	for item in _stars:
		var star: Food = item.food
		if not is_instance_valid(star) or not star.active:
			continue
		var home: Vector3 = item.home
		var phase := world._time * float(item.speed) + float(item.phase)
		star.position = home + Vector3(sin(phase) - sin(item.phase), 0, cos(phase * 0.83) - cos(float(item.phase) * 0.83)) * 0.11
		star.visual.rotation.y += delta * 0.12
	for item in _background:
		item.node.rotation.y += delta * float(item.speed)
	if not _fabric_unlocked and (not is_instance_valid(supercluster) or not supercluster.active):
		_fabric_unlocked = true
		fabric.min_tier = 4

func _nonblocking(food: Food) -> void:
	food.collider_radius = 0.0
	food.collision_layer = 0
	food.collision_mask = 0

func _galaxy_offset() -> Vector2:
	return Vector2(world._rng.randfn(0, 0.75), world._rng.randfn(0, 0.65)).limit_length(1.2)

func _group_point(index: int) -> Vector3:
	var spine := [-0.96, -0.68, -0.68, -0.09, -0.09, 0.58, 0.58]
	var offsets := [Vector2.ZERO, Vector2.ZERO, Vector2(-6, 15), Vector2.ZERO,
		Vector2(14, -14), Vector2.ZERO, Vector2(13, 12)]
	var local := index % 7
	var patch: Vector3 = [Vector3.ZERO, Vector3(115, 0, -43), Vector3(-112, 0, 52), Vector3(5, 0, -105)][index / 7]
	return _filament_point(spine[local]) + Vector3(offsets[local].x, 0, offsets[local].y) + patch

func _build_branch(index: int) -> void:
	var origins := {2: 1, 4: 3, 6: 5}
	var region := (index / 7) * 7
	var start := _group_point(region + origins[index % 7])
	var end := _group_point(index)
	var side := Vector3(-(end.z - start.z), 0, end.x - start.x) * 0.14
	var points := PackedVector3Array()
	for step_index in range(33):
		var t := step_index / 32.0
		points.append(start.lerp(end, t) + side * sin(t * PI))
	_dust_path(filament, points, 220, 0.9)

func _step_groups(delta: float) -> void:
	for entry in _groups:
		var group: Food = entry.food
		if not group.active:
			continue
		var phase: float = entry.phase
		var time := world._time
		group.position = entry.home + Vector3(sin(time * 0.045 + phase) - sin(phase), 0,
			cos(time * 0.035 + phase) - cos(phase)) * 0.55
	for galaxy in _galaxies:
		if galaxy.active:
			galaxy.rotation.y += delta * float(galaxy.get_meta("spin"))

func _build_outlying_filaments() -> void:
	for patch in [Vector3(115, 0, -43), Vector3(-112, 0, 52), Vector3(5, 0, -105)]:
		var points := PackedVector3Array()
		for index in range(81):
			points.append(_filament_point(index / 40.0 - 1.0) + patch)
		_dust_path(filament, points, 1100, 1.5)
		var inward := -1.0 if patch.x > 0 else 1.0
		var start := _filament_point(-inward)
		var finish: Vector3 = _filament_point(inward) + patch
		var link := PackedVector3Array()
		for index in range(33):
			var t := index / 32.0
			link.append(start.lerp(finish, t) + Vector3(0, 0, sin(t * PI) * 6.0))
		_dust_path(filament, link, 300, 1.1)
	for index in [9, 11, 13, 16, 18, 20, 23, 25, 27]:
		_build_branch(index)
