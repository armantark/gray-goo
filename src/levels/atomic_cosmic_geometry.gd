extends RefCounted

static func line(parent: Node3D, points: PackedVector3Array, color: Color) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in points:
		mesh.surface_add_vertex(point)
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	node.material_override = material
	parent.add_child(node)
	return node

static func ring(parent: Node3D, radius: float, color: Color, y: float = 0.1) -> MeshInstance3D:
	var points := PackedVector3Array()
	for index in range(49):
		var angle := index * TAU / 48.0
		points.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
	return line(parent, points, color)

static func bond(parent: Node3D, start: Vector3, end: Vector3, width: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = width
	mesh.bottom_radius = width
	mesh.height = start.distance_to(end)
	mesh.radial_segments = 6
	var node := Art.mesh_node(mesh, color)
	parent.add_child(node)
	node.position = (start + end) * 0.5
	var up := (end - start).normalized()
	var side := up.cross(Vector3.FORWARD).normalized()
	node.basis = Basis(side, up, side.cross(up).normalized())
	return node
