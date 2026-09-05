class_name GooCamera
extends Node3D

const TILT := deg_to_rad(70.0)
var camera: Camera3D
var field: Rect2
var subject: Node3D
var yaw := 0.0
var zoom := 1.0
var _view_size := 10.0
var _target_view := 10.0
var _focus := Vector3.ZERO
var _ground_height: Callable

func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 0.05
	camera.far = 200.0
	add_child(camera)
	camera.make_current()

func configure(bounds: Rect2, view_size: float, target: Node3D, ground: Callable) -> void:
	field = bounds
	subject = target
	_view_size = view_size
	_target_view = view_size
	_ground_height = ground
	yaw = 0.0
	zoom = 1.0
	_focus = subject.global_position
	_update_camera(1.0)

func reveal(view_size: float) -> void:
	_target_view = view_size

func _process(delta: float) -> void:
	if is_instance_valid(subject):
		_update_camera(delta)

func _update_camera(delta: float) -> void:
	_view_size = lerpf(_view_size, _target_view, 1.0 - exp(-2.8 * delta))
	camera.size = _view_size * zoom
	var viewport := get_viewport().get_visible_rect().size
	var half_width := camera.size * viewport.x / viewport.y * 0.5
	var half_depth := camera.size / sin(TILT) * 0.5
	var margin_x := absf(cos(yaw)) * half_width + absf(sin(yaw)) * half_depth
	var margin_z := absf(sin(yaw)) * half_width + absf(cos(yaw)) * half_depth
	var desired := subject.global_position
	var center := field.get_center()
	var extent_x := maxf(0.0, field.size.x * 0.5 - margin_x)
	var extent_z := maxf(0.0, field.size.y * 0.5 - margin_z)
	desired.x = clampf(desired.x, center.x - extent_x, center.x + extent_x)
	desired.z = clampf(desired.z, center.y - extent_z, center.y + extent_z)
	_focus = _focus.lerp(desired, 1.0 - exp(-7.0 * delta))
	var direction := Vector3(sin(yaw) * cos(TILT), sin(TILT), cos(yaw) * cos(TILT))
	camera.global_position = _focus + direction * maxf(camera.size * 1.6, 12.0)
	camera.look_at(_focus, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.006
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(0.75, zoom - 0.07)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(1.3, zoom + 0.07)

func movement_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var right := camera.global_basis.x
	var up := camera.global_basis.y
	right.y = 0.0
	up.y = 0.0
	var direction := right.normalized() * input.x - up.normalized() * input.y
	if direction.length_squared() > 0.001:
		return direction.limit_length(1.0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var destination := mouse_ground_position()
		var offset := destination - subject.global_position
		offset.y = 0.0
		var stop_distance: float = subject.radius * 0.18
		if offset.length() > stop_distance:
			return offset.normalized() * minf(1.0, (offset.length() - stop_distance) / maxf(subject.radius, 0.1))
	return Vector3.ZERO

func mouse_ground_position() -> Vector3:
	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var ground := float(_ground_height.call(subject.global_position))
	var point := origin
	for iteration in 4:
		point = origin + direction * ((ground - origin.y) / direction.y)
		ground = float(_ground_height.call(point))
	return point
