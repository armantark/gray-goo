class_name LocalPool
extends Node3D

var pigment := Color(0.16, 0.66, 0.79, 0.7)
var remaining_volume := 0.0
var whole_threshold := 0.0
var min_tier := 0
var minimum_radius := 0.0
var last_contact := Vector3.ZERO
var center: Vector3:
	get:
		return global_position

const EDGE := 0.015
var _extent := Vector2.ONE
var _step := Vector2.ONE
var _fill := PackedFloat32Array()
var _unit_volume := 0.0
var _surface: MeshInstance3D
var _dirty := false
var _upload_time := 0.0
var _resolution := 64
var _mask_texture: ImageTexture
var _basin_heights := PackedFloat32Array()
var _initial_surface := 0.0
var _initial_volume := 0.0
var _basin_bottom := 0.0

func set_basin(height_at: Callable) -> void:
	_initial_surface = global_position.y
	_initial_volume = remaining_volume
	_basin_bottom = _initial_surface
	_basin_heights.resize(_fill.size())
	for z in range(_resolution + 1):
		for x in range(_resolution + 1):
			var index := _index(x, z)
			var height: float = height_at.call(global_position + _point(x, z))
			_basin_heights[index] = height
			_fill[index] *= maxf(0.0, _initial_surface - height)
			_basin_bottom = minf(_basin_bottom, height)
	_lower_surface()
	_dirty = true

func _lower_surface() -> void:
	# Mopping leaves float residue once every cell is dry; below this the pool is empty, as in is_edible.
	if _basin_heights.is_empty() or remaining_volume <= 0.00001:
		return
	var lowest_wet := _initial_surface
	for index in _fill.size():
		if _fill[index] > EDGE:
			lowest_wet = minf(lowest_wet, _basin_heights[index])
	global_position.y = maxf(lowest_wet + 0.02, lerpf(_basin_bottom, _initial_surface, remaining_volume / _initial_volume))
	var weight := 0.0
	for index in _fill.size():
		if _basin_heights[index] >= global_position.y - 0.01 or _fill[index] <= EDGE:
			_fill[index] = 0.0
		weight += _fill[index]
	# A receding shore redistributes the remaining water; only contact grants growth.
	assert(weight > 0.0, "Basin must retain a wet cell while water remains")
	_unit_volume = remaining_volume / weight

func is_edible(tier: int, goo_radius: float) -> bool:
	return remaining_volume > 0.00001 and tier >= min_tier and goo_radius >= minimum_radius

func configure(at: Vector3, extent: Vector2, color: Color, volume: float,
		final_threshold: float = 0.0) -> void:
	global_position = at
	_extent = extent
	_resolution = clampi(int(ceil(maxf(extent.x, extent.y) * 8.0)), 64, 384)
	_step = extent * 2.0 / _resolution
	pigment = color
	whole_threshold = final_threshold
	_fill.resize((_resolution + 1) * (_resolution + 1))
	var weight := 0.0
	for z in range(_resolution + 1):
		for x in range(_resolution + 1):
			var p := Vector2(float(x) / _resolution * 2.0 - 1.0, float(z) / _resolution * 2.0 - 1.0)
			var angle := atan2(p.y, p.x)
			var boundary := 0.9 + 0.07 * sin(angle * 3.0) + 0.035 * cos(angle * 5.0) - p.length()
			var amount := clampf(boundary * 14.0, 0.0, 1.0)
			if amount <= EDGE:
				amount = 0.0
			_fill[_index(x, z)] = amount
			weight += amount
	_unit_volume = volume / weight
	remaining_volume = volume
	_surface = MeshInstance3D.new()
	add_child(_surface)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/liquid.gdshader")
	material.set_shader_parameter("pigment", color)
	material.set_shader_parameter("extent", extent)
	material.set_shader_parameter("mask_threshold", EDGE)
	_mask_texture = ImageTexture.create_from_image(Image.create_from_data(
		_resolution + 1, _resolution + 1, false, Image.FORMAT_RF, _fill.to_byte_array()))
	material.set_shader_parameter("depletion_mask", _mask_texture)
	var plane := PlaneMesh.new()
	plane.size = extent * 2.0
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	_surface.mesh = plane
	_surface.material_override = material
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _index(x: int, z: int) -> int:
	return z * (_resolution + 1) + x

func _point(x: int, z: int) -> Vector3:
	return Vector3(-_extent.x + x * _step.x, 0.0, -_extent.y + z * _step.y)

func _contact_radius(point: Vector3, goo_radius: float) -> float:
	var height := absf(point.y - global_position.y)
	var envelope := goo_radius * 1.08
	if height >= envelope:
		return 0.0
	return sqrt(envelope * envelope - height * height)

func consume_at(point: Vector3, goo_radius: float, delta: float) -> float:
	if remaining_volume <= 0.0 or delta <= 0.0:
		return 0.0
	var contact_radius := _contact_radius(point, goo_radius)
	if contact_radius <= 0.0:
		return 0.0
	var local := point - global_position
	var x_min := maxi(0, int(floor((local.x - contact_radius + _extent.x) / _step.x)))
	var x_max := mini(_resolution, int(ceil((local.x + contact_radius + _extent.x) / _step.x)))
	var z_min := maxi(0, int(floor((local.z - contact_radius + _extent.y) / _step.y)))
	var z_max := mini(_resolution, int(ceil((local.z + contact_radius + _extent.y) / _step.y)))
	var removed := 0.0
	var contact_sum := Vector3.ZERO
	for z in range(z_min, z_max + 1):
		for x in range(x_min, x_max + 1):
			var distance := Vector2(_point(x, z).x - local.x, _point(x, z).z - local.z).length()
			if distance >= contact_radius:
				continue
			var index := _index(x, z)
			var bite := minf(_fill[index], delta * 3.0 * (1.0 - distance / contact_radius))
			if _fill[index] - bite <= EDGE:
				bite = _fill[index]
			_fill[index] -= bite
			removed += bite * _unit_volume
			contact_sum += _point(x, z) * bite * _unit_volume
	if removed > 0.0:
		last_contact = global_position + contact_sum / removed
		remaining_volume = maxf(0.0, remaining_volume - removed)
		_dirty = true
	return removed

func consume_whole() -> float:
	var result := remaining_volume
	remaining_volume = 0.0
	_fill.fill(0.0)
	_surface.mesh = null
	_dirty = false
	return result

func touches(point: Vector3, goo_radius: float) -> bool:
	if remaining_volume <= 0.0:
		return false
	var local := point - global_position
	if absf(local.x) > _extent.x + goo_radius or absf(local.z) > _extent.y + goo_radius:
		return false
	var reach := _contact_radius(point, goo_radius)
	if reach <= 0.0:
		return false
	var nearest := closest_point(point)
	return Vector2(nearest.x - point.x, nearest.z - point.z).length_squared() < reach * reach

func closest_point(point: Vector3) -> Vector3:
	if remaining_volume <= 0.0:
		return Vector3(INF, INF, INF)
	var best := Vector3(INF, INF, INF)
	var best_distance := INF
	var local := point - global_position
	var cell := Vector2i(
		clampi(roundi((local.x + _extent.x) / _step.x), 0, _resolution),
		clampi(roundi((local.z + _extent.y) / _step.y), 0, _resolution))
	# Search out from contact; ordinary bites need only a few neighboring cells.
	for ring in range(_resolution + 1):
		var left := maxi(0, cell.x - ring)
		var right := mini(_resolution, cell.x + ring)
		var top := maxi(0, cell.y - ring)
		var bottom := mini(_resolution, cell.y + ring)
		for z in range(top, bottom + 1):
			var columns = range(left, right + 1) if z == top or z == bottom else [left, right]
			for x in columns:
				if _fill[_index(x, z)] <= EDGE:
					continue
				var candidate := _point(x, z)
				var distance := Vector2(candidate.x - local.x, candidate.z - local.z).length_squared()
				if distance < best_distance:
					best_distance = distance
					best = candidate + global_position
		var unsearched := [
			Rect2(-_extent, Vector2(left * _step.x, _extent.y * 2.0)),
			Rect2(Vector2(-_extent.x + right * _step.x, -_extent.y), Vector2((_resolution - right) * _step.x, _extent.y * 2.0)),
			Rect2(-_extent, Vector2(_extent.x * 2.0, top * _step.y)),
			Rect2(Vector2(-_extent.x, -_extent.y + bottom * _step.y), Vector2(_extent.x * 2.0, (_resolution - bottom) * _step.y))]
		var unsearched_distance := INF
		var local_point := Vector2(local.x, local.z)
		for region in unsearched:
			if region.has_area():
				unsearched_distance = minf(unsearched_distance, local_point.distance_squared_to(local_point.clamp(region.position, region.end)))
		if best_distance <= unsearched_distance:
			break
	return best

func _process(delta: float) -> void:
	_upload_time += delta
	if _dirty and _upload_time >= 0.08:
		_upload_time = 0.0
		_dirty = false
		_lower_surface()
		_mask_texture.update(Image.create_from_data(
			_resolution + 1, _resolution + 1, false, Image.FORMAT_RF, _fill.to_byte_array()))
