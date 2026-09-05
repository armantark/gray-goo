class_name GameWorld
extends Node3D

var config: Dictionary
var field := Rect2(-50.0, -50.0, 100.0, 100.0)
var foods: Array[Food] = []
var pools: Array[LocalPool] = []
var player_radius := 0.5
var _level := 0
var _revealed := false
var _locked: Array[Food] = []
var _currents: Array[Food] = []
var _time := 0.0
var _rng := RandomNumberGenerator.new()

func build(level_index: int) -> void:
	_level = level_index
	_rng.seed = 7309 + level_index * 197
	match _level:
		0:
			config = {"title": "Quark Dust Ladder", "meters_per_unit": 1e-15, "initial_radius": 0.5, "goal_radius": 3.85,
				"jump_radius": 1.5, "camera_sizes": [14.0, 26.0], "start_position": Vector3(-32.0, 0.0, 29.0), "accent": Color("ffbc70")}
			_lighting(Color("10152e"), Color("a7b9ee"), Color("ff92b1"))
			_terrain(Color("202747"))
			_quarks()
		1:
			config = {"title": "Coral Colony Tide Pool", "meters_per_unit": 0.01, "initial_radius": 0.55, "goal_radius": 3.75,
				"jump_radius": 1.45, "camera_sizes": [14.0, 26.0], "start_position": Vector3(-33.0, 0.0, 28.0), "accent": Color("73ead9")}
			_lighting(Color("376f83"), Color("e2fff4"), Color("81c9ff"))
			_terrain(Color("c9c7a1"))
			_coral()
		2:
			config = {"title": "Skatepark Bowl", "meters_per_unit": 0.25, "initial_radius": 0.55, "goal_radius": 3.75,
				"jump_radius": 0.0, "camera_sizes": [16.0], "start_position": Vector3(-33.0, 0.0, 29.0), "accent": Color("ffaf68")}
			_lighting(Color("8eabbc"), Color("fff0d0"), Color("98dcff"))
			_terrain(Color("65a6b3"))
			_skatepark()
		3:
			config = {"title": "Tablecloth of Everything", "meters_per_unit": 1e21, "initial_radius": 0.6, "goal_radius": 3.8,
				"jump_radius": 1.6, "camera_sizes": [14.0, 28.0], "start_position": Vector3(-32.0, 0.0, 26.0), "accent": Color("c5a6ff")}
			_lighting(Color("080b1a"), Color("c9c5ff"), Color("679be8"))
			_terrain(Color("080b1a"), false)
			_cosmos()
	player_radius = float(config["initial_radius"])
	_walls()

func get_start() -> Vector3:
	var point: Vector3 = config["start_position"]
	point.y = get_ground_height(point)
	return point

func get_ground_height(point: Vector3) -> float:
	if _level != 2:
		return 0.0
	# The floor and the native collision mesh sample this same bowl profile.
	var distance := Vector2((point.x - 16.0) / 1.2, point.z + 6.0).length()
	var slope := clampf((distance - 9.0) / 10.0, 0.0, 1.0)
	return -2.6 * (1.0 - slope * slope * (3.0 - 2.0 * slope))

func get_obstacles(center: Vector3, reach: float) -> Array:
	var result: Array = []
	for food in foods:
		if not is_instance_valid(food) or not food.active or food.threshold <= player_radius:
			continue
		var offset := Vector2(food.global_position.x - center.x, food.global_position.z - center.z)
		if offset.length_squared() > pow(reach + food.collider_radius, 2):
			continue
		var obstacle := {"center": food.global_position, "radius": food.collider_radius,
			"bottom": food.global_position.y, "top": food.global_position.y + food.height * 0.72}
		if not food.freeze:
			obstacle["body"] = food
		result.append(obstacle)
	return result

func nearest_edible(point: Vector3, goo_radius: float) -> Food:
	var nearest: Food
	var distance := INF
	for food in foods:
		if not is_instance_valid(food) or not food.active or food.threshold > goo_radius:
			continue
		var candidate := point.distance_squared_to(food.center())
		if candidate < distance:
			distance = candidate
			nearest = food
	return nearest

func advance_scale() -> void:
	if _revealed:
		return
	_revealed = true
	for food in _locked:
		if is_instance_valid(food):
			food.active = true
			food.visible = true
			food.collision_layer = 2
	for food in foods:
		if is_instance_valid(food) and food.active and food.tier == 0 and food.radius < 0.3 and food.parent_food == null:
			food.active = false
			food.collision_layer = 0
			food.collision_mask = 0
			food.queue_free()
	_locked.clear()

func _add_food(kind: String, at: Vector2, size: float, threshold: float, volume: float,
		label: String, moving: bool = false, tier: int = 0, parent: Food = null, lift: float = 0.0) -> Food:
	var food := Food.new()
	if parent == null:
		add_child(food)
	else:
		parent.add_child(food)
		parent.parts.append(food)
		food.parent_food = parent
	food.configure(kind, size, threshold, volume, label, moving, tier)
	if parent == null:
		var point := Vector3(at.x, 0.0, at.y)
		food.global_position = point + Vector3.UP * (get_ground_height(point) + lift + (0.05 if moving else 0.0))
	else:
		food.position = Vector3(at.x, lift, at.y)
	food.rotation.y = _rng.randf_range(-PI, PI)
	foods.append(food)
	if tier > 0 and float(config["jump_radius"]) > 0.0:
		food.active = false
		food.visible = false
		food.collision_layer = 0
		_locked.append(food)
	return food

func _pool(at: Vector3, extent: Vector2, color: Color, volume: float, threshold: float = 0.0, fabric: bool = false) -> void:
	var pool := LocalPool.new()
	add_child(pool)
	pool.configure(at, extent, color, volume, threshold, fabric)
	pools.append(pool)

func _patch(center: Vector2, spread: Vector2, count: int, separation: float = 0.8) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for i in range(count):
		var candidate := center
		for attempt in range(40):
			candidate = center + Vector2(_rng.randfn(0.0, 0.48), _rng.randfn(0.0, 0.48)).clamp(Vector2(-1, -1), Vector2(1, 1)) * spread
			candidate = candidate.clamp(field.position + Vector2(5, 5), field.end - Vector2(5, 5))
			var clear := true
			for other in points:
				if other.distance_squared_to(candidate) < separation * separation:
					clear = false
					break
			if clear:
				break
		points.append(candidate)
	return points

func _quarks() -> void:
	var pockets := [Vector2(-32, 28), Vector2(-15, 12), Vector2(5, 30),
		Vector2(30, 9), Vector2(12, -13), Vector2(-24, -31), Vector2(33, -31)]
	var counts := [24, 18, 16, 20, 14, 16, 12]
	for region in range(pockets.size()):
		var center: Vector2 = pockets[region]
		var spread := Vector2(_rng.randf_range(5.0, 8.0), _rng.randf_range(3.0, 6.0))
		var points := _patch(center, spread, counts[region], 0.8)
		for i in range(points.size()):
			var moving := i < 2
			var particle := _add_food("quark", points[i], _rng.randf_range(0.2, 0.29), 0.34, 0.025, "Quark", moving)
			if moving:
				particle.drift = Vector3(_rng.randf_range(-0.12, 0.12), 0.0, _rng.randf_range(-0.12, 0.12))
				_currents.append(particle)
		# Loose assemblies grow along short, differently oriented local chains.
		var direction := Vector2.from_angle(_rng.randf_range(-PI, PI))
		var at := center + direction * 3.0
		var assemblies := 2 if region == 6 else 3
		for i in range(assemblies):
			at += direction.rotated(_rng.randf_range(-0.65, 0.65)) * _rng.randf_range(2.8, 4.3)
			var proton := _add_food("proton", at, _rng.randf_range(0.76, 0.98), 0.9, 0.48, "Proton")
			for part in range(3):
				var phi := part * TAU / 3.0 + _rng.randf_range(-0.22, 0.22)
				_add_food("quark", Vector2.from_angle(phi) * proton.radius * 0.92, 0.25, 0.43, 0.04, "Bound quark", false, 0, proton, 0.04)
	for center in [Vector2(-5, 7), Vector2(17, 32), Vector2(36, -5), Vector2(-31, -17)]:
		for at in _patch(center, Vector2(9, 7), 3, 3.5):
			_add_food("nucleus", at, _rng.randf_range(1.35, 1.65), 1.65, 1.5, "Nucleus", false, 1)
	for at in [Vector2(-39, 14), Vector2(-12, -30), Vector2(16, -27), Vector2(37, 31), Vector2(37, -35)]:
		_add_food("nucleus", at, _rng.randf_range(2.3, 2.7), 2.45, 4.0, "Heavy nucleus", false, 0 if at == Vector2(-39, 14) else 1)
	var final := _add_food("nucleus", Vector2(5, -39), 3.5, 3.65, 10.0, "Atomic heart", false, 1)
	final.milestone = true

func _coral() -> void:
	var beds := [Vector2(-33, 27), Vector2(-14, 10), Vector2(9, 28),
		Vector2(33, 8), Vector2(16, -18), Vector2(-26, -29), Vector2(32, -35)]
	_pool(Vector3(-29, 0.12, 24), Vector2(12, 9), Color(0.14, 0.7, 0.8, 0.59), 1.0)
	_pool(Vector3(-9, 0.1, 9), Vector2(14, 10), Color(0.15, 0.66, 0.76, 0.64), 1.0)
	_pool(Vector3(29, 0.12, 8), Vector2(13, 17), Color(0.14, 0.7, 0.8, 0.59), 1.5)
	_pool(Vector3(-12, 0.1, -29), Vector2(18, 11), Color(0.15, 0.66, 0.76, 0.64), 1.5)
	for region in range(beds.size()):
		var center: Vector2 = beds[region]
		var drift_direction := Vector2.from_angle(_rng.randf_range(-PI, PI))
		var plankton_count: int = [18, 9, 14, 7, 11, 16, 9][region]
		for i in range(plankton_count):
			var at := center + drift_direction * _rng.randf_range(-6.0, 7.0)
			at += drift_direction.orthogonal() * _rng.randfn(0.0, 1.3)
			var plankton := _add_food("plankton", at, _rng.randf_range(0.21, 0.29), 0.33, 0.012, "Plankton", i == 0)
			if i == 0:
				plankton.drift = Vector3(drift_direction.x, 0.0, drift_direction.y) * 0.12
				_currents.append(plankton)
		for at in _patch(center + Vector2(2, 3), Vector2(7, 4), [7, 3, 4, 6, 3, 8, 4][region], 1.0):
			_add_food("shell", at, _rng.randf_range(0.32, 0.48), 0.48, 0.045, "Shell")
		for at in _patch(center + Vector2(-5, 0), Vector2(4, 7), [2, 4, 2, 5, 3, 3, 2][region], 1.7):
			_add_food("rock", at, _rng.randf_range(0.65, 1.1), 1.25, 0.15, "Tide stone")
		for at in _patch(center + Vector2(4, -3), Vector2(6, 5), [2, 1, 3, 2, 2, 1, 3][region], 2.8):
			var coral := _add_food("coral_branch", at, _rng.randf_range(0.95, 1.2), 0.83, 0.38, "Coral branch")
			_polyps(coral, 4, 0.23, 0.44, 0.027, 0)
	for center in [Vector2(-23, -9), Vector2(27, 29), Vector2(24, -26)]:
		for at in _patch(center, Vector2(10, 7), 3, 3.8):
			var colony := _add_food("coral_branch", at, _rng.randf_range(1.7, 2.05), 1.6, 1.4, "Coral colony", false, 1)
			_polyps(colony, 4, 0.4, 1.05, 0.07, 1)
	for at in [Vector2(-40, 17), Vector2(39, -18), Vector2(6, -34), Vector2(2, 39)]:
		_add_food("coral_fan", at, _rng.randf_range(2.65, 3.0), 2.45, 4.0, "Coral fan", false, 0 if at == Vector2(-40, 17) else 1)
	var final := _add_food("coral_fan", Vector2(-11, -39), 3.7, 3.55, 9.0, "Great coral crown", false, 1)
	final.milestone = true

func _polyps(coral: Food, count: int, size: float, threshold: float, volume: float, tier: int) -> void:
	for i in range(count):
		var angle := i * TAU / count + _rng.randf_range(-0.3, 0.3)
		# Low branch tips keep living parts reachable before the colony is edible.
		var at := Vector2.from_angle(angle) * coral.radius * _rng.randf_range(0.6, 0.83)
		_add_food("polyp", at, size, threshold, volume, "Living polyp", false, tier, coral, size * _rng.randf_range(0.2, 0.65))

func _skatepark() -> void:
	var spots := [Vector2(-33, 29), Vector2(-13, 15), Vector2(16, 25),
		Vector2(34, -5), Vector2(14, -7), Vector2(-27, -22), Vector2(27, -34)]
	for region in range(spots.size()):
		var center: Vector2 = spots[region]
		for at in _patch(center, Vector2(7, 5), [18, 9, 12, 6, 15, 14, 10][region], 0.85):
			_add_food("wheel", at, _rng.randf_range(0.26, 0.36), 0.4, 0.032, "Loose wheel")
		var deck_count: int = [6, 3, 4, 5, 6, 3, 5][region]
		for at in _patch(center + Vector2(5, -3), Vector2(9, 6), deck_count, 2.1):
			var moving := region == 1 or region == 4
			var board := _add_food("board", at, _rng.randf_range(0.9, 1.2), 0.73, 0.25, "Skate deck", moving)
			if moving:
				board.linear_velocity = Vector3(_rng.randf_range(-0.3, 0.3), 0.0, _rng.randf_range(-0.3, 0.3))
	for center in [Vector2(-8, 30), Vector2(11, 2), Vector2(31, -27)]:
		for i in range(6):
			var at: Vector2 = center + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-5, 5))
			var board := _add_food("skateboard", at, _rng.randf_range(1.25, 1.65), 1.2, 0.7, "Skateboard", i == 0)
			if i == 0:
				board.linear_velocity = Vector3(0.4, 0.0, -0.25)
	for at in [Vector2(-30, 14), Vector2(-17, 34), Vector2(-8, -2), Vector2(2, 23), Vector2(31, 18),
		Vector2(39, -14), Vector2(-39, -19), Vector2(-13, -25), Vector2(11, -35), Vector2(36, -37)]:
		var rail := _add_food("rail", at, _rng.randf_range(1.8, 2.2), 1.7, 1.1, "Practice rail")
		rail.rotation.y = _rng.randf_range(-0.5, 0.5) + (PI * 0.5 if at.x < 0 else 0.0)
	for at in [Vector2(-40, 19), Vector2(-2, 37), Vector2(38, 34), Vector2(39, 0), Vector2(5, -39)]:
		var ramp := _add_food("ramp", at, _rng.randf_range(2.6, 3.0), 2.25, 2.8, "Quarter pipe")
		ramp.rotation.y = atan2(16.0 - at.x, -6.0 - at.y)
	var final := _add_food("ramp", Vector2(-26, -38), 3.7, 3.6, 8.0, "Big quarter pipe")
	final.milestone = true
	# Coping follows the actual off-center elliptical bowl, not the equipment layout.
	var tube := SurfaceTool.new()
	tube.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(96):
		var angle := float(i) / 96.0 * TAU
		var next_angle := float(i + 1) / 96.0 * TAU
		var a := Vector3(16.0 + cos(angle) * 22.8, 0.035, -6.0 + sin(angle) * 19.0)
		var b := Vector3(16.0 + cos(next_angle) * 22.8, 0.035, -6.0 + sin(next_angle) * 19.0)
		var side := (b - a).cross(Vector3.UP).normalized() * 0.1
		for point in [a - side, b + side, a + side, a - side, b - side, b + side]:
			tube.set_normal(Vector3.UP)
			tube.add_vertex(point)
	add_child(Art.mesh_node(tube.commit(), Color("d4eee7")))

func _cosmos() -> void:
	_pool(Vector3(0, 0.1, 0), Vector2(44, 43), Color(0.22, 0.36, 0.67, 0.8), 24.0, 3.3, true)
	var groups := [Vector2(-32, 26), Vector2(-12, 10), Vector2(13, 30),
		Vector2(31, 6), Vector2(9, -13), Vector2(-25, -28), Vector2(27, -31)]
	for region in range(groups.size()):
		var center: Vector2 = groups[region]
		var direction := Vector2.from_angle(_rng.randf_range(-PI, PI))
		var count: int = [24, 14, 19, 15, 22, 12, 20][region]
		var points := _patch(center, Vector2(6, 5), count - 8, 0.8)
		for i in range(8):
			var distance := _rng.randf_range(3.0, 12.0)
			points.append(center + direction * distance + direction.orthogonal() * _rng.randfn(0.0, 1.4))
		for at in points:
			_add_food("knot", at, _rng.randf_range(0.21, 0.3), 0.4, 0.02, "Cosmic knot")
		var galaxy_count: int = [4, 2, 5, 3, 3, 4, 3][region]
		for at in _patch(center + direction * 5.0, Vector2(8, 6), galaxy_count, 2.6):
			_add_food("galaxy", at, _rng.randf_range(0.85, 1.25), 0.78, 0.3, "Galaxy")
	for center in [Vector2(-23, 15), Vector2(1, 27), Vector2(31, -16), Vector2(-7, -31)]:
		for at in _patch(center, Vector2(10, 8), 4, 3.9):
			_add_food("galaxy", at, _rng.randf_range(1.7, 2.15), 1.55, 1.25, "Spiral galaxy", false, 0 if center == Vector2(-23, 15) else 1)
	for at in [Vector2(-37, -33), Vector2(34, 33), Vector2(34, -35), Vector2(4, -37)]:
		_add_food("knot", at, _rng.randf_range(2.4, 2.8), 2.35, 2.4, "Spacetime knot", false, 1)

func _lighting(background: Color, key: Color, rim: Color) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = background
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = key
	environment.environment.ambient_light_energy = 0.25
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	sun.light_color = key
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(-25.0, 140.0, 0.0)
	fill.light_color = rim
	fill.light_energy = 0.2

func _terrain(color: Color, visible_surface: bool = true) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var resolution := 128 if _level == 2 else 1
	for z in range(resolution):
		for x in range(resolution):
			var corners: Array[Vector3] = []
			for offset in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var p := field.position + Vector2(x + offset.x, z + offset.y) / resolution * field.size
				var point := Vector3(p.x, 0.0, p.y)
				point.y = get_ground_height(point)
				corners.append(point)
			for index in [0, 1, 2, 0, 2, 3]:
				var point := corners[index]
				vertices.append(point)
				var dx := get_ground_height(point + Vector3(0.01, 0, 0)) - get_ground_height(point - Vector3(0.01, 0, 0))
				var dz := get_ground_height(point + Vector3(0, 0, 0.01)) - get_ground_height(point - Vector3(0, 0, 0.01))
				normals.append(Vector3(-dx, 0.02, -dz).normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if visible_surface:
		var surface := Art.mesh_node(mesh, color)
		surface.material_override = Art.ground_material(color, [3.0, 3.0, 5.0, 1.0][_level])
		add_child(surface)
	var body := StaticBody3D.new()
	add_child(body)
	body.collision_layer = 1
	body.collision_mask = 2
	var shape := CollisionShape3D.new()
	var collision := ConcavePolygonShape3D.new()
	collision.set_faces(vertices)
	collision.backface_collision = true
	shape.shape = collision
	body.add_child(shape)

func _walls() -> void:
	for axis in range(2):
		for side in [-1.0, 1.0]:
			var body := StaticBody3D.new()
			add_child(body)
			body.collision_layer = 1
			body.collision_mask = 2
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(1.0, 14.0, field.size.y + 2.0) if axis == 0 else Vector3(field.size.x + 2.0, 14.0, 1.0)
			shape.shape = box
			body.add_child(shape)
			var midpoint := field.get_center()
			body.position = Vector3(midpoint.x, 5.0, midpoint.y)
			if axis == 0:
				body.position.x += side * (field.size.x * 0.5 + 0.5)
			else:
				body.position.z += side * (field.size.y * 0.5 + 0.5)

func _physics_process(delta: float) -> void:
	_time += delta
	for food in _currents:
		if not is_instance_valid(food) or not food.active:
			continue
		var phase := food.global_position.x * 0.17 + food.global_position.z * 0.11
		food.drift = Vector3(0.11 * cos(_time * 0.13 + phase), 0.0, 0.09 * sin(_time * 0.17 + phase))
