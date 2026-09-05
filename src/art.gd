class_name Art
extends RefCounted

const TOON = preload("res://shaders/toon.gdshader")
const OUTLINE = preload("res://shaders/outline.gdshader")
static var _manifest: Dictionary = {}
static var _models: Dictionary = {}
static var _materials: Dictionary = {}
static var _outline: ShaderMaterial

static func ground_material(color: Color, grain_scale: float = 4.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ground.gdshader")
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("grain_scale", grain_scale)
	return mat

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset_manifest.json"))
	return _manifest

static func material(color: Color, glow: float = 0.0) -> ShaderMaterial:
	var key := color.to_html() + ":" + str(glow)
	if not _materials.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = TOON
		mat.set_shader_parameter("base_color", color)
		mat.set_shader_parameter("glow", glow)
		if _outline == null:
			_outline = ShaderMaterial.new()
			_outline.shader = OUTLINE
		mat.next_pass = _outline
		_materials[key] = mat
	return _materials[key]

static func model(model_name: String, target_radius: float) -> Node3D:
	var info: Dictionary = manifest()[model_name]
	if not _models.has(model_name):
		_models[model_name] = load(info["path"])
	var instance: Node3D = _models[model_name].instantiate()
	instance.scale = Vector3.ONE * target_radius / float(info["radius"])
	_style(instance)
	return instance

static func _style(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var original: Material = node.get_active_material(surface)
			var color := Color.WHITE
			if original is StandardMaterial3D:
				color = original.albedo_color
			node.set_surface_override_material(surface, material(color))
	for child in node.get_children():
		_style(child)

static func food_color(model_name: String) -> Color:
	return Color(manifest()[model_name]["color"])

static func model_height(model_name: String, target_radius: float) -> float:
	var info: Dictionary = manifest()[model_name]
	return float(info["height"]) * target_radius / float(info["radius"])

static func mesh_node(mesh: Mesh, color: Color, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color, glow)
	return node

static func clip_model(node: Node, side: float) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var mat: ShaderMaterial = node.get_active_material(surface).duplicate()
			mat.set_shader_parameter("cut_side", side)
			mat.next_pass = null
			node.set_surface_override_material(surface, mat)
	for child in node.get_children():
		clip_model(child, side)
