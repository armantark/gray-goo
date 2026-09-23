extends RefCounted

const Geometry = preload("res://src/levels/atomic_cosmic_geometry.gd")
const NUCLEON_RADIUS := 0.18
# Each food grows the goo by its visible volume times this density, so a meal's reward always
# matches the size the goo sees it swallow.
const GROWTH_DENSITY := 0.22
const ELEMENTS := ["Nothing", "Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen"]
const COLORS := ["4b5366", "eef0df", "e8d0ab", "c1a3ba", "a1bfaa", "c8a381", "677582", "6087ae", "d87569"]
var world: GameWorld
var sucrose: Food
var drop: Node3D
var _orbits: Array[Dictionary] = []
var _particles: Array[Dictionary] = []
var _formations: Array[Dictionary] = []
var _bonds: Array[Dictionary] = []
var _background: Array[Node3D] = []
var _atoms: Array[Food] = []
var _detail_tier := -1
var _free_hosts: Array[Food] = []
var _nuclei: Array[Food] = []
var _clumps: Array[Dictionary] = []
var _waters: Array[Food] = []
var _drifters: Array[Dictionary] = []

func definition() -> Dictionary:
	return {"title": "Sugar Water", "meters_per_unit": 1e-15,
		"initial_radius": 0.16, "goal_radius": 3.85, "start_position": Vector3(-25, 0, 17),
		"accent": Color("f1c78a"), "field": Rect2(-96, -75, 192, 150),
		"tiers": ["Particle soup", "Formations", "Small nuclei", "Atoms", "Molecules"],
		"jumps": [{"radius": 0.16, "view_size": 5.0}, {"radius": 0.38, "view_size": 12.0},
			{"radius": 0.85, "view_size": 20.0}, {"radius": 1.8, "view_size": 34.0, "meters_per_unit": 1e-11},
			{"radius": 2.5, "view_size": 50.0, "meters_per_unit": 1e-10}],
		"background_color": Color("0b1622"), "ground_color": Color("263644"),
		"key_color": Color("e4ebe8"), "fill_color": Color("8da4bb"),
		"ground_texture": "res://assets/models/ground_particle.png"}

func ground_height(_point: Vector3) -> float:
	return 0.0

func build(scene_world: GameWorld) -> void:
	world = scene_world
	drop = Node3D.new()
	drop.name = "SugarWaterDrop"
	drop.scale = Vector3.ONE * 1.5
	world.add_child(drop)
	Geometry.line(drop, PackedVector3Array([Vector3(-51, 0.03, -27), Vector3(-33, 0.03, -43),
		Vector3(8, 0.03, -47), Vector3(46, 0.03, -36), Vector3(58, 0.03, -8),
		Vector3(49, 0.03, 30), Vector3(14, 0.03, 46), Vector3(-24, 0.03, 42),
		Vector3(-53, 0.03, 17), Vector3(-58, 0.03, -9), Vector3(-51, 0.03, -27)]), Color("91c3d4"))
	_build_sucrose()
	_build_water()
	_build_nursery()
	_build_background()

func _growth(size: float) -> float:
	return GROWTH_DENSITY * pow(size, 3.0)

func _food(kind: String, at: Vector2, size: float, label: String, tier: int, parent: Food = null, lift: float = 0.0) -> Food:
	return world._add_food(kind, at, size, _growth(size), label, false, tier, parent, lift)

# Molecules and nuclei have no body of their own: their growth is the parts they hold, and they
# leave with their last visible part.
func _whole(at: Vector2, size: float, label: String, tier: int, parent: Food = null) -> Food:
	var food := world._add_food("", at, size, 0.0, label, false, tier, parent)
	food.rotation = Vector3.ZERO
	food.height = 0.36
	food.collect_when_empty = true
	if parent == null:
		food.context_whole = drop
	return food

# An atom's electron shell is a body: it grows the goo by its own size and stays edible after
# the goo takes its nucleus or electrons, like a board after its wheels.
func _shell(at: Vector2, size: float, label: String, tier: int, parent: Food = null) -> Food:
	var atom := _whole(at, size, label, tier, parent)
	atom.volume = _growth(size)
	atom.collect_when_empty = false
	return atom

func _build_sucrose() -> void:
	sucrose = _whole(Vector2(6, -5), 17.0, "Sucrose molecule · C12H22O11", 4)
	sucrose.milestone = true
	_add_drift(sucrose, 1.0, 0.012, 0.006)
	var atoms: Array[Food] = []
	var sites: Array[Vector2] = []
	for index in range(6):
		sites.append(Vector2(-6, 0) + Vector2.from_angle(index * TAU / 6) * 4.7)
	for index in range(5):
		sites.append(Vector2(6, 0) + Vector2.from_angle(PI + index * TAU / 5) * 4.3)
	sites.append_array([sites[2] + Vector2(-2.8, 3.7), sites[7] + Vector2(1, -4.5), sites[9] + Vector2(4.3, 0.5)])
	for index in range(14):
		var protons := 8 if index in [5, 10] else 6
		atoms.append(_atom(sucrose, sites[index], protons, protons, 3))
	_ring_bonds(sucrose, atoms, [0, 1, 2, 3, 4, 5])
	_ring_bonds(sucrose, atoms, [6, 7, 8, 9, 10])
	for pair in [[2, 11], [7, 12], [9, 13]]:
		_bond(sucrose, atoms[pair[0]], atoms[pair[1]])
	var bridge := _atom(sucrose, (sites[0] + sites[6]) * 0.5, 8, 8, 3)
	atoms.append(bridge)
	_bond(sucrose, atoms[0], bridge)
	_bond(sucrose, bridge, atoms[6])
	_add_sucrose_hydroxyls(atoms, sites)
	_add_sucrose_hydrogens(atoms)
	sucrose.set_meta("formula", "C12H22O11")
	sucrose.set_meta("atom_count", 45)
	sucrose.set_meta("ring_sizes", [6, 5])

func _add_sucrose_hydroxyls(atoms: Array[Food], sites: Array[Vector2]) -> void:
	for index in [1, 3, 4, 8, 9, 11, 12, 13]:
		var direction := sites[index].normalized()
		var oxygen := _atom(sucrose, sites[index] + direction * 2.4, 8, 8, 3)
		atoms.append(oxygen)
		_bond(sucrose, atoms[index], oxygen)
	for index in range(15, 23):
		var oxygen: Food = atoms[index]
		var at := Vector2(oxygen.position.x, oxygen.position.z)
		var hydrogen := _atom(sucrose, at + at.normalized() * 1.75, 1, 0, 3)
		atoms.append(hydrogen)
		_bond(sucrose, oxygen, hydrogen)

func _add_sucrose_hydrogens(atoms: Array[Food]) -> void:
	for index in [0, 1, 2, 3, 4, 7, 8, 9, 11, 11, 12, 12, 13, 13]:
		var carbon: Food = atoms[index]
		var angle := atoms.size() * 2.39996
		var at := Vector2(carbon.position.x, carbon.position.z) + Vector2.from_angle(angle) * 1.85
		var hydrogen := _atom(sucrose, at, 1, 0, 3)
		atoms.append(hydrogen)
		_bond(sucrose, carbon, hydrogen)

func _ring_bonds(parent: Food, atoms: Array[Food], indices: Array) -> void:
	for index in range(indices.size()):
		_bond(parent, atoms[indices[index]], atoms[indices[(index + 1) % indices.size()]])

func _bond(parent: Food, first: Food, second: Food) -> void:
	var visual := Geometry.bond(parent.visual, first.position + Vector3.UP * 0.17,
		second.position + Vector3.UP * 0.17, 0.055, Color("afbbbe"))
	_bonds.append({"visual": visual, "first": first, "second": second})

func _build_water() -> void:
	var sites := [Vector2(-21, -7), Vector2(-12, -22), Vector2(-15, 4), Vector2(-39, -5),
		Vector2(-44, 8), Vector2(24, 18), Vector2(36, 24), Vector2(31, 1), Vector2(29, 5),
		Vector2(20, 29), Vector2(7, 22), Vector2(-1, 40), Vector2(11, 38), Vector2(3, -32),
		Vector2(17, -35), Vector2(28, -25), Vector2(37, -33), Vector2(42, -17)]
	for index in range(30):
		var center: Vector2 = [Vector2(-60, -40), Vector2(-58, 40), Vector2(60, 40), Vector2(60, -40), Vector2(0, 53)][index % 5]
		sites.append(center + Vector2(world._rng.randfn(0, 15), world._rng.randfn(0, 12)).limit_length(24))
	for site in sites:
		var at: Vector2 = site + Vector2(world._rng.randfn(0, 0.8), world._rng.randfn(0, 0.8))
		var water := _whole(at, 3.7, "Water molecule · H2O", 4)
		var oxygen := _atom(water, Vector2.ZERO, 8, 8, 3)
		for side in [-1, 1]:
			var hydrogen := _atom(water, Vector2(side * 2.25, 1.65), 1, 0, 3)
			_bond(water, oxygen, hydrogen)
		water.set_meta("formula", "H2O")
		_waters.append(water)
		water.rotation.y = world._rng.randf_range(-PI, PI)
		_add_drift(water, world._rng.randf_range(0.7, 1.3), 0.028, 0.014)

func _atom(parent: Food, at: Vector2, protons: int, neutrons: int, tier: int) -> Food:
	var atom_radius := 0.8 if protons <= 2 else 1.45
	var atom := _shell(at, atom_radius, ELEMENTS[protons] + " atom", tier, parent)
	atom.set_meta("protons", protons)
	atom.set_meta("electrons", protons)
	var nucleus := _nucleus(atom, protons, neutrons)
	nucleus.part_consumed.connect(_nucleus_changed.bind(nucleus, atom))
	_add_electrons(atom, protons, atom_radius)
	atom.part_consumed.connect(_atom_changed.bind(atom))
	_atoms.append(atom)
	return atom

func _nucleus(atom: Food, protons: int, neutrons: int) -> Food:
	var nucleus := _whole(Vector2.ZERO, 0.8, ELEMENTS[protons] + " nucleus", 2, atom)
	nucleus.set_meta("protons", protons)
	nucleus.set_meta("neutrons", neutrons)
	_nuclei.append(nucleus)
	for index in range(protons + neutrons):
		var proton := index < protons
		var angle := index * 2.39996
		var distance := sqrt(float(index)) * NUCLEON_RADIUS * 0.86
		var kind := "proton" if proton else "neutron"
		var nucleon := _food(kind, Vector2.from_angle(angle) * distance, NUCLEON_RADIUS,
			kind.capitalize(), 1, nucleus, (index % 3) * 0.035)
		nucleon.set_meta("proton", proton)
	return nucleus

func _add_electrons(atom: Food, count: int, atom_radius: float) -> void:
	var shells := [mini(count, 2)]
	if count > 2:
		shells.append(count - 2)
	for shell in range(shells.size()):
		var orbit_radius := atom_radius * (0.58 if shell == 0 and count > 2 else 1.0)
		var ring := Geometry.ring(atom.visual, orbit_radius, Color("7793a1"), 0.15)
		ring.name = "ElectronShellRing"
		for index in range(shells[shell]):
			var phase: float = TAU * index / shells[shell] + shell * 0.4
			var electron := _food("electron", Vector2.from_angle(phase) * orbit_radius,
				0.065, "Orbital electron", 0, atom, 0.1)
			_orbits.append({"food": electron, "radius": orbit_radius, "phase": phase, "speed": 0.65 + shell * 0.2})

func _nucleus_changed(part: Food, nucleus: Food, atom: Food) -> void:
	if part.get_meta("proton", false):
		nucleus.set_meta("protons", maxi(0, int(nucleus.get_meta("protons")) - 1))
	else:
		nucleus.set_meta("neutrons", maxi(0, int(nucleus.get_meta("neutrons")) - 1))
	var count: int = nucleus.get_meta("protons")
	nucleus.rename(ELEMENTS[count] + " nucleus", Color(COLORS[count]))
	atom.rename(ELEMENTS[count] + " atom", Color(COLORS[count]))
	atom.set_meta("protons", count)
	nucleus.set_meta("formed", true)
	_pack_nucleus(nucleus)
	_refresh_nucleus_proxy(nucleus)
	if count == 0:
		nucleus.rename("Neutron cluster", Color(COLORS[0]))
		atom.rename("Neutron remnant", Color(COLORS[0]))

func _build_nursery() -> void:
	for index in range(16):
		var at := _nursery_point(index)
		var shell := _shell(at, 1.3, "Hydrogen atom" if index % 2 == 0 else "Helium atom", 3)
		shell.rotation.y = world._rng.randf_range(-PI, PI)
		_add_drift(shell, 0.35, 0.035)
		var count := 1 if index % 2 == 0 else 2
		var nucleus := _nucleus(shell, count, 0 if count == 1 else 2)
		nucleus.part_consumed.connect(_nucleus_changed.bind(nucleus, shell))
		_add_electrons(shell, count, 1.1)
		shell.part_consumed.connect(_atom_changed.bind(shell))
		for nucleon in nucleus.parts:
			nucleon.tier = 1
			_clumps.append({"food": nucleon, "home": nucleon.position})
			_bind_quarks(nucleon, 3, index)
	for index in range(12):
		var at := _nursery_point(index + 4)
		var pion := _food("pion", at, 0.21, "Pion", 1)
		_add_drift(pion, 0.45, 0.09)
		pion.context_whole = drop
		pion.loose_reason = "Quark and antiquark condense together in the drop."
		_bind_quarks(pion, 2, index)
	_build_free_hosts()
	for index in range(56):
		_add_free_particle(index)

func _bind_quarks(nucleon: Food, count: int, phase: int) -> void:
	nucleon.collect_when_empty = true
	for index in range(count):
		var at := Vector2.from_angle(TAU * index / count) * 0.23
		var quark := _food("quark", at, 0.075, "Bound quark", 0, nucleon)
		quark.rename("Bound quark", Color(["ed7169", "77bba0", "719ed6"][index % 3]))
		_formations.append({"food": quark, "home": at, "phase": phase * 0.4 + index})
	var gluon := _food("gluon", Vector2.ZERO, 0.06, "Binding gluon", 0, nucleon)
	_particles.append({"food": gluon, "home": Vector2.ZERO, "phase": float(phase), "kind": "gluon"})
	nucleon.part_consumed.connect(_collapse_nucleon.bind(nucleon))

func _collapse_nucleon(part: Food, nucleon: Food) -> void:
	if part.model_name != "quark" or not nucleon.active or nucleon.get_meta("collapsed", false):
		return
	nucleon.visual.hide()
	nucleon.set_meta("collapsed", true)
	nucleon.collider_radius = 0.0
	nucleon.collision_layer = 0
	nucleon.collision_mask = 0
	for sibling in nucleon.parts:
		if is_instance_valid(sibling) and sibling.active:
			sibling.position *= 0.42

func _add_free_particle(index: int) -> void:
	var kinds := ["quark", "quark", "quark", "photon", "electron", "positron", "gluon"]
	var kind: String = kinds[index % kinds.size()]
	var at := _nursery_point(index)
	var particle := _food(kind, at, 0.06 if kind != "quark" else 0.075, kind.capitalize(), 0)
	particle.context_whole = drop
	particle.loose_reason = "Thermal particle soup in the water drop."
	if kind == "quark":
		particle.rename("Free quark", Color(["ed7169", "77bba0", "719ed6"][index % 3]))
	_particles.append({"food": particle, "home": at, "phase": index * 0.71, "kind": kind,
		"capture": _free_hosts[index / 7], "slot": index % 7,
		"direction": Vector2.from_angle(world._rng.randf_range(-PI, PI))})

func _build_background() -> void:
	var sites := [Vector2(-84, -15), Vector2(-77, -33), Vector2(-90, -26), Vector2(-68, 57),
		Vector2(-44, 68), Vector2(-12, 74), Vector2(41, 62), Vector2(58, 71), Vector2(79, 36),
		Vector2(82, -28), Vector2(56, -63), Vector2(19, -71)]
	for index in range(sites.size()):
		var source: Food = sucrose if index % 3 == 0 else _waters[index]
		var root := _molecule_replica(source, 0.35 if index % 3 == 0 else 0.9)
		root.name = "BackgroundSucroseMolecule" if index % 3 == 0 else "BackgroundWaterMolecule"
		world.add_child(root)
		root.position = Vector3(sites[index].x * 1.5, 0.8 + index % 3, sites[index].y * 1.5)
		root.rotation.y = world._rng.randf_range(-PI, PI)
		_background.append(root)

func step(delta: float) -> void:
	_step_drifters()
	_step_orbits(delta)
	_step_particles()
	_step_bonds()
	_step_nucleus_formations()
	for item in _background:
		item.rotation.y += delta * 0.013
		item.position.x += sin(world._time * 0.07) * delta * 0.06
		item.position.z += cos(world._time * 0.05) * delta * 0.04
	_update_detail()

func _step_orbits(delta: float) -> void:
	for orbit in _orbits:
		var electron: Food = orbit.food
		if not is_instance_valid(electron) or not electron.active:
			continue
		orbit.phase += delta * float(orbit.speed)
		var at := electron.position
		at.x = cos(orbit.phase) * float(orbit.radius)
		at.z = sin(orbit.phase) * float(orbit.radius)
		electron.position = at

func _step_particles() -> void:
	for entry in _particles:
		var particle: Food = entry.food
		if not is_instance_valid(particle) or not particle.active:
			continue
		var home: Vector2 = entry.home
		var phase := world._time + float(entry.phase)
		var amplitude := 0.48 if particle.parent_food == null else 0.035
		var offset := Vector2(sin(phase * 0.7), cos(phase * 0.53)) * amplitude
		if entry.kind == "photon":
			offset = entry.direction * (fposmod(phase * 2.8, 9.0) - 4.5)
		if entry.kind == "gluon":
			offset = Vector2(sin(phase * 3.0) * 0.22, 0)
		particle.position.x = home.x + offset.x
		particle.position.z = home.y + offset.y
	for formation in _formations:
		_step_formation(formation)

func _step_formation(formation: Dictionary) -> void:
	var quark: Food = formation.food
	if not is_instance_valid(quark) or not quark.active:
		return
	if quark.parent_food.get_meta("collapsed", false):
		return
	var scale_factor := 1.0 + 3.0 * exp(-world._time * 0.32)
	if world.current_tier > 0:
		scale_factor = 1.0
	var at: Vector2 = formation.home * scale_factor
	quark.position.x = at.x
	quark.position.z = at.y

func _step_bonds() -> void:
	for entry in _bonds:
		if not is_instance_valid(entry.visual):
			continue
		entry.visual.visible = is_instance_valid(entry.first) and is_instance_valid(entry.second) and entry.first.active and entry.second.active

func _update_detail() -> void:
	if _detail_tier == world.current_tier:
		return
	_detail_tier = world.current_tier
	for food in world.foods:
		if food.detail_hidden:
			food.visual.hide()
	if _detail_tier > 0:
		_capture_free_quarks()
	for nucleus in _nuclei:
		if not is_instance_valid(nucleus) or not nucleus.active:
			continue
		_refresh_nucleus_proxy(nucleus)
		for nucleon in nucleus.parts:
			if is_instance_valid(nucleon):
				nucleon.visible = nucleon.active and not nucleon.detail_hidden and _detail_tier < 3

func _build_free_hosts() -> void:
	for index in range(8):
		var shell := _shell(_nursery_point(index + 8), 0.9, "Forming hydrogen atom", 3)
		shell.rotation.y = world._rng.randf_range(-PI, PI)
		_add_drift(shell, 0.35, 0.025)
		var nucleus := _nucleus(shell, 1, 0)
		nucleus.part_consumed.connect(_nucleus_changed.bind(nucleus, shell))
		_add_electrons(shell, 1, 0.8)
		shell.part_consumed.connect(_atom_changed.bind(shell))
		var proton: Food = nucleus.parts[0]
		proton.collect_when_empty = true
		proton.tier = 1
		proton.part_consumed.connect(_collapse_nucleon.bind(proton))
		_free_hosts.append(proton)

func _capture_free_quarks() -> void:
	for entry in _particles:
		var quark: Food = entry.food
		if not is_instance_valid(quark) or not quark.active or entry.kind != "quark":
			continue
		if quark.parent_food != null:
			continue
		var host: Food = entry.capture
		if not is_instance_valid(host) or not host.active:
			continue
		quark.reparent(host, false)
		host.parts.append(quark)
		quark.parent_food = host
		quark.context_whole = null
		quark.loose_reason = ""
		quark.rename("Bound quark", quark.pigment)
		entry.home = Vector2.from_angle(int(entry.slot) * TAU / 3.0) * 0.2

func _refresh_nucleus_proxy(nucleus: Food) -> void:
	for child in nucleus.visual.get_children():
		child.queue_free()
	if _detail_tier < 3:
		return
	for kind in ["proton", "neutron"]:
		var transforms: Array[Transform3D] = []
		for nucleon in nucleus.parts:
			if is_instance_valid(nucleon) and nucleon.active and not nucleon.get_meta("collapsed", false) and nucleon.model_name == kind:
				transforms.append(Transform3D(Basis.IDENTITY, nucleon.position + Vector3.UP * NUCLEON_RADIUS))
		_add_nucleon_batch(nucleus.visual, transforms, kind)

func _add_nucleon_batch(parent: Node3D, transforms: Array[Transform3D], kind: String) -> void:
	if transforms.is_empty():
		return
	var sphere := SphereMesh.new()
	sphere.radius = NUCLEON_RADIUS
	sphere.height = NUCLEON_RADIUS * 2
	sphere.radial_segments = 8
	sphere.rings = 4
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = sphere
	batch.instance_count = transforms.size()
	for index in range(transforms.size()):
		batch.set_instance_transform(index, transforms[index])
	var node := MultiMeshInstance3D.new()
	node.multimesh = batch
	node.material_override = Art.material(Color.WHITE, 0, load("res://assets/models/" + kind + ".png"))
	parent.add_child(node)

func _molecule_replica(molecule: Food, scale_factor: float) -> Node3D:
	var projection := Node3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.65
	sphere.height = 1.3
	sphere.radial_segments = 8
	sphere.rings = 4
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	batch.mesh = sphere
	batch.instance_count = molecule.parts.size()
	for index in range(molecule.parts.size()):
		var atom: Food = molecule.parts[index]
		var count: int = atom.get_meta("protons")
		var basis := Basis.IDENTITY.scaled(Vector3.ONE * scale_factor * (0.6 if count == 1 else 1.0))
		batch.set_instance_transform(index, Transform3D(basis, atom.position * scale_factor))
		batch.set_instance_color(index, Color(COLORS[count]))
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = batch
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = load("res://assets/models/proton.png")
	visual.material_override = material
	projection.add_child(visual)
	for entry in _bonds:
		if entry.first.parent_food == molecule:
			Geometry.line(projection, PackedVector3Array([entry.first.position * scale_factor,
				entry.second.position * scale_factor]), Color("a7bbc3"))
	return projection

func _step_nucleus_formations() -> void:
	if world.current_tier > 1:
		return
	for entry in _clumps:
		var nucleon: Food = entry.food
		if not is_instance_valid(nucleon) or not nucleon.active:
			continue
		if not nucleon.parent_food.get_meta("formed", false):
			nucleon.position = entry.home * (1.0 + 2.5 * exp(-world._time * 0.12))

func _pack_nucleus(nucleus: Food) -> void:
	var index := 0
	for nucleon in nucleus.parts:
		if not is_instance_valid(nucleon) or not nucleon.active:
			continue
		var distance := sqrt(float(index)) * NUCLEON_RADIUS * 0.86
		var at := Vector2.from_angle(index * 2.39996) * distance
		nucleon.position = Vector3(at.x, (index % 3) * 0.035, at.y)
		index += 1

func _atom_changed(_part: Food, atom: Food) -> void:
	var electrons := 0
	var has_nucleus := false
	for part in atom.parts:
		if not is_instance_valid(part) or not part.active:
			continue
		if part.model_name == "":
			has_nucleus = true
		if part.model_name == "electron":
			electrons += 1
	atom.set_meta("electrons", electrons)
	if not has_nucleus:
		atom.title = "Electron cloud"

func _nursery_point(index: int) -> Vector2:
	var centers := [Vector2(-25, 17), Vector2(-12, 12), Vector2(-15, 29), Vector2(-33, 30)]
	var memberships := [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3]
	var cloud: int = memberships[index % memberships.size()]
	var offset := Vector2(world._rng.randfn(0, 2.5), world._rng.randfn(0, 1.4)).limit_length(4.5)
	return centers[cloud] + offset.rotated(cloud * 1.13)

func _add_drift(food: Food, amplitude: float, spin: float, tilt: float = 0.0) -> void:
	var home := food.position
	home.y += food.radius * tilt * 1.6
	_drifters.append({"food": food, "home": home, "phase": world._rng.randf_range(0, TAU),
		"amplitude": amplitude, "spin": spin * world._rng.randf_range(-1.0, 1.0),
		"tilt": tilt, "yaw": food.rotation.y})

func _step_drifters() -> void:
	var time := world._time
	var current := Vector3(sin(time * 0.11), 0, cos(time * 0.08) - 1.0) * 0.55
	for entry in _drifters:
		var food: Food = entry.food
		if not food.active:
			continue
		var phase: float = entry.phase
		var eddy := Vector3(sin(time * 0.17 + phase) - sin(phase), 0,
			cos(time * 0.13 + phase) - cos(phase)) * float(entry.amplitude)
		var angles := Vector3(sin(time * 0.09 + phase) * float(entry.tilt),
			float(entry.yaw) + time * float(entry.spin), cos(time * 0.07 + phase) * float(entry.tilt))
		food.transform = Transform3D(Basis.from_euler(angles).scaled(food.scale), entry.home + current + eddy)
