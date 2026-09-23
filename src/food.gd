class_name Food
extends RigidBody3D

signal part_consumed(part: Food)
signal touched

var title: String
var model_name: String
var radius: float
var height: float
var volume: float
var pigment: Color
var tier: int
var active := true
var detail_hidden := false
var collect_when_empty := false
var milestone := false
var parts: Array[Food] = []
var parent_food: Food
var context_whole: Node3D
var loose_reason := ""
var visual: Node3D
var collider_radius: float
var drift := Vector3.ZERO
var _meal_target: Node3D
var _meal_age := 0.0
var _meal_seconds := 0.34
var _meal_start := Vector3.ZERO
var _meal_scale := Vector3.ONE
var _sway_phase := 0.0
var _highlighted := false
static var _target_outline: ShaderMaterial

func configure(kind: String, size: float, food_volume: float,
		label: String, moving: bool = false, band: int = 0) -> void:
	model_name = kind
	title = label
	radius = size
	height = Art.model_height(kind, size) if not kind.is_empty() else size * 0.4
	volume = food_volume
	pigment = Art.food_color(kind) if not kind.is_empty() else Color.WHITE
	tier = band
	collider_radius = radius if not kind.is_empty() else 0.0
	if kind in ["coral_branch", "coral_fan", "rail"]:
		collider_radius *= 0.48
	if kind == "board":
		collider_radius *= 0.28
	visual = Art.model(kind, size) if not kind.is_empty() else Node3D.new()
	add_child(visual)
	if collider_radius > 0.0:
		var shape := CollisionShape3D.new()
		if kind == "board":
			var deck := BoxShape3D.new()
			deck.size = Vector3(radius * 2.0, maxf(height, 0.04), radius * 0.63)
			shape.shape = deck
			shape.position.y = deck.size.y * 0.5
		else:
			var cylinder := CylinderShape3D.new()
			cylinder.radius = maxf(collider_radius, 0.025)
			cylinder.height = maxf(height * 0.72, 0.04)
			shape.shape = cylinder
			shape.position.y = cylinder.height * 0.5
		add_child(shape)
	collision_layer = 2
	collision_mask = 3
	freeze = not moving
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	mass = clampf(food_volume * 3.0, 0.08, 30.0)
	linear_damp = 0.65
	angular_damp = 1.8
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.38
	physics_material.bounce = 0.12
	physics_material_override = physics_material
	_sway_phase = randf() * TAU
	set_physics_process(moving or kind in ["polyp", "plankton"])

func rename(label: String, color: Color) -> void:
	title = label
	pigment = color
	Art.tint_model(visual, color)

func set_highlighted(enabled: bool) -> void:
	enabled = enabled and active
	if _highlighted == enabled:
		return
	_highlighted = enabled
	if enabled and _target_outline == null:
		_target_outline = ShaderMaterial.new()
		_target_outline.shader = Art.OUTLINE
		_target_outline.set_shader_parameter("ink", Color("ffe05a"))
		_target_outline.set_shader_parameter("width", 5.5)
	_highlight_visual(visual, _target_outline if enabled else null)
	for part in parts:
		if is_instance_valid(part):
			part.set_highlighted(enabled)

# A hop and a flash when the goo grows past this object's size. The flash material is shared
# by every object that crosses on the same frame, so they fade together.
func signal_edible(flash: Material) -> void:
	_highlight_visual(visual, flash)
	var rest := visual.scale
	var tween := visual.create_tween()
	tween.tween_property(visual, "scale", rest * 1.35, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", rest, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _highlight_visual(visual, _target_outline if _highlighted else null))

func _highlight_visual(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_overlay = material
	for child in node.get_children():
		_highlight_visual(child, material)

func remaining_volume(include_empty_parents: bool = true) -> float:
	if not active:
		return 0.0
	var result := volume
	for part in parts:
		if is_instance_valid(part):
			result += part.remaining_volume(false)
	if include_empty_parents:
		var child := self
		var parent := parent_food
		while is_instance_valid(parent) and parent.active and parent.collect_when_empty and parent._last_visible_part(child):
			result += parent.remaining_volume(false) - child.remaining_volume(false)
			child = parent
			parent = parent.parent_food
	return result

func _last_visible_part(except: Food) -> bool:
	for part in parts:
		if is_instance_valid(part) and part.active and not part.detail_hidden and part != except:
			return false
	return true

func meal_color() -> Color:
	var total := volume
	var combined := Vector3(pigment.r, pigment.g, pigment.b) * volume
	for part in parts:
		if is_instance_valid(part) and part.active:
			var portion := part.remaining_volume(false)
			var color := part.meal_color()
			combined += Vector3(color.r, color.g, color.b) * portion
			total += portion
	if total <= 0.0:
		return pigment
	combined /= total
	return Color(combined.x, combined.y, combined.z)

func center() -> Vector3:
	return global_position + Vector3.UP * height * 0.4

func consume(target: Node3D, seconds: float = 0.34) -> void:
	set_highlighted(false)
	active = false
	freeze = true
	collision_layer = 0
	collision_mask = 0
	_disable_parts()
	if is_instance_valid(parent_food):
		parent_food.part_consumed.emit(self)
	_meal_target = target
	_meal_seconds = seconds
	_meal_start = global_position
	_meal_scale = scale
	set_physics_process(true)
	if model_name == "board":
		_snap_board()
	if is_instance_valid(parent_food) and parent_food.active and parent_food.collect_when_empty and parent_food._last_visible_part(self):
		parent_food.consume(target, seconds)

func _disable_parts() -> void:
	for part in parts:
		if not is_instance_valid(part):
			continue
		part.set_highlighted(false)
		if not part.active:
			part.hide()
			part.scale = part._meal_scale
		part.active = false
		part.collision_layer = 0
		part.collision_mask = 0
		part.freeze = true
		part.set_physics_process(false)
		part._disable_parts()

func _snap_board() -> void:
	var half := visual.duplicate() as Node3D
	add_child(half)
	Art.clip_model(visual, 1.0)
	Art.clip_model(half, -1.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(visual, "rotation:z", 0.55, 0.25)
	tween.tween_property(half, "rotation:z", -0.55, 0.25)
	tween.tween_property(visual, "position:y", radius * 0.2, 0.25)

func _physics_process(delta: float) -> void:
	if is_instance_valid(_meal_target):
		_meal_age += delta
		var progress := clampf(_meal_age / _meal_seconds, 0.0, 1.0)
		global_position = _meal_start.lerp(_meal_target.global_position, progress * progress)
		if progress >= 1.0:
			# Scene graphs keep part references for damage and motion until the level ends.
			hide()
			scale = _meal_scale
			set_physics_process(false)
		else:
			scale = _meal_scale * maxf(0.01, 1.0 - progress)
		return
	if not active:
		return
	if not freeze and drift.length_squared() > 0.0:
		apply_central_force((drift - linear_velocity) * mass * 0.7)
	if model_name in ["polyp", "plankton"]:
		_sway_phase += delta * 1.5
		visual.rotation.z = sin(_sway_phase) * 0.08
