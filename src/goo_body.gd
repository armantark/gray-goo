class_name GooBody
extends Node3D

# The center is the shell's mean, so adhesion and impacts move the whole organism.
const SUBSTEPS := 2
const SOLVER_ITERATIONS := 4
const GRAY := Color(0.57, 0.61, 0.65)
const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_front;
uniform float width = 2.5;
void vertex() {
	vec3 view_normal = MODELVIEW_NORMAL_MATRIX * NORMAL;
	vec2 outward = view_normal.xy / max(length(view_normal.xy), 0.0001);
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	clip.xy += outward * width * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
}
void fragment() {
	ALBEDO = vec3(0.035, 0.045, 0.065);
}
"""
const SILHOUETTE_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_back;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
void fragment() {
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	vec4 scene = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float scene_distance = -scene.z / scene.w;
	float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float hidden = step(scene_distance + 0.025, -VERTEX.z);
	ALBEDO = vec3(0.48, 0.60, 0.65);
	ALPHA = hidden * (1.0 - smoothstep(0.12, 0.3, facing)) * 0.48;
}
"""

var radius: float = 0.6
var velocity := Vector3.ZERO
var tint := GRAY
var render_mesh: MeshInstance3D

var _target_radius: float
var _ground_height: Callable
var _obstacles: Callable
var _field: Rect2
var _drive := Vector3.ZERO
var _speed: float = 0.0
var _food_target := Vector3.ZERO
var _food_radius: float = -1.0
var _reach_direction := Vector3.ZERO
var _reach_strength: float = 0.0
var _stride_phase: float = 0.0
var _steps: Array[Dictionary] = [{}, {}]
var _swing_weights := PackedFloat32Array()
var _swing_targets := PackedVector3Array()
var _planted_weights := PackedFloat32Array()
var _points := PackedVector3Array()
var _previous := PackedVector3Array()
var _previous_dt: float = 1.0 / (Engine.physics_ticks_per_second * SUBSTEPS)
var _rest := PackedVector3Array()
var _faces := PackedInt32Array()
var _edges: Array[Vector2i] = []
var _edge_lengths := PackedFloat32Array()
var _anchors := PackedVector3Array()
var _attached := PackedByteArray()
var _colors := PackedColorArray()
var _normals := PackedVector3Array()
var _gradients := PackedVector3Array()
var _rest_volume: float
var _mesh := ArrayMesh.new()
var _material: ShaderMaterial
var _render_sources: Array[Vector3i] = []
var _render_weights := PackedVector3Array()
var _render_indices := PackedInt32Array()
var _render_vertices := PackedVector3Array()
var _render_normals := PackedVector3Array()
var _render_colors := PackedColorArray()
var _celebration: float = 0.0
var _eyes: Array[MeshInstance3D] = []
var _eye_offsets := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
var _eye_speeds := PackedVector3Array([Vector3.ZERO, Vector3.ZERO])
var _eye_body_velocity := Vector3.ZERO
var _facing := Vector3(0, 0, 1)
var _configured := false
var _contact_radius: float = 0.0

func configure(start: Vector3, starting_radius: float, ground_height: Callable,
		obstacles: Callable, field: Rect2) -> void:
	radius = maxf(starting_radius, 0.05)
	_target_radius = radius
	_ground_height = ground_height
	_obstacles = obstacles
	_field = field
	global_position = start
	global_position.y = maxf(start.y, float(_ground_height.call(start)) + radius)
	_build_shell()
	_build_render_mesh()
	_configured = true
	_update_surface()

func set_drive(direction: Vector3, speed: float) -> void:
	_drive = Vector3(direction.x, 0, direction.z).limit_length(1.0)
	_speed = maxf(speed, 0.0)

func set_food_target(at: Vector3, food_radius: float) -> void:
	_food_target = at
	_food_radius = food_radius

func grow_to(new_radius: float) -> void:
	_target_radius = maxf(_target_radius, new_radius)

func absorb(at: Vector3, color: Color, fraction: float) -> void:
	if not _configured:
		return
	var amount := clampf(fraction, 0.0, 1.0)
	if amount <= 0.0:
		return
	var direction := (at - global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector3.UP
	var spread := lerpf(0.22, 0.65, sqrt(amount))
	for i in _points.size():
		var local_direction := (_points[i] - global_position).normalized()
		var weight := exp((local_direction.dot(direction) - 1.0) / spread)
		_colors[i] = _colors[i].lerp(color, weight * minf(0.95, sqrt(amount) * 1.6))
		# Changing particle momentum makes the bite tug on the actual shell.
		var tug := exp((local_direction.dot(direction) - 1.0) / 0.085)
		_previous[i] -= direction * radius * tug * minf(amount * 32.4, 12.0) * _previous_dt
	_update_tint()

func celebrate() -> void:
	_celebration = 1.0
	for i in _points.size():
		var offset := _points[i] - global_position
		_previous[i] -= Vector3(-offset.x * 9.0, offset.y * 16.8, -offset.z * 9.0) * _previous_dt

func touches(point: Vector3, object_radius: float) -> bool:
	if not _configured:
		return false
	var offset := point - global_position
	if offset.length() > _contact_radius + object_radius:
		return false
	var direction := offset.normalized()
	var envelope := 0.0
	for particle in _points:
		var local := particle - global_position
		if local.normalized().dot(direction) > 0.88:
			envelope = maxf(envelope, local.dot(direction))
	return offset.length() <= envelope + object_radius

func _physics_process(delta: float) -> void:
	if not _configured:
		return
	var dt := minf(delta, 1.0 / 30.0) / SUBSTEPS
	var old_center := global_position
	for _substep in SUBSTEPS:
		_step(dt)
	velocity = (global_position - old_center) / maxf(delta, 0.001)
	_diffuse_pigment(delta)
	_celebration = maxf(0.0, _celebration - delta * 1.5)
	_update_surface(delta)

func _step(dt: float) -> void:
	var old_radius := radius
	radius = lerpf(radius, _target_radius, 1.0 - exp(-3.5 * dt))
	var growth := radius / old_radius
	var center := global_position
	var to_food := _food_target - center
	var reach := 0.0
	if _food_radius >= 0.0 and not to_food.is_zero_approx():
		reach = clampf((radius * 1.5 + _food_radius - to_food.length()) / (radius * 0.35), 0.0, 1.0)
		_reach_direction = to_food.normalized()
	_reach_strength = lerpf(_reach_strength, reach, 1.0 - exp(-9.0 * dt))
	_prepare_steps(dt, center)
	var solids: Array = _obstacles.call(center, radius * 2.2)
	for i in _points.size():
		_points[i] = center + (_points[i] - center) * growth
		_previous[i] = center + (_previous[i] - center) * growth
		# Displacement belongs to the previous step, including across slow-motion changes.
		var point_velocity := (_points[i] - _previous[i]) / _previous_dt
		_previous[i] = _points[i]
		var acceleration := -point_velocity * 4.0 + Vector3.DOWN * radius * 27.0
		_points[i] += point_velocity * dt + acceleration * dt * dt
	# Compliance scales with dt squared so a slow-motion step cannot release a full-speed spring.
	var elasticity := pow(dt * Engine.physics_ticks_per_second * SUBSTEPS, 2.0)
	for iteration in SOLVER_ITERATIONS:
		_solve_edges(elasticity)
		var reach_reaction := _solve_reach(center, dt)
		for i in _points.size():
			var strength := 1.0 - exp(-260.0 * dt / SOLVER_ITERATIONS)
			var extension := ((_swing_targets[i] - _points[i]) * _swing_weights[i] * strength).limit_length(radius * dt * 3.0)
			_points[i] += extension
			reach_reaction += extension
		# Internal reaching cannot translate a free body; planted contacts supply traction.
		reach_reaction /= _points.size()
		for i in _points.size():
			_points[i] -= reach_reaction
		_solve_volume(center, elasticity)
		for i in _points.size():
			_solve_contact(i, solids, dt, iteration == SOLVER_ITERATIONS - 1)
	center = Vector3.ZERO
	for point in _points:
		center += point
	global_position = center / _points.size()
	_previous_dt = dt

func _prepare_steps(dt: float, center: Vector3) -> void:
	_swing_weights.fill(0.0)
	_planted_weights.fill(0.0)
	if _drive.length_squared() < 0.001 or _speed <= 0.0:
		_steps = [{}, {}]
		_stride_phase = 0.0
		return
	_stride_phase += dt * _speed * _drive.length() / radius * 0.75
	for foot in 2:
		var phase := fposmod(_stride_phase + float(foot) * 0.5, 1.0)
		if _steps[foot].is_empty() or phase < float(_steps[foot].phase):
			_start_step(foot, center)
		var step := _steps[foot]
		step.phase = phase
		for j in step.indices.size():
			var i: int = step.indices[j]
			var weight: float = step.weights[j]
			if phase < 0.36:
				var progress := phase / 0.36
				var target: Vector3 = step.starts[j] + step.shift * smoothstep(0.0, 1.0, progress)
				target.y += sin(progress * PI) * radius * 0.12
				target.x = clampf(target.x, _field.position.x + radius * 0.02, _field.end.x - radius * 0.02)
				target.z = clampf(target.z, _field.position.y + radius * 0.02, _field.end.y - radius * 0.02)
				if weight > _swing_weights[i]:
					_swing_targets[i] = target
					_swing_weights[i] = weight
			elif phase < 0.88:
				_planted_weights[i] = maxf(_planted_weights[i], weight)

func _start_step(foot: int, center: Vector3) -> void:
	var forward := _drive.normalized()
	var sideways := forward.cross(Vector3.UP)
	var heading := (forward + sideways * (float(foot) * 2.0 - 1.0) * 0.65).normalized()
	var cap_direction := (heading + Vector3.DOWN * 0.5).normalized()
	var indices := PackedInt32Array()
	var weights := PackedFloat32Array()
	var starts := PackedVector3Array()
	var cap_center := Vector3.ZERO
	var total := 0.0
	for i in _points.size():
		var alignment := (_points[i] - center).normalized().dot(cap_direction)
		var weight := exp((alignment - 1.0) / 0.075)
		if weight < 0.18:
			continue
		indices.append(i)
		weights.append(weight)
		starts.append(_points[i])
		cap_center += _points[i] * weight
		total += weight
	cap_center /= maxf(total, 0.001)
	var target := center + heading * radius * 1.68
	target.x = clampf(target.x, _field.position.x + radius * 0.02, _field.end.x - radius * 0.02)
	target.z = clampf(target.z, _field.position.y + radius * 0.02, _field.end.y - radius * 0.02)
	target.y = float(_ground_height.call(target)) + radius * 0.04
	_steps[foot] = {"phase": 0.0, "indices": indices, "weights": weights,
		"starts": starts, "shift": target - cap_center}

func _solve_edges(elasticity: float) -> void:
	var stiffness := 0.10 * elasticity / (0.8 + 0.2 * elasticity)
	for e in _edges.size():
		var pair := _edges[e]
		var separation := _points[pair.y] - _points[pair.x]
		var distance := separation.length()
		if distance < 0.00001:
			continue
		var correction := separation * ((distance - _edge_lengths[e] * radius) / distance) * stiffness
		_points[pair.x] += correction
		_points[pair.y] -= correction

func _solve_reach(center: Vector3, dt: float) -> Vector3:
	var reaction := Vector3.ZERO
	if _reach_strength < 0.001:
		return reaction
	# A rounded cap of the same constrained shell reaches; no detached appendage or suction.
	for i in _points.size():
		var offset := _points[i] - center
		var cap := exp((offset.normalized().dot(_reach_direction) - 1.0) / 0.06)
		var extension := maxf(radius * 1.5 - offset.dot(_reach_direction), 0.0)
		var strength := 1.0 - exp(-119.0 * dt / SOLVER_ITERATIONS)
		var correction := (_reach_direction * extension * cap * _reach_strength * strength).limit_length(radius * dt * 3.0)
		_points[i] += correction
		reaction += correction
	return reaction

func _solve_volume(center: Vector3, elasticity: float) -> void:
	var stiffness := 0.45 * elasticity / (0.55 + 0.45 * elasticity)
	_gradients.fill(Vector3.ZERO)
	var volume := 0.0
	for f in range(0, _faces.size(), 3):
		var a := _faces[f]
		var b := _faces[f + 1]
		var c := _faces[f + 2]
		var pa := _points[a] - center
		var pb := _points[b] - center
		var pc := _points[c] - center
		volume += pa.dot(pb.cross(pc)) / 6.0
		_gradients[a] += pb.cross(pc) / 6.0
		_gradients[b] += pc.cross(pa) / 6.0
		_gradients[c] += pa.cross(pb) / 6.0
	var denominator := 0.0
	for gradient in _gradients:
		denominator += gradient.length_squared()
	var pressure := (_rest_volume * radius * radius * radius - volume) / maxf(denominator, 0.000001)
	for i in _points.size():
		_points[i] += (_gradients[i] * pressure * stiffness).limit_length(radius * 0.08)

func _solve_contact(i: int, solids: Array, dt: float, last_iteration: bool) -> void:
	var point := _points[i]
	var skin := radius * 0.018
	var floor_y := float(_ground_height.call(point)) + skin
	var was_below := point.y <= floor_y
	point.y = maxf(point.y, floor_y)
	var moving := _drive.length_squared() > 0.001 and _speed > 0.0
	var planted := _planted_weights[i] > 0.25 and _swing_weights[i] < 0.18
	if moving and not planted:
		_attached[i] = 0
	elif _attached[i]:
		var strain := Vector2(point.x - _anchors[i].x, point.z - _anchors[i].z).length()
		if strain > radius * 0.85 or point.y - _anchors[i].y > radius * 0.35:
			_attached[i] = 0
		else:
			point = point.lerp(_anchors[i], 0.78)
	elif was_below or (planted and point.y - floor_y < radius * 0.07):
		point.y = floor_y
		_attached[i] = 1
		_anchors[i] = point
	point.x = clampf(point.x, _field.position.x + skin, _field.end.x - skin)
	point.z = clampf(point.z, _field.position.y + skin, _field.end.y - skin)
	for solid in solids:
		point = _project_obstacle(point, solid, skin, last_iteration, dt)
	_points[i] = point
	if last_iteration and was_below:
		_previous[i].y = minf(_previous[i].y, point.y)

func _project_obstacle(point: Vector3, solid: Dictionary, skin: float,
		last_iteration: bool, dt: float) -> Vector3:
	var obstacle_center: Vector3 = solid.center
	var horizontal := Vector3(point.x - obstacle_center.x, 0, point.z - obstacle_center.z)
	var distance := horizontal.length()
	var solid_radius: float = float(solid.radius) + skin
	var bottom: float = float(solid.bottom) - skin
	var top: float = float(solid.top) + skin
	if distance >= solid_radius or point.y < bottom or point.y > top:
		return point
	var push := Vector3.UP * (top - point.y)
	if bottom > float(_ground_height.call(point)) + skin and point.y - bottom < push.length():
		push = Vector3.DOWN * (point.y - bottom)
	if solid_radius - distance < push.length():
		push = horizontal.normalized() * (solid_radius - distance)
		if distance < 0.0001:
			push = Vector3.RIGHT * solid_radius
	if last_iteration and solid.has("body"):
		var body: RigidBody3D = solid.body
		if is_instance_valid(body):
			body.apply_impulse(-push / maxf(dt, 0.001) * 0.018, point - body.global_position)
	return point + push

func _diffuse_pigment(dt: float) -> void:
	# Equal edge exchanges conserve pigment; gray is never reapplied after eating.
	var next := _colors.duplicate()
	var rate := minf(dt * 0.07, 0.08)
	for edge in _edges:
		var flow := (_colors[edge.y] - _colors[edge.x]) * rate
		next[edge.x] += flow
		next[edge.y] -= flow
	_colors = next
	_update_tint()

func _update_tint() -> void:
	tint = Color(0, 0, 0, 0)
	for color in _colors:
		tint += color
	tint /= _colors.size()

func _build_shell() -> void:
	var t := (1.0 + sqrt(5.0)) / 2.0
	_rest = PackedVector3Array([
		Vector3(-1,t,0), Vector3(1,t,0), Vector3(-1,-t,0), Vector3(1,-t,0),
		Vector3(0,-1,t), Vector3(0,1,t), Vector3(0,-1,-t), Vector3(0,1,-t),
		Vector3(t,0,-1), Vector3(t,0,1), Vector3(-t,0,-1), Vector3(-t,0,1)])
	for i in _rest.size():
		_rest[i] = _rest[i].normalized()
	_faces = PackedInt32Array([0,11,5, 0,5,1, 0,1,7, 0,7,10, 0,10,11,
		1,5,9, 5,11,4, 11,10,2, 10,7,6, 7,1,8, 3,9,4, 3,4,2,
		3,2,6, 3,6,8, 3,8,9, 4,9,5, 2,4,11, 6,2,10, 8,6,7, 9,8,1])
	for _subdivision in 2:
		var cache := {}
		var subdivided := PackedInt32Array()
		for f in range(0, _faces.size(), 3):
			var a := _faces[f]
			var b := _faces[f + 1]
			var c := _faces[f + 2]
			var ab := _midpoint(a, b, cache)
			var bc := _midpoint(b, c, cache)
			var ca := _midpoint(c, a, cache)
			subdivided.append_array(PackedInt32Array([a,ab,ca, b,bc,ab, c,ca,bc, ab,bc,ca]))
		_faces = subdivided
	# These rest lengths belong to the physical shell, not a render-only distortion.
	for i in _rest.size():
		var p := _rest[i]
		var angle := atan2(p.z, p.x)
		var lobes := 1.0 + (0.09 * sin(angle * 3.0 + 0.5) + 0.045 * cos(angle * 5.0)) * (1.0 - p.y * p.y)
		_rest[i] = Vector3(p.x * lobes, p.y, p.z * lobes)
	var seen := {}
	_rest_volume = 0.0
	for f in range(0, _faces.size(), 3):
		var a := _faces[f]
		var b := _faces[f + 1]
		var c := _faces[f + 2]
		_rest_volume += _rest[a].dot(_rest[b].cross(_rest[c])) / 6.0
		for pair in [Vector2i(a,b), Vector2i(b,c), Vector2i(c,a)]:
			var key := Vector2i(mini(pair.x, pair.y), maxi(pair.x, pair.y))
			if not seen.has(key):
				seen[key] = true
				_edges.append(key)
				_edge_lengths.append(_rest[key.x].distance_to(_rest[key.y]))
	for rest_point in _rest:
		_points.append(global_position + rest_point * radius)
		_colors.append(GRAY)
	_previous = _points.duplicate()
	_swing_weights.resize(_points.size())
	_swing_targets.resize(_points.size())
	_planted_weights.resize(_points.size())
	_anchors.resize(_points.size())
	_attached.resize(_points.size())
	_normals.resize(_points.size())
	_gradients.resize(_points.size())

func _midpoint(a: int, b: int, cache: Dictionary) -> int:
	var key := Vector2i(mini(a,b), maxi(a,b))
	if cache.has(key):
		return cache[key]
	var index := _rest.size()
	_rest.append((_rest[a] + _rest[b]).normalized())
	cache[key] = index
	return index

func _build_render_mesh() -> void:
	var weights := PackedVector3Array([Vector3(1,0,0), Vector3(0,1,0), Vector3(0,0,1),
		Vector3(0.5,0.5,0), Vector3(0,0.5,0.5), Vector3(0.5,0,0.5)])
	for f in range(0, _faces.size(), 3):
		var base := _render_sources.size()
		for weight in weights:
			_render_sources.append(Vector3i(_faces[f], _faces[f + 1], _faces[f + 2]))
			_render_weights.append(weight)
		# Godot front faces use clockwise winding.
		for index in [0,5,3, 1,3,4, 2,4,5, 3,5,4]:
			_render_indices.append(base + index)
	_render_vertices.resize(_render_sources.size())
	_render_normals.resize(_render_sources.size())
	_render_colors.resize(_render_sources.size())
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/goo.gdshader")
	var contour_shader := Shader.new()
	contour_shader.code = OUTLINE_SHADER
	var outline_material := ShaderMaterial.new()
	outline_material.shader = contour_shader
	_material.next_pass = outline_material
	render_mesh = MeshInstance3D.new()
	render_mesh.name = "GooSurface"
	render_mesh.mesh = _mesh
	render_mesh.material_override = _material
	add_child(render_mesh)
	var silhouette := MeshInstance3D.new()
	silhouette.name = "OccludedOutline"
	silhouette.mesh = _mesh
	silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shader := Shader.new()
	shader.code = SILHOUETTE_SHADER
	var silhouette_material := ShaderMaterial.new()
	silhouette_material.shader = shader
	silhouette_material.render_priority = 10
	silhouette.material_override = silhouette_material
	add_child(silhouette)
	for _eye_index in 2:
		var eye := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 20
		sphere.rings = 10
		eye.mesh = sphere
		var white := StandardMaterial3D.new()
		white.albedo_color = Color(0.94, 0.96, 0.91)
		white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var eye_outline := ShaderMaterial.new()
		eye_outline.shader = contour_shader
		eye_outline.set_shader_parameter("width", 1.5)
		white.next_pass = eye_outline
		eye.material_override = white
		add_child(eye)
		_eyes.append(eye)
		var pupil := MeshInstance3D.new()
		pupil.mesh = sphere
		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color(0.025, 0.045, 0.055)
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pupil.material_override = ink
		pupil.scale = Vector3(0.50, 0.57, 0.20)
		pupil.position = Vector3(0.10 - float(_eye_index) * 0.20, 0.10, 0.93)
		eye.add_child(pupil)

func _update_surface(delta: float = 0.0) -> void:
	_contact_radius = 0.0
	_normals.fill(Vector3.ZERO)
	for f in range(0, _faces.size(), 3):
		var a := _faces[f]
		var b := _faces[f + 1]
		var c := _faces[f + 2]
		var normal := (_points[b] - _points[a]).cross(_points[c] - _points[a])
		_normals[a] += normal
		_normals[b] += normal
		_normals[c] += normal
	for i in _normals.size():
		_normals[i] = _normals[i].normalized()
		_contact_radius = maxf(_contact_radius, _points[i].distance_to(global_position))
	for i in _render_sources.size():
		var ids := _render_sources[i]
		var w := _render_weights[i]
		var normal := (_normals[ids.x] * w.x + _normals[ids.y] * w.y + _normals[ids.z] * w.z).normalized()
		_render_vertices[i] = _points[ids.x] * w.x + _points[ids.y] * w.y + _points[ids.z] * w.z - global_position
		_render_vertices[i] += normal * radius * 0.04 * (1.0 - w.length_squared())
		_render_normals[i] = normal
		_render_colors[i] = _colors[ids.x] * w.x + _colors[ids.y] * w.y + _colors[ids.z] * w.z
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _render_vertices
	arrays[Mesh.ARRAY_NORMAL] = _render_normals
	arrays[Mesh.ARRAY_COLOR] = _render_colors
	arrays[Mesh.ARRAY_INDEX] = _render_indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_material.set_shader_parameter("celebration", _celebration)
	_update_eyes(delta)

func _update_eyes(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var acceleration := (velocity - _eye_body_velocity) / maxf(delta, 0.001)
	_eye_body_velocity = velocity
	if _drive.length_squared() > 0.01:
		_facing = _facing.lerp(_drive.normalized(), 0.08).normalized()
	var side := _facing.cross(Vector3.UP).normalized()
	for e in _eyes.size():
		var direction := (_facing * 0.34 + Vector3.UP * 0.88 + side * (float(e) * 2.0 - 1.0) * 0.38).normalized()
		var surface := Vector3.ZERO
		var normal := Vector3.ZERO
		var total := 0.0
		for i in _points.size():
			var alignment := (_points[i] - global_position).normalized().dot(direction)
			var weight := exp((alignment - 1.0) * 75.0)
			surface += _points[i] * weight
			normal += _normals[i] * weight
			total += weight
		var dt := minf(delta, 1.0 / 30.0)
		_eye_speeds[e] += (-_eye_offsets[e] * (110.0 + float(e) * 24.0) - _eye_speeds[e] * (11.0 + float(e) * 2.0) - acceleration * 0.28) * dt
		_eye_offsets[e] = (_eye_offsets[e] + _eye_speeds[e] * dt).limit_length(radius * 0.12)
		var surface_normal := normal.normalized()
		_eye_offsets[e] += surface_normal * maxf(-radius * 0.04 - _eye_offsets[e].dot(surface_normal), 0.0)
		_eyes[e].position = surface / total - global_position + surface_normal * radius * 0.10 + _eye_offsets[e]
		var gaze := (Vector3.UP * 0.9 + _facing * 0.3).normalized()
		_eyes[e].basis = Basis(side, gaze.cross(side).normalized(), gaze).scaled(Vector3(0.23, 0.265, 0.23) * radius)
		if camera != null:
			var mouse_offset := get_viewport().get_mouse_position() - camera.unproject_position(_eyes[e].global_position)
			var offset := mouse_offset.limit_length(100.0) * 0.004
			var world_direction := camera.global_basis.z + camera.global_basis.x * offset.x - camera.global_basis.y * offset.y
			var local_direction := _eyes[e].global_basis.inverse() * world_direction
			_eyes[e].get_child(0).position = local_direction.normalized() * 0.9
