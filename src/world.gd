class_name GameWorld
extends Node3D

var config: Dictionary
var field := Rect2(-50.0, -50.0, 100.0, 100.0)
var foods: Array[Food] = []
var pools: Array[LocalPool] = []
var player_radius := 0.5
var _level := 0
var current_tier := 0
var _layout: RefCounted
var _time := 0.0
var _rng := RandomNumberGenerator.new()
# Foods wander a bounded distance from where the layout placed them, so a grid keyed by
# placement plus a wander margin answers "what is near the goo" without scanning every food.
const CELL := 8.0
const WANDER := 8.0
var _cells: Dictionary = {}
var _widest_collider := 0.0

func build(level_index: int) -> void:
	_level = level_index
	_rng.seed = 7309 + level_index * 197
	var layouts := [preload("res://src/levels/sugar_water.gd"), preload("res://src/levels/tide_pool.gd"),
		preload("res://src/levels/skatepark.gd"), preload("res://src/levels/cosmic_web.gd")]
	_layout = layouts[level_index].new()
	config = _layout.definition()
	field = config.field
	_lighting(config.background_color, config.key_color, config.fill_color)
	_terrain(config.ground_color, config.get("visible_ground", true))
	_layout.build(self)
	player_radius = float(config.initial_radius)
	_walls()

func get_start() -> Vector3:
	var point: Vector3 = config["start_position"]
	point.y = get_ground_height(point)
	return point

func get_ground_height(point: Vector3) -> float:
	return _layout.ground_height(point)

func get_obstacles(center: Vector3, reach: float) -> Array:
	var result: Array = []
	for food in nearby(center, reach):
		if not food.active or food.collider_radius <= 0.0 or is_edible(food, player_radius):
			continue
		var point := food.global_position
		var offset := Vector2(point.x - center.x, point.z - center.z)
		if offset.length_squared() > pow(reach + food.collider_radius, 2):
			continue
		var obstacle := {"center": point, "radius": food.collider_radius,
			"bottom": point.y, "top": point.y + food.height * 0.72}
		if not food.freeze:
			obstacle["body"] = food
		result.append(obstacle)
	return result

func nearby(center: Vector3, reach: float) -> Array[Food]:
	if _cells.is_empty():
		_widest_collider = 0.0
		for food in foods:
			var point := food.global_position
			_cells.get_or_add(Vector2i(floori(point.x / CELL), floori(point.z / CELL)), []).append(food)
			_widest_collider = maxf(_widest_collider, food.collider_radius)
	var margin := reach + WANDER + _widest_collider
	var result: Array[Food] = []
	for x in range(floori((center.x - margin) / CELL), floori((center.x + margin) / CELL) + 1):
		for z in range(floori((center.z - margin) / CELL), floori((center.z + margin) / CELL) + 1):
			for food in _cells.get(Vector2i(x, z), []):
				if is_instance_valid(food):
					result.append(food)
	return result

func nearest_edible(point: Vector3, goo_radius: float) -> Food:
	var nearest: Food
	var distance := INF
	for food in foods:
		if not is_edible(food, goo_radius):
			continue
		var candidate := point.distance_squared_to(food.center())
		if candidate < distance:
			distance = candidate
			nearest = food
	return nearest

func is_edible(food: Food, goo_radius: float) -> bool:
	return is_instance_valid(food) and food.active and not food.detail_hidden and food.tier <= current_tier and food.threshold <= goo_radius

func advance_scale(tier_index: int) -> void:
	current_tier = tier_index
	var radius: float = config.jumps[tier_index].radius
	for food in foods:
		food.detail_hidden = food.tier < tier_index and food.radius < radius * 0.12
		if food.detail_hidden:
			if food.parent_food == null:
				food.visual.hide()
			food.set_highlighted(false)
			food.collider_radius = 0.0
			food.collision_layer = 0
			food.collision_mask = 0
	if config.jumps[tier_index].has("meters_per_unit"):
		config.meters_per_unit = config.jumps[tier_index].meters_per_unit

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
	_cells.clear()
	return food

func _pool(at: Vector3, extent: Vector2, color: Color, volume: float, threshold: float = 0.0, fabric: bool = false) -> LocalPool:
	var pool := LocalPool.new()
	add_child(pool)
	pool.configure(at, extent, color, volume, threshold, fabric)
	pools.append(pool)
	return pool

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
	# Compatibility adds shadow-light passes after sRGB conversion, bleaching the palette.
	sun.shadow_enabled = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	sun.directional_shadow_max_distance = 65.0
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(-25.0, 140.0, 0.0)
	fill.light_color = rim
	fill.light_energy = 0.2

func _terrain(color: Color, visible_surface: bool = true) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var resolution := 128 if _level in [1, 2] else 1
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
		surface.material_override = Art.ground_material(color, [3.0, 3.0, 5.0, 12.0][_level], load(config.ground_texture))
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
	_layout.step(delta)
