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
# Scatter and spawn timing draw on this stream. Placed objects set every turn and offset by hand
# after `_add_food` draws its turn, so a build with any seed places them identically.
var _rng := RandomNumberGenerator.new()
var placed: Array[Food] = []
var spawns: Array[Dictionary] = []
# A mover that outlives its spawn point's lifetime shrinks away over this many seconds.
const LEAVE_SECONDS := 0.8
# The goo eats objects whose footprint radius is under its radius times this margin. Its skin
# reaches at least 1.19 radii from its center while moving, so 1.2 keeps "smaller" true on screen.
const EAT_MARGIN := 1.2
# Foods drift, orbit, and roll, so a grid answers "what is near the goo" without scanning every
# food. Each physics tick re-bins a slice, so every food is re-binned within REBIN_SECONDS; a
# food must move less than WANDER in that time.
const CELL := 8.0
const WANDER := 8.0
const REBIN_SECONDS := 0.5
var _cells: Dictionary = {}
var _cell_of: Dictionary = {}
var _rebin_index := 0
var _widest_collider := 0.0
# Foods sorted by footprint. The goo only grows, so the foods it has grown past are a prefix,
# and each frame's newly edible foods are found by advancing a cursor instead of a full scan.
var _by_size: Array[Food] = []
var _grown_past := 0
var _reach := 0.0

func build(level_index: int, random_seed: int = 7309) -> void:
	_level = level_index
	_rng.seed = random_seed + level_index * 197
	var layouts := [preload("res://src/levels/sugar_water.gd"), preload("res://src/levels/tide_pool.gd"),
		preload("res://src/levels/skatepark.gd"), preload("res://src/levels/cosmic_web.gd")]
	_layout = layouts[level_index].new()
	config = _layout.definition()
	field = config.field
	_lighting(config.background_color, config.key_color, config.fill_color)
	_terrain(config.ground_color, config.get("visible_ground", true))
	_layout.build(self)
	player_radius = float(config.initial_radius)
	_reach = player_radius * EAT_MARGIN
	_grown_past = _size_index(_reach)
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
		_cell_of.clear()
		_widest_collider = 0.0
		for food in foods:
			_bin(food)
	var margin := reach + WANDER + _widest_collider
	var result: Array[Food] = []
	for x in range(floori((center.x - margin) / CELL), floori((center.x + margin) / CELL) + 1):
		for z in range(floori((center.z - margin) / CELL), floori((center.z + margin) / CELL) + 1):
			for food in _cells.get(Vector2i(x, z), []):
				if is_instance_valid(food):
					result.append(food)
	return result

func _bin(food: Food) -> void:
	var cell := _cell(food.global_position)
	_cells.get_or_add(cell, []).append(food)
	_cell_of[food] = cell
	_widest_collider = maxf(_widest_collider, food.collider_radius)

func _cell(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / CELL), floori(point.z / CELL))

func _rebin(count: int) -> void:
	if _cells.is_empty():
		return
	for _step in mini(count, foods.size()):
		_rebin_index = (_rebin_index + 1) % foods.size()
		var food := foods[_rebin_index]
		if not is_instance_valid(food) or not food.active:
			continue
		var cell := _cell(food.global_position)
		if cell != _cell_of[food]:
			_cells[_cell_of[food]].erase(food)
			_cells.get_or_add(cell, []).append(food)
			_cell_of[food] = cell

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

# Foods the goo has just grown past that it can eat now. Foods hidden at that moment never report.
func newly_edible(goo_radius: float) -> Array[Food]:
	var result: Array[Food] = []
	_reach = maxf(_reach, goo_radius * EAT_MARGIN)
	while _grown_past < _by_size.size() and _by_size[_grown_past].radius < _reach:
		if is_edible(_by_size[_grown_past], goo_radius):
			result.append(_by_size[_grown_past])
		_grown_past += 1
	return result

func _size_index(size: float) -> int:
	var low := 0
	var high := _by_size.size()
	while low < high:
		var middle := (low + high) >> 1
		if _by_size[middle].radius < size:
			low = middle + 1
		else:
			high = middle
	return low

# The one edibility rule for eating, blocking, and the arrow. A container whose own body is
# hidden, such as a disassembled nucleon, is eaten only through its visible parts.
func is_edible(food: Food, goo_radius: float) -> bool:
	return is_instance_valid(food) and food.active and not food.detail_hidden and food.visual.visible \
		and food.radius < goo_radius * EAT_MARGIN

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

func _add_food(kind: String, at: Vector2, size: float, volume: float,
		label: String, moving: bool = false, tier: int = 0, parent: Food = null, lift: float = 0.0) -> Food:
	var food := Food.new()
	if parent == null:
		add_child(food)
	else:
		parent.add_child(food)
		parent.parts.append(food)
		food.parent_food = parent
	food.configure(kind, size, volume, label, moving, tier)
	if parent == null:
		var point := Vector3(at.x, 0.0, at.y)
		food.global_position = point + Vector3.UP * (get_ground_height(point) + lift + (0.05 if moving else 0.0))
	else:
		food.position = Vector3(at.x, lift, at.y)
	food.rotation.y = _rng.randf_range(-PI, PI)
	foods.append(food)
	if not _cells.is_empty():
		_bin(food)
	_by_size.insert(_size_index(food.radius), food)
	# A food added below the reach is already edible, so it counts as grown past without a signal.
	if food.radius < _reach:
		_grown_past += 1
	return food

# A spawned mover that was eaten or has left the level leaves every registry, so the scans
# stay the size of the live level. Like any meal it keeps its node until the level is freed,
# because the driver and the HUD may still hold it.
func _retire(food: Food) -> void:
	food.active = false
	food.hide()
	food.set_physics_process(false)
	food.collision_layer = 0
	food.collision_mask = 0
	foods.erase(food)
	var index := _by_size.find(food)
	_by_size.remove_at(index)
	if index < _grown_past:
		_grown_past -= 1
	if _cell_of.has(food):
		_cells[_cell_of[food]].erase(food)
		_cell_of.erase(food)

# Placed objects, one row per object: [kind, at, turn in degrees, size], every value chosen by
# hand. `kinds` maps a kind to its "model" (none for a composite), "label", "tier", growth
# "density" (volume per size cubed), visible "whole", and "reason". Optional: "lift" raises it off
# the ground, "fit" (the model's drawn reach per unit of manifest radius) draws a model that
# reaches past its manifest radius within its footprint, and "build" is a callable that adds a
# composite's parts to the placed food.
func place(rows: Array, kinds: Dictionary) -> void:
	for row in rows:
		var kind: Dictionary = kinds[row[0]]
		var food := _make(kind, row[1], row[3])
		food.rotation.y = deg_to_rad(row[2])
		if kind.has("build"):
			kind.build.call(food)
		placed.append(food)

func _make(kind: Dictionary, at: Vector2, size: float) -> Food:
	var food := _add_food(kind.get("model", ""), at, size, kind.density * size * size * size,
		kind.label, false, kind.tier, null, kind.get("lift", 0.0))
	food.context_whole = kind.whole
	food.loose_reason = kind.reason
	var fit: float = kind.get("fit", 1.0)
	food.visual.scale /= fit
	food.height /= fit
	return food

# A spawn point releases movers of one `kind` (as for `place`) while the view is within `tiers`
# (first and last, a Vector2i), `rate` per second on average at jittered intervals, until `limit`
# are live. Each starts at a random point between the ends of `from` (one point for a fixed
# source, two for a stretch of edge) with a size within `sizes`, and leaves after `lifetime`
# seconds or on crossing the field edge. `move` takes the mover ({"food", "age", "from", "at",
# "seed" in 0..1}) and the step, and returns its next ground position; the mover faces along it.
func spawn(point: Dictionary) -> void:
	point.merge({"movers": [], "wait": 0.0})
	spawns.append(point)

func _step_spawns(delta: float) -> void:
	for point in spawns:
		var live := 0
		for mover: Dictionary in point.movers.duplicate():
			var food: Food = mover.food
			mover.age += delta
			if not food.active:
				# Eaten: gone once its meal animation has landed.
				if not food.is_physics_processing():
					_retire(food)
					point.movers.erase(mover)
			elif mover.age > point.lifetime:
				var left: float = (mover.age - point.lifetime) / LEAVE_SECONDS
				food.scale = Vector3.ONE * maxf(0.01, 1.0 - left)
				if left >= 1.0:
					_retire(food)
					point.movers.erase(mover)
			else:
				live += 1
				_move(point, mover, delta)
		point.wait -= delta
		if point.wait <= 0.0 and live < point.limit and current_tier >= point.tiers.x and current_tier <= point.tiers.y:
			_release(point)
			# Jittered, not exponential: at low rates an exponential gap left a minute with no movers.
			point.wait = _rng.randf_range(0.5, 1.5) / point.rate

func _release(point: Dictionary) -> void:
	var at: Vector2 = point.from[0].lerp(point.from[-1], _rng.randf())
	var food := _make(point.kind, at, _rng.randf_range(point.sizes.x, point.sizes.y))
	point.movers.append({"food": food, "age": 0.0, "from": at, "at": at, "seed": _rng.randf()})

func _move(point: Dictionary, mover: Dictionary, delta: float) -> void:
	var food: Food = mover.food
	var next: Vector2 = point.move.call(mover, delta)
	if not field.has_point(next):
		mover.age = point.lifetime
		return
	# Movers flow around larger placed objects, so none drifts inside an outline the goo cannot enter.
	for solid in placed:
		if solid.active and solid.collider_radius > 0.0 and solid.radius > food.radius:
			var away := next - Vector2(solid.global_position.x, solid.global_position.z)
			var clear := solid.collider_radius + food.radius
			if away.length_squared() < clear * clear:
				next += away.normalized() * (clear - away.length())
	var step: Vector2 = next - mover.at
	if step.length_squared() > 0.0000001:
		food.rotation.y = atan2(-step.y, step.x)
	var ground := Vector3(next.x, 0.0, next.y)
	food.position = ground + Vector3.UP * (get_ground_height(ground) + point.kind.get("lift", 0.0))
	mover.at = next

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
	_step_spawns(delta)
	_rebin(ceili(foods.size() * delta / REBIN_SECONDS))
