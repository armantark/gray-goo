class_name LocalPool
extends Node3D

var pigment := Color(0.16, 0.66, 0.79, 0.7)
var remaining_volume := 0.0
var whole_threshold := 0.0
var center: Vector3:
	get:
		return global_position

const RESOLUTION := 64
const EDGE := 0.015
var _extent := Vector2.ONE
var _step := Vector2.ONE
var _fill := PackedFloat32Array()
var _unit_volume := 0.0
var _surface: MeshInstance3D
var _dirty := false
var _remesh_time := 0.0

func configure(at: Vector3, extent: Vector2, color: Color, volume: float,
		final_threshold: float = 0.0, fabric: bool = false) -> void:
	global_position = at
	_extent = extent
	_step = extent * 2.0 / RESOLUTION
	pigment = color
	whole_threshold = final_threshold
	_fill.resize((RESOLUTION + 1) * (RESOLUTION + 1))
	var weight := 0.0
	for z in range(RESOLUTION + 1):
		for x in range(RESOLUTION + 1):
			var p := Vector2(float(x) / RESOLUTION * 2.0 - 1.0, float(z) / RESOLUTION * 2.0 - 1.0)
			var boundary: float
			if fabric:
				boundary = 1.0 - pow(absf(p.x), 6.0) - pow(absf(p.y), 6.0)
			else:
				var angle := atan2(p.y, p.x)
				boundary = 0.9 + 0.07 * sin(angle * 3.0) + 0.035 * cos(angle * 5.0) - p.length()
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
	material.set_shader_parameter("fabric", fabric)
	_surface.material_override = material
	_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_remesh()

func _index(x: int, z: int) -> int:
	return z * (RESOLUTION + 1) + x

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
	var x_max := mini(RESOLUTION, int(ceil((local.x + contact_radius + _extent.x) / _step.x)))
	var z_min := maxi(0, int(floor((local.z - contact_radius + _extent.y) / _step.y)))
	var z_max := mini(RESOLUTION, int(ceil((local.z + contact_radius + _extent.y) / _step.y)))
	var removed := 0.0
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
	if removed > 0.0:
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
	var reach := _contact_radius(point, goo_radius)
	if reach <= 0.0:
		return false
	var nearest := closest_point(point)
	return Vector2(nearest.x - point.x, nearest.z - point.z).length_squared() < reach * reach

func closest_point(point: Vector3) -> Vector3:
	var best := Vector3(INF, INF, INF)
	var best_distance := INF
	var local := point - global_position
	for z in range(RESOLUTION + 1):
		for x in range(RESOLUTION + 1):
			if _fill[_index(x, z)] <= EDGE:
				continue
			var candidate := _point(x, z)
			var distance := Vector2(candidate.x - local.x, candidate.z - local.z).length_squared()
			if distance < best_distance:
				best_distance = distance
				best = candidate + global_position
	return best

func _process(delta: float) -> void:
	_remesh_time += delta
	if _dirty and _remesh_time >= 0.12:
		_remesh_time = 0.0
		_remesh()

func _remesh() -> void:
	_dirty = false
	var vertices := PackedVector3Array()
	for z in range(RESOLUTION):
		for x in range(RESOLUTION):
			var index := _index(x, z)
			var fa := _fill[index]
			var fb := _fill[index + 1]
			var fc := _fill[index + RESOLUTION + 2]
			var fd := _fill[index + RESOLUTION + 1]
			if maxf(maxf(fa, fb), maxf(fc, fd)) <= EDGE:
				continue
			var a := _point(x, z)
			var b := a + Vector3(_step.x, 0.0, 0.0)
			var c := a + Vector3(_step.x, 0.0, _step.y)
			var d := a + Vector3(0.0, 0.0, _step.y)
			if minf(minf(fa, fb), minf(fc, fd)) > EDGE:
				vertices.append(a)
				vertices.append(b)
				vertices.append(c)
				vertices.append(a)
				vertices.append(c)
				vertices.append(d)
			else:
				_clip_triangle(vertices, [a, b, c], [fa, fb, fc])
				_clip_triangle(vertices, [a, c, d], [fa, fc, fd])
	if vertices.is_empty():
		_surface.mesh = null
		return
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_surface.mesh = mesh

func _clip_triangle(output: PackedVector3Array, points: Array, amounts: Array) -> void:
	var polygon: Array[Vector3] = []
	for i in range(3):
		var previous := (i + 2) % 3
		var inside: bool = amounts[i] > EDGE
		var was_inside: bool = amounts[previous] > EDGE
		if inside != was_inside:
			var fraction: float = (EDGE - amounts[previous]) / (amounts[i] - amounts[previous])
			polygon.append(points[previous].lerp(points[i], fraction))
		if inside:
			polygon.append(points[i])
	for i in range(1, polygon.size() - 1):
		output.append(polygon[0])
		output.append(polygon[i])
		output.append(polygon[i + 1])
