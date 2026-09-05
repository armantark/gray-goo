class_name GameWorld
extends Node3D

var config: Dictionary
var field := Rect2(-18.0, -18.0, 36.0, 36.0)
var foods: Array[Food] = []
var pools: Array[LocalPool] = []
var player_radius := 0.5
var _level := 0
var _revealed := false
var _locked: Array[Food] = []
var _currents: Array[Food] = []
var _time := 0.0

func build(level_index: int) -> void:
	_level = level_index
	match _level:
		0:
			config = {"title": "Quark Dust Ladder", "initial_radius": 0.5, "goal_radius": 3.7,
				"jump_radius": 1.5, "camera_sizes": [16.0, 32.0], "start_position": Vector3(-3.0, 0.0, 3.0), "accent": Color("ffbc70")}
			_lighting(Color("10152e"), Color("a7b9ee"), Color("ff92b1"))
			_terrain(Color("202747"))
			_quarks()
		1:
			config = {"title": "Coral Colony Tide Pool", "initial_radius": 0.55, "goal_radius": 3.65,
				"jump_radius": 1.45, "camera_sizes": [17.0, 32.0], "start_position": Vector3(-4.0, 0.0, 4.0), "accent": Color("73ead9")}
			_lighting(Color("376f83"), Color("e2fff4"), Color("81c9ff"))
			_terrain(Color("c9c7a1"))
			_coral()
		2:
			field = Rect2(-16.0, -16.0, 32.0, 32.0)
			config = {"title": "Skatepark Bowl", "initial_radius": 0.55, "goal_radius": 3.5,
				"jump_radius": 0.0, "camera_sizes": [27.0], "start_position": Vector3(-4.0, 0.0, 3.0), "accent": Color("ffaf68")}
			_lighting(Color("8eabbc"), Color("fff0d0"), Color("98dcff"))
			_terrain(Color("65a6b3"))
			_skatepark()
		3:
			field = Rect2(-20.0, -20.0, 40.0, 40.0)
			config = {"title": "Tablecloth of Everything", "initial_radius": 0.6, "goal_radius": 3.8,
				"jump_radius": 1.6, "camera_sizes": [17.0, 36.0], "start_position": Vector3(-3.0, 0.0, 3.0), "accent": Color("c5a6ff")}
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
	var distance := Vector2(point.x, point.z).length()
	var slope := clampf((distance - 6.0) / 7.0, 0.0, 1.0)
	return 2.2 * slope * slope * (3.0 - 2.0 * slope)

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
	food.rotation.y = atan2(at.x, at.y) * 0.55
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

func _quarks() -> void:
	# Three curling particle streams converge on the small proton assemblies.
	for stream in range(3):
		for i in range(14):
			var angle := float(i) * 0.47 + stream * TAU / 3.0
			var distance := 2.2 + i * 0.28
			var at := Vector2(cos(angle), sin(angle)) * distance
			var particle := _add_food("quark", at, 0.22, 0.34, 0.05, "Quark", true)
			particle.drift = Vector3(-sin(angle), 0.0, cos(angle)) * 0.18
			_currents.append(particle)
	for i in range(7):
		var angle := i * TAU / 7.0 + 0.3
		var at := Vector2(cos(angle), sin(angle)) * 6.4
		var proton := _add_food("proton", at, 0.88, 0.95, 0.7, "Proton")
		for part in range(3):
			var phi := part * TAU / 3.0
			_add_food("quark", Vector2(cos(phi), sin(phi)) * 0.84, 0.26, 0.43, 0.07, "Bound quark", false, 0, proton, 0.04)
	for i in range(8):
		var angle := i * TAU / 8.0 + 0.12
		_add_food("nucleus", Vector2(cos(angle), sin(angle)) * 10.0, 1.5, 1.65, 2.6, "Nucleus", false, 1)
	for i in range(3):
		var angle := i * TAU / 3.0 - 0.4
		_add_food("nucleus", Vector2(cos(angle), sin(angle)) * 14.0, 2.5, 2.55, 7.0, "Heavy nucleus", false, 1)
	var final := _add_food("nucleus", Vector2(0.0, -14.0), 3.4, 3.0, 12.0, "Atomic heart", false, 1)
	final.milestone = true
	for ring in [4.0, 10.0, 15.5]:
		_ring(Vector2.ZERO, ring, 0.025, 0.018, Color("3b4367"))

func _coral() -> void:
	_pool(Vector3(-2.0, 0.12, 1.0), Vector2(8.0, 6.5), Color(0.14, 0.7, 0.8, 0.59), 3.0)
	_pool(Vector3(7.0, 0.1, -6.0), Vector2(7.0, 5.5), Color(0.15, 0.66, 0.76, 0.64), 2.0)
	for i in range(30):
		var along := float(i) / 29.0
		var at := Vector2(-6.0 + along * 12.0, 2.5 * sin(along * TAU * 1.5) + 1.5)
		var plankton := _add_food("plankton", at, 0.23, 0.33, 0.035, "Plankton", true)
		plankton.drift = Vector3(0.15, 0.0, cos(along * TAU) * 0.09)
		_currents.append(plankton)
	for i in range(10):
		var angle := i * TAU / 10.0
		_add_food("shell", Vector2(cos(angle) * 7.0, sin(angle) * 5.8), 0.4, 0.48, 0.09, "Shell")
	for i in range(6):
		var angle := i * TAU / 6.0 + 0.4
		var coral := _add_food("coral_branch", Vector2(cos(angle) * 5.8, sin(angle) * 4.5), 1.1, 0.92, 0.7, "Coral branch")
		_polyps(coral, 5, 0.23, 0.44, 0.045, 0)
	for i in range(6):
		var angle := i * TAU / 6.0
		var colony := _add_food("coral_branch", Vector2(cos(angle), sin(angle)) * 11.1, 1.9, 1.65, 2.1, "Coral colony", false, 1)
		_polyps(colony, 5, 0.42, 1.1, 0.1, 1)
	for at in [Vector2(-13.0, -8.0), Vector2(12.0, -10.0), Vector2(3.0, 13.0)]:
		_add_food("coral_fan", at, 2.9, 2.5, 5.0, "Coral fan", false, 1)
	var final := _add_food("coral_fan", Vector2(-1.0, -12.0), 3.6, 2.9, 10.0, "Great coral crown", false, 1)
	final.milestone = true
	for i in range(12):
		var angle := i * TAU / 12.0 + 0.2
		_add_food("rock", Vector2(cos(angle), sin(angle)) * 16.0, 0.8 + (i % 3) * 0.2, 1.3, 0.25, "Tide stone", false, 1)

func _polyps(coral: Food, count: int, size: float, threshold: float, volume: float, tier: int) -> void:
	for i in range(count):
		var angle := i * TAU / count
		# Low branch tips keep the living parts in reach before the whole is edible.
		var at := Vector2(cos(angle), sin(angle)) * coral.radius * 0.68
		_add_food("polyp", at, size, threshold, volume, "Living polyp", false, tier, coral, size * (0.25 + (i % 2) * 0.3))

func _skatepark() -> void:
	for lane in range(3):
		for i in range(10):
			var at := Vector2(-5.5 + i * 1.15, -3.8 + lane * 3.2 + sin(i * 0.7) * 0.35)
			_add_food("wheel", at, 0.28, 0.4, 0.045, "Loose wheel", true)
	for i in range(10):
		var angle := i * TAU / 10.0 + 0.2
		var board := _add_food("board", Vector2(cos(angle), sin(angle)) * 6.8, 1.1, 0.73, 0.45, "Skate deck", true)
		board.linear_velocity = Vector3(-sin(angle), 0.0, cos(angle)) * 0.45
	for i in range(8):
		var angle := i * TAU / 8.0
		var board := _add_food("skateboard", Vector2(cos(angle), sin(angle)) * 9.3, 1.5, 1.2, 1.3, "Skateboard", true)
		board.linear_velocity = Vector3(-sin(angle), 0.0, cos(angle)) * 0.65
	for i in range(4):
		var angle := i * TAU / 4.0 + 0.4
		_add_food("rail", Vector2(cos(angle), sin(angle)) * 11.9, 2.0, 1.7, 2.0, "Practice rail")
	for i in range(3):
		var angle := i * TAU / 3.0 + 0.2
		var ramp := _add_food("ramp", Vector2(cos(angle), sin(angle)) * 13.0, 2.8, 2.25, 5.0, "Quarter pipe")
		ramp.rotation.y = -angle + PI * 0.5
	var final := _add_food("ramp", Vector2(0.0, -12.0), 3.5, 2.65, 8.0, "Big quarter pipe")
	final.milestone = true
	_ring(Vector2.ZERO, 13.0, 2.24, 0.16, Color("d4eee7"))
	_ring(Vector2.ZERO, 6.1, 0.035, 0.035, Color("8ac8ca"))
	for i in range(5):
		var stripe := BoxMesh.new()
		stripe.size = Vector3(2.0, 0.018, 0.14)
		var node := Art.mesh_node(stripe, Color("efd9aa"))
		add_child(node)
		node.position = Vector3(-3.0 + i * 1.4, 0.026, -1.7)

func _cosmos() -> void:
	_pool(Vector3(0.0, 0.1, 0.0), Vector2(17.4, 16.0), Color(0.22, 0.36, 0.67, 0.8), 34.0, 2.9, true)
	for arm in range(3):
		for i in range(12):
			var angle := arm * TAU / 3.0 + i * 0.36
			var distance := 1.8 + i * 0.46
			_add_food("knot", Vector2(cos(angle), sin(angle)) * distance, 0.25, 0.4, 0.055, "Cosmic knot")
	for i in range(8):
		var angle := i * TAU / 8.0 + 0.2
		_add_food("galaxy", Vector2(cos(angle), sin(angle)) * 7.8, 1.15, 0.86, 0.85, "Galaxy")
	for i in range(7):
		var angle := i * TAU / 7.0
		_add_food("galaxy", Vector2(cos(angle), sin(angle)) * 12.4, 2.0, 1.6, 2.5, "Spiral galaxy", false, 1)
	for at in [Vector2(-11.0, -10.0), Vector2(12.0, -9.0), Vector2(1.0, 13.0)]:
		_add_food("knot", at, 2.65, 2.4, 4.5, "Spacetime knot", false, 1)

func _lighting(background: Color, key: Color, rim: Color) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = background
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = key
	environment.environment.ambient_light_energy = 0.62
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	sun.light_color = key
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 65.0
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(-25.0, 140.0, 0.0)
	fill.light_color = rim
	fill.light_energy = 0.55

func _terrain(color: Color, visible_surface: bool = true) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var resolution := 64 if _level == 2 else 1
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

func _ring(at: Vector2, radius: float, height: float, width: float, color: Color) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - width
	torus.outer_radius = radius + width
	torus.rings = 96
	torus.ring_segments = 8
	var node := Art.mesh_node(torus, color)
	add_child(node)
	node.position = Vector3(at.x, height, at.y)

func _physics_process(delta: float) -> void:
	_time += delta
	for food in _currents:
		if not is_instance_valid(food) or not food.active:
			continue
		if _level == 0:
			var at := food.global_position
			var tangent := Vector3(-at.z, 0.0, at.x).normalized()
			food.drift = tangent * 0.18 - Vector3(at.x, 0.0, at.z) * 0.004
		else:
			food.drift = Vector3(0.14 * cos(_time * 0.08), 0.0, 0.07 * sin(_time * 0.15 + food.global_position.x * 0.3))
