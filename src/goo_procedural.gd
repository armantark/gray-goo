class_name GooProcedural
extends GooBody

# The skin is a continuous, positive radial shape. Ground grips deform that shape
# in world space while the material rotates through it, without a spring-shell solver.
var _roll := Basis.IDENTITY
var _grip_positions := PackedVector3Array()
var _grip_headings := PackedVector3Array()
var _grip_phases := PackedFloat32Array()
var _grip_strides := PackedFloat32Array()
var _grip_weights := PackedFloat32Array()
var _idle := 0.0
var _age := 0.0
var _strain := Vector3.ZERO
var _strain_speed := Vector3.ZERO
var _squash := 0.0
var _squash_speed := 0.0
var _bite_direction := Vector3.ZERO
var _bite_amount := 0.0
var _half_height := 0.0

func configure(start: Vector3, starting_radius: float, ground_height: Callable,
		obstacles: Callable, field: Rect2) -> void:
	super.configure(start, starting_radius, ground_height, obstacles, field)
	for grip in 5:
		_grip_positions.append(global_position)
		_grip_headings.append(Vector3.FORWARD)
		_grip_phases.append(float(grip) / 5.0)
		_grip_strides.append(5.6 + float(grip) * 0.47)
		_grip_weights.append(0.0)
	_half_height = radius / pow(1.12, 2)
	_shape_skin([])
	_update_surface()

func absorb(at: Vector3, color: Color, fraction: float) -> void:
	super.absorb(at, color, fraction)
	_bite_direction = (at - global_position).normalized()
	_bite_amount = minf(0.35, sqrt(maxf(fraction, 0.0)) * 0.4)
	_squash_speed -= minf(fraction * 3.0, 1.2)

func pulse(strength: float) -> void:
	_celebration = maxf(_celebration, 0.55 * strength)
	_squash_speed += lerpf(0.4, 3.0, strength)

func celebrate() -> void:
	_celebration = 1.0
	_squash_speed = -4.0

func _physics_process(delta: float) -> void:
	if not _configured:
		return
	var dt := minf(delta, 1.0 / 30.0)
	_age += dt
	radius = lerpf(radius, _target_radius, 1.0 - exp(-3.5 * dt))
	var moving := _drive.length_squared() > 0.001
	_idle = lerpf(_idle, 0.0 if moving else 1.0, 1.0 - exp(-(4.0 if moving else 0.45) * dt))
	var previous_flow := _flow_drive
	_flow_drive = _flow_drive.lerp(_drive * _speed, 1.0 - exp(-6.0 * dt))
	var acceleration := (_flow_drive - previous_flow) / maxf(dt * radius, 0.001)
	_strain_speed += (-_strain * 65.0 - _strain_speed * 11.0 - acceleration * 0.10) * dt
	_strain = (_strain + _strain_speed * dt).limit_length(0.28)
	_squash_speed += (-_squash * 90.0 - _squash_speed * 8.0) * dt
	_squash = clampf(_squash + _squash_speed * dt, -0.28, 0.30)
	_bite_amount *= exp(-4.0 * dt)
	var spread := lerpf(1.12, 1.82, _idle)
	_half_height = radius / (spread * spread) * (1.0 + _squash)
	var old_center := global_position
	var solids: Array = _obstacles.call(old_center, radius * 3.0)
	_move_core(dt, solids)
	velocity = (global_position - old_center) / maxf(delta, 0.001)
	var travel := Vector3(velocity.x, 0, velocity.z)
	if travel.length_squared() > 0.000001:
		_roll = (Basis(Vector3.UP.cross(travel).normalized(), travel.length() / radius * 0.8 * dt) * _roll).orthonormalized()
	_update_grips(dt, travel.length() / radius)
	_shape_skin(solids)
	_diffuse_pigment(dt)
	_celebration = maxf(0.0, _celebration - dt * 1.5)
	_update_surface(dt)

func _move_core(dt: float, solids: Array) -> void:
	var core_radius := radius * 0.72
	var steps := maxi(1, ceili(_flow_drive.length() * dt / (radius * 0.25)))
	var center := global_position
	for step in steps:
		center += _flow_drive * (dt / steps)
		var ground := float(_ground_height.call(center))
		for solid in solids:
			if float(solid.bottom) > ground + _half_height * 2.0 or float(solid.top) < ground:
				continue
			var offset := Vector3(center.x - solid.center.x, 0, center.z - solid.center.z)
			var distance := offset.length()
			var clearance := float(solid.radius) + core_radius
			if distance >= clearance:
				continue
			var normal := offset / distance if distance > 0.0001 else -_drive.normalized()
			if normal.is_zero_approx():
				normal = Vector3.RIGHT
			var push := normal * (clearance - distance)
			center += push
			_slide_along(normal)
			if solid.has("body") and is_instance_valid(solid.body):
				solid.body.apply_central_impulse(-push * 0.018 / maxf(dt, 0.001))
		center.x = clampf(center.x, _field.position.x + core_radius, _field.end.x - core_radius)
		center.z = clampf(center.z, _field.position.y + core_radius, _field.end.y - core_radius)
	center.y = float(_ground_height.call(center)) + _half_height + radius * 0.018
	global_position = center

func _update_grips(dt: float, travel_rate: float) -> void:
	var moving := _drive.length_squared() > 0.001
	for grip in 5:
		var old_phase := _grip_phases[grip]
		_grip_phases[grip] += dt * maxf(travel_rate, 0.8) / _grip_strides[grip]
		if _grip_phases[grip] >= 1.0:
			_grip_phases[grip] = fmod(_grip_phases[grip], 1.0)
			_grip_strides[grip] = _step_random.randf_range(5.6, 8.0)
		var phase := _grip_phases[grip]
		if phase < 0.25 or _grip_weights[grip] < 0.001:
			var heading := _drive.normalized() if moving else _facing
			_grip_headings[grip] = heading.rotated(Vector3.UP, (float(grip) - 2.0) * 0.48 + sin(float(grip) * 7.1) * 0.14)
			var reach := lerpf(0.85, 1.65, smoothstep(0.0, 0.25, phase))
			_grip_positions[grip] = global_position + _grip_headings[grip] * radius * reach
			_grip_positions[grip].y = float(_ground_height.call(_grip_positions[grip])) + radius * 0.018
		# Once planted, the world position stays fixed until the grip peels away.
		var weight := smoothstep(0.0, 0.25, phase) * (1.0 - smoothstep(0.60, 0.96, phase))
		var distance := Vector2(_grip_positions[grip].x - global_position.x, _grip_positions[grip].z - global_position.z).length() / radius
		weight *= 1.0 - smoothstep(1.7, 2.4, distance)
		if not moving:
			weight = 0.0
		_grip_weights[grip] = lerpf(_grip_weights[grip], weight, 1.0 - exp(-14.0 * dt))
		if phase > 0.60 and old_phase <= 0.60:
			_grip_positions[grip].y += radius * 0.08

func _shape_skin(solids: Array) -> void:
	var spread := lerpf(1.12, 1.82, _idle)
	var skin := radius * 0.018
	for i in _rest.size():
		var direction := _roll * _rest[i].normalized()
		var horizontal := Vector3(direction.x, 0, direction.z)
		var equator := horizontal.length()
		var heading := horizontal / maxf(equator, 0.0001)
		var angle := atan2(direction.z, direction.x)
		var lobes := 0.12 * sin(angle * 3.0 + _ooze_phases.x) * (1.0 - exp(-_idle * 3.0))
		lobes += 0.075 * cos(angle * 5.0 + _ooze_phases.y) * _idle
		lobes += 0.07 * sin(angle + _ooze_phases.z) * _idle
		lobes += sin(angle * 3.0 + _age * 0.55) * _idle * 0.025
		var reach := radius * spread * (1.0 + lobes * equator * equator)
		var low_band := pow(maxf(0.0, 1.0 - direction.y * direction.y), 2.0)
		var floor_pull := 0.0
		for grip in _grip_positions.size():
			var offset := _grip_positions[grip] - global_position
			offset.y = 0.0
			var distance := offset.length()
			var alignment := heading.dot(offset / maxf(distance, 0.0001))
			var cap := exp((alignment - 1.0) / 0.14) * low_band * _grip_weights[grip]
			reach += maxf(0.0, distance - radius * spread) * cap
			floor_pull = maxf(floor_pull, cap * (1.0 - smoothstep(0.60, 0.96, _grip_phases[grip])) * 0.96)
		var local := Vector3(direction.x * reach, direction.y * _half_height, direction.z * reach)
		local += _strain * radius * (direction.y + 1.0) * 0.5
		local += _bite_direction * radius * _bite_amount * exp((direction.dot(_bite_direction) - 1.0) / 0.12)
		local.y = lerpf(local.y, -_half_height, floor_pull)
		var point := global_position + local
		# Clip each radial ray against nearby cylinders. Keeping its direction avoids
		# folding adjacent skin triangles across each other at an obstacle edge.
		for solid in solids:
			if point.y < float(solid.bottom) - skin:
				continue
			var ray := Vector2(point.x - global_position.x, point.z - global_position.z)
			var from := Vector2(global_position.x - solid.center.x, global_position.z - solid.center.z)
			var a := ray.length_squared()
			var b := from.dot(ray)
			var c := from.length_squared() - pow(float(solid.radius) + skin, 2)
			var discriminant := b * b - a * c
			if a > 0.000001 and c > 0.0 and b < 0.0 and discriminant > 0.0:
				var fraction := (-b - sqrt(discriminant)) / a
				if fraction > 0.0 and fraction < 1.0:
					point.x = global_position.x + ray.x * fraction
					point.z = global_position.z + ray.y * fraction
		point.x = clampf(point.x, _field.position.x + skin, _field.end.x - skin)
		point.z = clampf(point.z, _field.position.y + skin, _field.end.y - skin)
		point.y = maxf(point.y, float(_ground_height.call(point)) + skin)
		_points[i] = point
