class_name Art
extends RefCounted

const TOON = preload("res://shaders/toon.gdshader")
const OUTLINE = preload("res://shaders/outline.gdshader")
const GAS_MODELS := ["nebula", "galaxy_arm", "galaxy_bulge", "galaxy", "elliptical_galaxy", "dwarf_galaxy", "galaxy_group", "knot"]
const STAR_MODELS := ["red_dwarf", "yellow_star", "blue_giant"]
static var _manifest: Dictionary = {}
static var _models: Dictionary = {}
static var _materials: Dictionary = {}
static var _outline: ShaderMaterial

static func ground_material(color: Color, grain_scale: float = 4.0, texture: Texture2D = null) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/ground.gdshader")
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("grain_scale", grain_scale)
	if texture != null:
		mat.set_shader_parameter("albedo", texture)
	return mat

static func manifest() -> Dictionary:
	if _manifest.is_empty():
		_manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset_manifest.json"))
	return _manifest

static func material(color: Color, glow: float = 0.0, texture: Texture2D = null) -> ShaderMaterial:
	var key := color.to_html() + ":" + str(glow)
	if texture != null:
		key += ":" + str(texture.get_instance_id())
	if not _materials.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = TOON
		mat.set_shader_parameter("base_color", color)
		mat.set_shader_parameter("glow", glow)
		if texture != null:
			mat.set_shader_parameter("albedo", texture)
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
	_style(instance, model_name)
	if model_name in STAR_MODELS:
		_star_halo(instance, info)
	return instance

static func _style(node: Node, model_name: String) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var original: Material = node.get_active_material(surface)
			var color := Color.WHITE
			var texture: Texture2D
			if original is StandardMaterial3D:
				color = original.albedo_color
				texture = original.albedo_texture
			var mat: ShaderMaterial
			if model_name in GAS_MODELS:
				mat = gas_material(color, texture)
				if model_name == "galaxy_bulge":
					mat.set_shader_parameter("core_radius", float(manifest()[model_name].radius))
			else:
				var luminous: bool = model_name in STAR_MODELS or model_name == "black_hole"
				mat = material(color, 1.4 if luminous else 0.0, texture)
				if luminous:
					mat.next_pass = null
			node.set_surface_override_material(surface, mat)
		if model_name in GAS_MODELS or model_name in STAR_MODELS:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_style(child, model_name)

static func gas_material(color: Color, texture: Texture2D) -> ShaderMaterial:
	var key := "gas:" + color.to_html() + ":" + str(texture.get_instance_id())
	if not _materials.has(key):
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://shaders/gas.gdshader")
		mat.set_shader_parameter("base_color", color)
		mat.set_shader_parameter("albedo", texture)
		_materials[key] = mat
	return _materials[key]

static func _star_halo(model_root: Node3D, info: Dictionary) -> void:
	var halo := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * float(info.radius) * 5.0
	halo.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/star_halo.gdshader")
	mat.set_shader_parameter("color", Color(info.color))
	halo.material_override = mat
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model_root.add_child(halo)
	halo.position.y = float(info.height) * 0.5

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

static func tint_model(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var mat: Material = node.get_active_material(surface).duplicate()
			if mat is ShaderMaterial:
				mat.set_shader_parameter("base_color", color)
				mat.set_shader_parameter("recolor", true)
			elif mat is StandardMaterial3D:
				mat.albedo_color = color
			if node.material_override != null:
				node.material_override = mat
			else:
				node.set_surface_override_material(surface, mat)
	for child in node.get_children():
		tint_model(child, color)
