extends RefCounted

# One drop of sugar water. A gamma ray struck the drop's south-west side, and the goo starts on the
# vertex where it split. Particles fly out of the vertex, and atoms condense along the four tracks
# of the shower: forming atoms near the vertex, heavier bare nuclei and loose hydrogen farther out.
# The sucrose molecule, the milestone, floats across the drop inside its hydration shell, and
# the rest of the water holds itself together in hydrogen-bonded chains and rings, each molecule's
# hydrogens pointing at its neighbor's oxygen. More water diffuses in from the drop's rim toward
# the sucrose as the goo grows.

const Geometry = preload("res://src/levels/atomic_cosmic_geometry.gd")
const NUCLEON_RADIUS := 0.18
# A new atom's nucleons stand this many times farther apart than in a settled nucleus, so each
# one's quarks sit clear of its neighbors.
const LOOSE := 2.0
# Each food grows the goo by its visible volume times this density, so a meal's reward always
# matches the size the goo sees it swallow.
const GROWTH_DENSITY := 0.22
# A newly formed atom's electron cloud is still wide and thin, so it pays a tenth of a settled one.
const NEW_CLOUD_DENSITY := 0.022
const ELEMENTS := ["Nothing", "Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen"]
const COLORS := ["4b5366", "eef0df", "e8d0ab", "c1a3ba", "a1bfaa", "c8a381", "677582", "6087ae", "d87569"]
# [at, protons] for a water molecule's atoms: oxygen at the center, hydrogens toward local +z.
const WATER := [[Vector2.ZERO, 8], [Vector2(-2.25, 1.65), 1], [Vector2(2.25, 1.65), 1]]
const VERTEX := Vector2(-44.0, 30.0)
const SUCROSE := Vector2(36.0, -18.0)
# Where the nuclei tracks end and more nuclei fuse, and where loose hydrogen gathers between them.
const NORTH_TIP := Vector2(-24.3, 16.4)
const SOUTH_TIP := Vector2(-23.8, 42.4)
const WEST_TIP := Vector2(-58.6, 11.6)
# Stretches of the drop's rim where bulk water diffuses in: the north rim beside the sugar, and
# the south and west rims far from it and from each other.
const NORTH_RIM := [Vector2(20.0, -60.0), Vector2(60.0, -46.0)]
const SOUTH_RIM := [Vector2(-15.0, 58.0), Vector2(25.0, 58.0)]
const WEST_RIM := [Vector2(-76.0, -20.0), Vector2(-74.0, 8.0)]
# The shower's four tracks, drawn faintly: toward the sucrose, south-east, west, and a short stub.
const TRACKS := [
	[VERTEX, Vector2(-37.8, 25.9), Vector2(-31.2, 21.9), NORTH_TIP, Vector2(-19.5, 13.8)],
	[VERTEX, Vector2(-37.0, 33.0), Vector2(-30.4, 37.5), SOUTH_TIP, Vector2(-19.0, 44.2)],
	[VERTEX, Vector2(-47.9, 23.6), Vector2(-52.8, 17.4), WEST_TIP, Vector2(-62.8, 8.8)],
	[VERTEX, Vector2(-46.0, 32.9), Vector2(-48.4, 36.2), Vector2(-51.5, 38.1)],
]

# [kind, at, turn in degrees, size]
const PLACED := [
	# The milestone, across the drop from the vertex.
	["sucrose", SUCROSE, 20, 4.2],
	# Newly formed atoms along the tracks, nearest the vertex, where the goo starts among them.
	["new_hydrogen", Vector2(-41.1, 28.0), 0, 1.3],
	["new_helium", Vector2(-40.7, 31.2), 120, 1.3],
	["new_hydrogen", Vector2(-45.8, 27.0), 240, 1.3],
	["new_helium", Vector2(-46.0, 32.9), 20, 1.3],
	# Heavier bare nuclei farther along the tracks, and a hydrogen atom where the main track ends.
	["nucleus", NORTH_TIP, 90, 0.65],
	["nucleus", SOUTH_TIP, 210, 0.6],
	["nucleus", Vector2(-54.2, 15.6), 270, 0.45],
	["nucleus", WEST_TIP, 330, 0.53],
	["hydrogen", Vector2(-19.5, 13.8), 0, 0.8],
]

# Sugar and water molecules in the drops beyond this one: [at, turn in degrees, height, sucrose].
const BACKDROP := [
	[Vector2(-126, -22.5), 40, 0.8, true], [Vector2(-115.5, -49.5), 150, 1.8, false],
	[Vector2(-135, -39), 260, 2.8, false], [Vector2(-102, 85.5), 10, 0.8, true],
	[Vector2(-66, 102), 200, 1.8, false], [Vector2(-18, 111), 320, 2.8, false],
	[Vector2(61.5, 93), 100, 0.8, true], [Vector2(87, 106.5), 230, 1.8, false],
	[Vector2(118.5, 54), 70, 2.8, false], [Vector2(123, -42), 180, 0.8, true],
	[Vector2(84, -94.5), 290, 1.8, false], [Vector2(28.5, -106.5), 130, 2.8, false],
]

var world: GameWorld
var sucrose: Food
var drop: Node3D
var _orbits: Array[Dictionary] = []
var _gluons: Array[Dictionary] = []
var _bonds: Array[Dictionary] = []
var _background: Array[Node3D] = []
var _detail_tier := -1
var _nuclei: Array[Food] = []
var _drifters: Array[Dictionary] = []

func definition() -> Dictionary:
	return {"title": "Sugar Water", "meters_per_unit": 1e-15,
		"initial_radius": 0.16, "goal_radius": 3.85, "start_position": Vector3(VERTEX.x, 0, VERTEX.y),
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
	var tracks := Node3D.new()
	tracks.name = "The gamma ray's particle tracks"
	world.add_child(tracks)
	for track in TRACKS:
		var points := PackedVector3Array()
		for point: Vector2 in track:
			points.append(Vector3(point.x, 0.02, point.y))
		Geometry.line(tracks, points, Color("3d5a6e"))
	var reason := "Atoms condense along the tracks of the gamma ray's particle shower."
	var kinds := {
		"sucrose": {"label": "Sucrose molecule · C12H22O11", "tier": 4, "density": GROWTH_DENSITY, "whole": drop,
			"reason": "The dissolved sugar floats across the drop from the vertex.", "build": _build_sucrose},
		"new_hydrogen": {"label": "Hydrogen atom", "tier": 3, "density": NEW_CLOUD_DENSITY, "whole": drop,
			"reason": reason, "build": _new_atom.bind(1, 0)},
		"new_helium": {"label": "Helium atom", "tier": 3, "density": NEW_CLOUD_DENSITY, "whole": drop,
			"reason": reason, "build": _new_atom.bind(2, 2)},
		"nucleus": {"label": "Nucleus", "tier": 2, "density": 0.0, "whole": drop,
			"reason": "Nuclei settle at the ends of the shower's tracks.", "build": _bound_nucleus},
		"hydrogen": {"label": "Hydrogen atom", "tier": 3, "density": GROWTH_DENSITY, "whole": drop,
			"reason": reason, "build": _hydrogen},
	}
	world.place(PLACED, kinds)
	_build_background()
	_build_spawns()

func _growth(size: float) -> float:
	return GROWTH_DENSITY * pow(size, 3.0)

func _food(kind: String, at: Vector2, size: float, label: String, tier: int, parent: Food = null, lift: float = 0.0) -> Food:
	var food := world._add_food(kind, at, size, _growth(size), label, false, tier, parent, lift)
	food.rotation.y = 0.0
	return food

# Molecules and nuclei have no body of their own: their growth is the parts they hold, and they
# leave with their last visible part.
func _whole(at: Vector2, size: float, label: String, tier: int, parent: Food) -> Food:
	var food := world._add_food("", at, size, 0.0, label, false, tier, parent)
	food.rotation = Vector3.ZERO
	_bodiless(food)
	return food

func _bodiless(food: Food) -> void:
	food.height = 0.36
	food.collect_when_empty = true

# An atom's electron shell is a body: it grows the goo by its own size and stays edible after
# the goo takes its nucleus or electrons, like a board after its wheels.
func _shell(at: Vector2, size: float, label: String, parent: Food) -> Food:
	var atom := _whole(at, size, label, 3, parent)
	atom.volume = _growth(size)
	atom.collect_when_empty = false
	return atom

# The sugar is one solid milestone: a space-filling model of all 45 atoms, too big to eat until the
# Molecules view and a wall until then. Its atoms are not separate meals, so no goo can take the
# sugar apart before it has grown into it.
func _build_sucrose(molecule: Food) -> void:
	sucrose = molecule
	sucrose.milestone = true
	var atoms := _sucrose_atoms()
	var extent := 0.0
	for atom in atoms:
		extent = maxf(extent, atom[0].length())
	var hydrogen := 0.45
	sucrose.visual.add_child(_space_filling(atoms, (sucrose.radius - hydrogen) / extent, hydrogen, false))
	sucrose.height = 1.6
	sucrose.collider_radius = sucrose.radius
	sucrose.set_meta("formula", "C12H22O11")
	_add_drift(sucrose, 1.0, 0.012)

# [at, protons] for each of sucrose's atoms: a six-ring and a five-ring joined by one oxygen, with
# their hydroxyl groups and hydrogens.
func _sucrose_atoms() -> Array:
	var sites: Array[Vector2] = []
	for index in range(6):
		sites.append(Vector2(-6.6, 0) + Vector2.from_angle(index * TAU / 6) * 4.7)
	for index in range(5):
		sites.append(Vector2(6.6, 0) + Vector2.from_angle(PI + index * TAU / 5) * 4.3)
	sites.append_array([sites[2] + Vector2(-2.8, 3.7), sites[7] + Vector2(1, -4.5), sites[9] + Vector2(4.3, 0.5)])
	var atoms := []
	for index in range(14):
		atoms.append([sites[index], 8 if index in [5, 10] else 6])
	atoms.append([(sites[0] + sites[6]) * 0.5, 8])
	for index in [1, 3, 4, 8, 9, 11, 12, 13]:
		atoms.append([sites[index] + sites[index].normalized() * 2.4, 8])
	for index in range(15, 23):
		atoms.append([atoms[index][0] + atoms[index][0].normalized() * 1.75, 1])
	for index in [0, 1, 2, 3, 4, 7, 8, 9, 11, 11, 12, 12, 13, 13]:
		atoms.append([atoms[index][0] + Vector2.from_angle(atoms.size() * 2.39996) * 1.85, 1])
	return atoms

# One sphere per atom, carbon and oxygen larger than hydrogen. A batched copy draws the sugar in
# the drops beyond this one in three draw calls.
func _space_filling(atoms: Array, spacing: float, hydrogen: float, batched: bool) -> Node3D:
	var model := Node3D.new()
	for protons in [1, 6, 8]:
		var size := hydrogen if protons == 1 else hydrogen * 1.5
		var sphere := SphereMesh.new()
		sphere.radius = size
		sphere.height = size * 2.0
		var transforms: Array[Transform3D] = []
		for atom in atoms:
			if atom[1] == protons:
				transforms.append(Transform3D(Basis.IDENTITY, Vector3(atom[0].x * spacing, size, atom[0].y * spacing)))
		if batched:
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.mesh = sphere
			batch.instance_count = transforms.size()
			for index in range(transforms.size()):
				batch.set_instance_transform(index, transforms[index])
			var node := MultiMeshInstance3D.new()
			node.multimesh = batch
			node.material_override = Art.material(Color(COLORS[protons]))
			model.add_child(node)
			continue
		for transform in transforms:
			var ball := Art.mesh_node(sphere, Color(COLORS[protons]))
			model.add_child(ball)
			ball.transform = transform
	return model

func _bond(parent: Food, first: Food, second: Food) -> void:
	var visual := Geometry.bond(parent.visual, first.position + Vector3.UP * 0.17,
		second.position + Vector3.UP * 0.17, 0.055, Color("afbbbe"))
	_bonds.append({"visual": visual, "first": first, "second": second})

# A water molecule's atoms are seen whole: the goo takes a bound atom, never the nucleons inside it.
func _water(water: Food) -> void:
	_bodiless(water)
	water.set_meta("formula", "H2O")
	var oxygen := _light(water, WATER[0][0], 8, 8)
	for hydrogen in WATER.slice(1):
		_bond(water, oxygen, _light(water, hydrogen[0], 1, 0))

func _atom_radius(protons: int) -> float:
	return 0.8 if protons <= 2 else 1.45

func _light(parent: Food, at: Vector2, protons: int, neutrons: int) -> Food:
	var atom := _shell(at, _atom_radius(protons), ELEMENTS[protons] + " atom", parent)
	_light_atom(atom, protons, neutrons)
	return atom

func _fill_atom(atom: Food, protons: int, neutrons: int, spacing: float = 1.0) -> void:
	atom.set_meta("protons", protons)
	atom.set_meta("electrons", protons)
	var nucleus := _whole(Vector2.ZERO, _nucleus_reach(protons + neutrons, spacing), ELEMENTS[protons] + " nucleus", 2, atom)
	_fill_nucleus(nucleus, protons, neutrons, atom, spacing)
	_add_electrons(atom, protons, atom.radius)
	atom.part_consumed.connect(_atom_changed.bind(atom))

# The footprint is the packed nucleons it draws, so a hydrogen nucleus is as large as its one proton.
func _nucleus_reach(count: int, spacing: float = 1.0) -> float:
	return sqrt(float(count - 1)) * NUCLEON_RADIUS * 0.86 * spacing + NUCLEON_RADIUS

func _fill_nucleus(nucleus: Food, protons: int, neutrons: int, atom: Food = null, spacing: float = 1.0) -> void:
	nucleus.set_meta("protons", protons)
	nucleus.set_meta("neutrons", neutrons)
	nucleus.set_meta("spacing", spacing)
	_nuclei.append(nucleus)
	for index in range(protons + neutrons):
		var proton := index < protons
		var kind := "proton" if proton else "neutron"
		var nucleon := _food(kind, _packed(index, spacing), NUCLEON_RADIUS, kind.capitalize(), 1, nucleus, (index % 3) * 0.035)
		nucleon.set_meta("proton", proton)
	nucleus.part_consumed.connect(_nucleus_changed.bind(nucleus, atom))

func _packed(index: int, spacing: float = 1.0) -> Vector2:
	return Vector2.from_angle(index * 2.39996) * sqrt(float(index)) * NUCLEON_RADIUS * 0.86 * spacing

# A bare nucleus holds as many nucleons as fill its size, half of them protons.
func _nucleons_in(size: float) -> Vector2i:
	var count := clampi(floori(pow((size - NUCLEON_RADIUS) / (NUCLEON_RADIUS * 0.86), 2.0)) + 1, 2, 16)
	return Vector2i((count + 1) / 2, count / 2)

# A freshly fused nucleus is still loose: the goo can pick its nucleons off one by one.
func _nucleus_of_size(nucleus: Food) -> void:
	var nucleons := _nucleons_in(nucleus.radius)
	_bodiless(nucleus)
	nucleus.title = ELEMENTS[nucleons.x] + " nucleus"
	_fill_nucleus(nucleus, nucleons.x, nucleons.y)

# A nucleus that has settled at the end of its track is bound tight: one solid meal, and a wall to
# a goo smaller than itself.
func _bound_nucleus(nucleus: Food) -> void:
	var nucleons := _nucleons_in(nucleus.radius)
	nucleus.title = ELEMENTS[nucleons.x] + " nucleus"
	nucleus.volume = _growth(nucleus.radius)
	nucleus.collider_radius = nucleus.radius
	nucleus.height = NUCLEON_RADIUS * 2.0
	for index in range(nucleons.x + nucleons.y):
		var nucleon := Art.model("proton" if index < nucleons.x else "neutron", NUCLEON_RADIUS)
		nucleus.visual.add_child(nucleon)
		var at := _packed(index)
		nucleon.position = Vector3(at.x, (index % 3) * 0.035, at.y)

func _hydrogen(atom: Food) -> void:
	_fill_atom(atom, 1, 0)
	_add_drift(atom, 0.35, 0.035)

# A newly formed atom still shows the quarks inside each nucleon, for the smallest goo to pick out.
func _new_atom(atom: Food, protons: int, neutrons: int) -> void:
	_fill_atom(atom, protons, neutrons, LOOSE)
	_add_drift(atom, 0.35, 0.035)
	var nucleus: Food = atom.parts[0]
	for nucleon in nucleus.parts:
		_bind_quarks(nucleon, 3, _gluons.size())

func _add_electrons(atom: Food, count: int, atom_radius: float) -> void:
	var shells := _rings(atom, count, atom_radius)
	for shell in range(shells.size()):
		for index in range(shells[shell].y):
			var phase: float = TAU * index / shells[shell].y + shell * 0.4
			var electron := _food("electron", Vector2.from_angle(phase) * shells[shell].x,
				0.065, "Orbital electron", 0, atom, 0.1)
			_orbits.append({"food": electron, "radius": shells[shell].x, "phase": phase, "speed": 0.65 + shell * 0.2})

# Draws the atom's electron shells and returns each as (orbit radius, electrons).
func _rings(atom: Food, count: int, atom_radius: float) -> Array[Vector2]:
	var shells: Array[Vector2] = [Vector2(atom_radius * (0.58 if count > 2 else 1.0), mini(count, 2))]
	if count > 2:
		shells.append(Vector2(atom_radius, count - 2))
	for shell in shells:
		Geometry.ring(atom.visual, shell.x, Color("7793a1"), 0.15).name = "ElectronShellRing"
	return shells

func _nucleus_changed(part: Food, nucleus: Food, atom: Food) -> void:
	if part.get_meta("proton", false):
		nucleus.set_meta("protons", maxi(0, int(nucleus.get_meta("protons")) - 1))
	else:
		nucleus.set_meta("neutrons", maxi(0, int(nucleus.get_meta("neutrons")) - 1))
	var count: int = nucleus.get_meta("protons")
	nucleus.rename(ELEMENTS[count] + " nucleus", Color(COLORS[count]))
	_pack_nucleus(nucleus)
	_refresh_nucleus_proxy(nucleus)
	if count == 0:
		nucleus.rename("Neutron cluster", Color(COLORS[0]))
	if atom == null:
		return
	atom.rename(ELEMENTS[count] + " atom", Color(COLORS[count]))
	atom.set_meta("protons", count)
	if count == 0:
		atom.rename("Neutron remnant", Color(COLORS[0]))

# Quarks sit inside their nucleon's outline, so a nucleon draws no wider than its footprint.
func _bind_quarks(nucleon: Food, count: int, phase: int) -> void:
	nucleon.collect_when_empty = true
	for index in range(count):
		var at := Vector2.from_angle(TAU * index / count) * 0.1
		var quark := _food("quark", at, 0.075, "Bound quark", 0, nucleon)
		quark.rename("Bound quark", Color(["ed7169", "77bba0", "719ed6"][index % 3]))
	var gluon := _food("gluon", Vector2.ZERO, 0.06, "Binding gluon", 0, nucleon)
	_gluons.append({"food": gluon, "phase": float(phase)})
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

func _build_spawns() -> void:
	var soup := "Particles fly out of the vertex where the gamma ray split."
	_world_spawn("photon", "Gamma-ray photon", 0, soup, [VERTEX], Vector2(0.07, 0.13), Vector2i(0, 0), 0.4, 4, 14.0, _fly)
	_world_spawn("electron", "Free electron", 0, soup, [VERTEX], Vector2(0.09, 0.15), Vector2i(0, 0), 0.2, 2, 16.0, _curl.bind(1.0))
	_world_spawn("positron", "Positron", 0, soup, [VERTEX], Vector2(0.09, 0.15), Vector2i(0, 0), 0.2, 2, 16.0, _curl.bind(-1.0))
	_world_spawn("pion", "Pion", 1, soup, [VERTEX], Vector2(0.2, 0.28), Vector2i(0, 1), 0.07, 4, 30.0, _scatter)
	var fusing := "Nucleons fuse into nuclei at the ends of the shower's tracks and drift on."
	for tip in [NORTH_TIP, SOUTH_TIP, WEST_TIP]:
		_world_spawn("", "Nucleus", 2, fusing, [tip], Vector2(0.5, 0.78), Vector2i(1, 1), 0.085, 3, 45.0, _drift_on, _nucleus_of_size)
	for tip in [WEST_TIP, SOUTH_TIP]:
		_world_spawn("", "Hydrogen atom", 3, "A nucleus catches a stray electron at the end of its track.",
			[tip], Vector2(0.8, 0.9), Vector2i(2, 2), 0.24, 4, 60.0, _wander, _light_atom.bind(1, 0))
	var diffusing := "Bulk water diffuses in from the drop's rim toward the sugar."
	_world_spawn("", "Water molecule · H2O", 4, diffusing, NORTH_RIM, Vector2(3.7, 3.7), Vector2i(4, 4), 0.26, 4, 80.0, _diffuse, _water)
	for rim in [SOUTH_RIM, WEST_RIM]:
		_world_spawn("", "Water molecule · H2O", 4, diffusing, rim, Vector2(3.7, 3.7), Vector2i(3, 4), 0.065, 3, 80.0, _jostle, _water)

func _world_spawn(model: String, label: String, tier: int, reason: String, from: Array, sizes: Vector2,
		tiers: Vector2i, rate: float, limit: int, lifetime: float, move: Callable, composite: Callable = Callable()) -> void:
	var kind := {"model": model, "label": label, "tier": tier, "density": GROWTH_DENSITY if composite.is_null() else 0.0,
		"whole": drop, "reason": reason, "lift": 0.1 if model != "" else 0.0}
	if not composite.is_null():
		kind["build"] = composite
	world.spawn({"kind": kind, "from": from, "sizes": sizes, "tiers": tiers, "rate": rate,
		"limit": limit, "lifetime": lifetime, "move": move})

# An atom seen whole: its electron shells around a nucleus too fine to pick apart.
func _light_atom(atom: Food, protons: int, neutrons: int) -> void:
	atom.set_meta("protons", protons)
	atom.volume = _growth(atom.radius)
	atom.collect_when_empty = false
	_rings(atom, protons, atom.radius)
	for kind in ["proton", "neutron"]:
		var transforms: Array[Transform3D] = []
		for index in range(protons + neutrons):
			if (index < protons) == (kind == "proton"):
				var at := _packed(index)
				transforms.append(Transform3D(Basis.IDENTITY, Vector3(at.x, NUCLEON_RADIUS, at.y)))
		_add_nucleon_batch(atom.visual, transforms, kind)

# Photons leave the vertex in straight lines, each on its own heading.
func _fly(mover: Dictionary, delta: float) -> Vector2:
	return mover.at + Vector2.from_angle(mover.seed * TAU) * 1.2 * delta

# Charged particles curl in the drop, tighter as they slow; electrons and positrons curl opposite ways.
func _curl(mover: Dictionary, delta: float, handed: float) -> Vector2:
	var heading: float = mover.seed * TAU + handed * (mover.age * 0.7 + mover.age * mover.age * 0.04)
	return mover.at + Vector2.from_angle(heading) * 1.0 * delta

# Pions fly out fast and slow to a drift well out from the vertex, scattered all round it.
func _scatter(mover: Dictionary, delta: float) -> Vector2:
	var heading := Vector2.from_angle(mover.seed * TAU)
	return mover.at + heading * (3.6 * exp(-mover.age * 0.25) + 0.04) * delta

# New nuclei drift on along their track, away from the vertex, swaying.
func _drift_on(mover: Dictionary, delta: float) -> Vector2:
	var along: Vector2 = (mover.from - VERTEX).normalized().rotated(lerpf(-0.8, 0.8, mover.seed))
	return mover.at + (along + along.orthogonal() * sin(mover.age * 0.9) * 0.6) * 1.2 * delta

func _wander(mover: Dictionary, delta: float) -> Vector2:
	var phase: float = mover.seed * TAU
	return mover.at + Vector2(sin(mover.age * 0.6 + phase), cos(mover.age * 0.45 + phase * 3.0)) * 2.0 * delta

# Water diffuses toward the sugar and circles it as its hydration shell, each molecule in its own
# lane, jostled by its neighbors.
func _diffuse(mover: Dictionary, delta: float) -> Vector2:
	var offset: Vector2 = mover.at - SUCROSE
	var distance := offset.length()
	var lane := lerpf(10.5, 15.0, mover.seed)
	var along := Vector2(offset.y, -offset.x) / distance
	var inward := -offset / distance * clampf((distance - lane) * 0.15, -1.0, 1.0)
	var jostle := Vector2(sin(mover.age * 1.3 + mover.seed * 17.0), cos(mover.age * 1.1 + mover.seed * 5.0)) * 0.5
	return mover.at + (along * 0.6 + inward + jostle) * 2.4 * delta

# Far from the sugar, water only jostles, drifting slowly in toward the middle of the drop.
func _jostle(mover: Dictionary, delta: float) -> Vector2:
	var phase: float = mover.seed * TAU
	var wobble := Vector2(sin(mover.age * 0.5 + phase), cos(mover.age * 0.37 + phase * 2.0))
	return mover.at + (wobble - mover.from.normalized() * 0.35) * 1.6 * delta

func _build_background() -> void:
	for row in BACKDROP:
		var root := _space_filling(_sucrose_atoms() if row[3] else WATER, 0.35, 0.6, true)
		root.name = "BackgroundSucroseMolecule" if row[3] else "BackgroundWaterMolecule"
		world.add_child(root)
		root.position = Vector3(row[0].x, row[2], row[0].y)
		root.rotation.y = deg_to_rad(row[1])
		_background.append(root)

func step(delta: float) -> void:
	_step_drifters()
	_step_orbits(delta)
	for entry in _gluons:
		var gluon: Food = entry.food
		if gluon.active:
			gluon.position.x = sin((world._time + float(entry.phase)) * 3.0) * 0.06
	_step_bonds()
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
	for nucleus in _nuclei:
		if not is_instance_valid(nucleus) or not nucleus.active:
			continue
		_refresh_nucleus_proxy(nucleus)
		for nucleon in nucleus.parts:
			if is_instance_valid(nucleon):
				nucleon.visible = nucleon.active and not nucleon.detail_hidden and _detail_tier < 3

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

func _pack_nucleus(nucleus: Food) -> void:
	var index := 0
	for nucleon in nucleus.parts:
		if not is_instance_valid(nucleon) or not nucleon.active:
			continue
		var at := _packed(index, nucleus.get_meta("spacing"))
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

# Each drifting object sways on its own phase, taken from where it was placed.
func _add_drift(food: Food, amplitude: float, spin: float, tilt: float = 0.0) -> void:
	var home := food.position
	home.y += food.radius * tilt * 1.6
	var phase := fposmod(home.x * 0.37 + home.z * 0.73, TAU)
	_drifters.append({"food": food, "home": home, "phase": phase,
		"amplitude": amplitude, "spin": spin * sin(phase * 3.0), "tilt": tilt, "yaw": food.rotation.y})

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
