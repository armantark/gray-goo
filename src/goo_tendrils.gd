extends MeshInstance3D

const SEGMENTS := 16
const SIDES := 8
const MAX_STRANDS := 3
enum State { REACHING, GRIPPING, RETRACTING }

var _body
var _strands: Array[Dictionary] = []
var _forces := PackedVector3Array()
var _solids: Array = []
var _cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()
var _surface := ArrayMesh.new()
var _material: ShaderMaterial

func configure(body) -> void:
	_body = body
	_rng.seed = 4674895
	_forces.resize(body._points.size())
	mesh = _surface
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = body._material.shader
	_material.next_pass = body._material.next_pass.duplicate()
	_material.next_pass.set_shader_parameter("width", 0.75)
	material_override = _material

func advance(dt: float) -> PackedVector3Array:
	_forces.fill(Vector3.ZERO)
	var radius: float = _body.radius
	var rate: float = maxf(_body._speed / (radius * 3.0), 1.0)
	var moving: bool = _body._drive.length_squared() > 0.001 and _body._speed > 0.0
	_solids = _body._obstacles.call(_body.global_position, radius * 4.1)
	_cooldown -= dt
	if moving and _cooldown <= 0.0 and _strands.size() < MAX_STRANDS:
		_spawn()
		_cooldown = _rng.randf_range(0.16, 0.37) / rate
	for index in range(_strands.size() - 1, -1, -1):
		var strand := _strands[index]
		_attach(strand)
		var span: Vector3 = strand.tip - strand.base
		var toward_target: Vector3 = strand.target - _body.global_position
		var forward := Vector3(toward_target.x, 0, toward_target.z).normalized()
		if not moving or forward.dot(_body._drive) < 0.05:
			strand.state = State.RETRACTING
		var extension_speed: float = maxf(radius * 3.0, _body._speed * 2.1)
		if strand.state == State.REACHING:
			strand.tip = strand.tip.move_toward(strand.target, extension_speed * dt)
			strand.tip.y = float(_body._ground_height.call(strand.tip)) + radius * 0.012
			if strand.tip.distance_to(strand.target) < radius * 0.05 and _can_grip(strand.tip):
				strand.state = State.GRIPPING
				strand.rest_length = strand.base.distance_to(strand.tip)
		elif strand.state == State.RETRACTING:
			strand.tip = strand.tip.move_toward(strand.base, (extension_speed + radius) * dt)
			if strand.tip.distance_to(strand.base) < radius * 0.08:
				_strands.remove_at(index)
				continue
		var curve := _curve(strand)
		if curve.size() < SEGMENTS + 1:
			strand.state = State.RETRACTING
			strand.tip = curve[-1]
		if strand.state != State.GRIPPING:
			continue
		if span.length() < radius * 0.6 or not _can_grip(strand.tip):
			strand.state = State.RETRACTING
			continue
		# Only a real ground grip can supply this external tension to the shell.
		strand.rest_length = maxf(radius * 0.05, strand.rest_length - _body._speed * _body._drive.length() * strand.reel * dt)
		var pull := span.normalized()
		var tension := maxf((span.length() - strand.rest_length) * 48.0 * rate * rate - _body.velocity.dot(pull) * 1.8 * rate, 0.0)
		tension = minf(tension, maxf(_body._speed * 5.0, radius * 4.0))
		# Internal fluid pressure spreads fast pulls, while bounded local stress stretches the root.
		var local_share := 0.35 / rate
		for i in _forces.size():
			var share: float = 1.0 - local_share + local_share * strand.weights[i] * _forces.size()
			_forces[i] += pull * tension * share
	return _forces

func _spawn() -> void:
	var direction: Vector3 = _body._drive.normalized().rotated(Vector3.UP, _rng.randf_range(-0.65, 0.65))
	var to_food: Vector3 = _body._food_target - _body.global_position
	to_food.y = 0.0
	if _body._food_radius >= 0.0 and to_food.length() < _body.radius * 3.0 and to_food.normalized().dot(direction) > 0.5:
		direction = direction.lerp(to_food.normalized(), 0.2).normalized()
	var target: Vector3 = _body.global_position + direction * _body.radius * _rng.randf_range(2.3, 2.9)
	target.x = clampf(target.x, _body._field.position.x + _body.radius * 0.05, _body._field.end.x - _body.radius * 0.05)
	target.z = clampf(target.z, _body._field.position.y + _body.radius * 0.05, _body._field.end.y - _body.radius * 0.05)
	target.y = float(_body._ground_height.call(target)) + _body.radius * 0.012
	var strand := {"state": State.REACHING, "target": target, "tip": target,
		"base": Vector3.ZERO, "weights": PackedFloat32Array(), "color": _body.tint,
		"bend": _rng.randf_range(-0.35, 0.35), "reel": _rng.randf_range(0.85, 1.15), "rest_length": 0.0}
	_attach(strand)
	strand.tip = strand.base
	_strands.append(strand)

func _attach(strand: Dictionary) -> void:
	var heading: Vector3 = strand.target - _body.global_position
	heading.y = 0.0
	var direction := (heading.normalized() + Vector3.DOWN * 0.45).normalized()
	var weights := PackedFloat32Array()
	weights.resize(_body._points.size())
	var total := 0.0
	var base := Vector3.ZERO
	var color := Color(0, 0, 0, 0)
	for i in weights.size():
		var local: Vector3 = _body._points[i] - _body.global_position
		var weight := exp((local.normalized().dot(direction) - 1.0) / 0.12)
		weights[i] = weight
		total += weight
		base += _body._points[i] * weight
		color += _body._colors[i] * weight
	for i in weights.size():
		weights[i] /= total
	strand.weights = weights
	strand.base = base / total
	strand.color = color / total

func _can_grip(point: Vector3) -> bool:
	var height: float = _body._ground_height.call(point)
	return absf(point.y - height) <= _body.radius * 0.06 and _segment_clear(point, point)

func _segment_clear(a: Vector3, b: Vector3) -> bool:
	var width: float = _body.radius * 0.043
	var inside: Rect2 = _body._field.grow(-width)
	if not inside.has_point(Vector2(a.x, a.z)) or not inside.has_point(Vector2(b.x, b.z)):
		return false
	for solid in _solids:
		if maxf(a.y, b.y) + width < float(solid.bottom) or minf(a.y, b.y) - width > float(solid.top):
			continue
		var center: Vector3 = solid.center
		var nearest := Geometry2D.get_closest_point_to_segment(Vector2(center.x, center.z), Vector2(a.x, a.z), Vector2(b.x, b.z))
		if nearest.distance_to(Vector2(center.x, center.z)) < float(solid.radius) + width:
			return false
	return true

func _curve(strand: Dictionary) -> PackedVector3Array:
	var base: Vector3 = strand.base
	var tip: Vector3 = strand.tip
	var span := tip - base
	var side := Vector3.UP.cross(span).normalized()
	var bow: Vector3 = side * strand.bend * minf(_body.radius, span.length())
	var control_a := base + span * 0.27 + bow
	var control_b := base + span * 0.73 + bow * 0.65
	var curve := PackedVector3Array([base])
	for segment in range(1, SEGMENTS + 1):
		var t := float(segment) / SEGMENTS
		var point := base.bezier_interpolate(control_a, control_b, tip, t)
		var floor_y: float = _body._ground_height.call(point)
		var section_radius: float = _body.radius * lerpf(0.0425, 0.005, smoothstep(0.0, 1.0, t))
		point.y = maxf(floor_y + section_radius, lerpf(base.y, floor_y + section_radius, smoothstep(0.0, 0.22, t)))
		if not _segment_clear(curve[-1], point):
			break
		curve.append(point)
	return curve

func refresh_mesh() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for strand in _strands:
		_attach(strand)
		var curve := _curve(strand)
		if curve.size() < 2:
			continue
		var start := vertices.size()
		var fade: float = minf(strand.base.distance_to(strand.tip) / (_body.radius * 0.35), 1.0)
		for ring in curve.size():
			var t := float(ring) / (curve.size() - 1)
			var tangent := (curve[mini(ring + 1, curve.size() - 1)] - curve[maxi(ring - 1, 0)]).normalized()
			var side := Vector3.UP.cross(tangent).normalized()
			if side.is_zero_approx():
				side = Vector3.RIGHT
			var up := tangent.cross(side).normalized()
			var thickness: float = _body.radius * lerpf(0.0425, 0.005, smoothstep(0.0, 1.0, t)) * fade
			for edge in SIDES:
				var angle := float(edge) * TAU / SIDES
				var normal := side * cos(angle) + up * sin(angle)
				vertices.append(curve[ring] + normal * thickness - _body.global_position)
				normals.append(normal)
				colors.append(strand.color)
		for ring in curve.size() - 1:
			for edge in SIDES:
				var a := start + ring * SIDES + edge
				var b := start + ring * SIDES + (edge + 1) % SIDES
				indices.append_array(PackedInt32Array([a, a + SIDES, b, b, a + SIDES, b + SIDES]))
		var tip_index := vertices.size()
		vertices.append(curve[-1] - _body.global_position)
		normals.append((curve[-1] - curve[-2]).normalized())
		colors.append(strand.color)
		for edge in SIDES:
			var a := start + (curve.size() - 1) * SIDES + edge
			var b := start + (curve.size() - 1) * SIDES + (edge + 1) % SIDES
			indices.append_array(PackedInt32Array([a, tip_index, b]))
	_surface.clear_surfaces()
	visible = not vertices.is_empty()
	if visible:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		_surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_material.set_shader_parameter("celebration", _body._celebration)
