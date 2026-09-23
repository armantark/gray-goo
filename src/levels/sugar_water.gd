extends RefCounted

# One drop of sugar water. A gamma ray crossed the drop's west half from its north-west rim, and the
# goo starts on the vertex where it split. The shower's particles lie strewn along its four tracks,
# thickest at the bends, and more stream back in from beyond the view. Nuclei settle at the ends of
# the tracks and atoms condense past them, lightest nearest. Where the ray crossed the water it split
# molecules into hydrogen, hydroxyl, oxygen, and peroxide, in spurs along its path. Across the drop
# float the sugars: glucose and fructose pairs from the sucrose water has split, and four whole
# sucrose, the milestone among them. Water diffuses in from the rim: beside the sugar it circles as
# its hydration shell, far from it it only jostles.

const Geometry = preload("res://src/levels/atomic_cosmic_geometry.gd")
const NUCLEON_RADIUS := 0.18
# A new atom's nucleons stand this many times farther apart than in a settled nucleus, so each
# one's quarks sit clear of its neighbors.
const LOOSE := 2.0
# Sugars draw each atom as a sphere this far apart per unit of the sucrose layout, hydrogen this big.
const SUGAR_SPACING := 0.2
const SUGAR_HYDROGEN := 0.45
# The small molecules draw each atom at about its size in the Atoms view, from hydrogen this big.
const SMALL_HYDROGEN := 0.9
# Each food grows the goo by its visible volume times this density, so a meal's reward always
# matches the size the goo sees it swallow.
const GROWTH_DENSITY := 0.22
# A newly formed atom's electron cloud is still wide and thin, so it pays a tenth of a settled one.
const NEW_CLOUD_DENSITY := 0.022
const ELEMENTS := ["Nothing", "Hydrogen", "Helium", "Lithium", "Beryllium", "Boron", "Carbon", "Nitrogen", "Oxygen"]
const COLORS := ["4b5366", "eef0df", "e8d0ab", "c1a3ba", "a1bfaa", "c8a381", "677582", "6087ae", "d87569"]
# [at, protons] for a water molecule's atoms: oxygen at the center, hydrogens toward local +z.
const WATER := [[Vector2.ZERO, 8], [Vector2(-2.25, 1.65), 1], [Vector2(2.25, 1.65), 1]]
# The same for the small molecules, in world units around each molecule's center.
const H2 := [[Vector2(-0.45, 0.0), 1], [Vector2(0.45, 0.0), 1]]
const HYDROXYL := [[Vector2(-0.4, 0.0), 8], [Vector2(0.9, 0.0), 1]]
const WATER_MOLECULE := [[Vector2(0.0, -0.35), 8], [Vector2(-1.0, 0.55), 1], [Vector2(1.0, 0.55), 1]]
const O2 := [[Vector2(-0.75, 0.0), 8], [Vector2(0.75, 0.0), 8]]
const PEROXIDE := [[Vector2(-0.7, 0.0), 8], [Vector2(0.7, 0.0), 8], [Vector2(-1.35, 0.95), 1], [Vector2(1.35, -0.95), 1]]
const VERTEX := Vector2(-44.0, 30.0)
# Where the gamma ray entered the drop, at its north-west rim, on its way to the vertex.
const RAY_ENTRY := Vector2(-66.0, -49.0)
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
	# The milestone, across the drop from the vertex, three more whole sucrose, and the halves of the
	# sucrose that water has split. Each pair still drifts close together, except the first, whose
	# halves have drifted apart through the middle of the drop.
	["milestone", SUCROSE, 20, 4.2],
	["sucrose", Vector2(58.8, 21.4), 145, 4.2],
	["sucrose", Vector2(16.7, -58.3), 250, 4.2],
	["sucrose", Vector2(48.9, 47.6), 310, 4.2],
	["glucose", Vector2(-12.0, -22.0), 70, 2.56],
	["fructose", Vector2(10.0, 14.0), 200, 2.7],
	["glucose", Vector2(22.8, -29.1), 15, 2.56],
	["fructose", Vector2(27.4, -38.5), 160, 2.7],
	["glucose", Vector2(51.6, -30.2), 290, 2.56],
	["fructose", Vector2(60.9, -25.4), 35, 2.7],
	["glucose", Vector2(48.4, -4.1), 120, 2.56],
	["fructose", Vector2(55.2, 4.0), 305, 2.7],
	["glucose", Vector2(74.1, -4.8), 205, 2.56],
	["fructose", Vector2(77.3, 5.3), 80, 2.7],
	["glucose", Vector2(21.4, 24.7), 330, 2.56],
	["fructose", Vector2(31.7, 27.0), 190, 2.7],
	["glucose", Vector2(60.1, 34.3), 55, 2.56],
	["fructose", Vector2(70.3, 30.1), 240, 2.7],
	["glucose", Vector2(-3.9, -47.9), 100, 2.56],
	["fructose", Vector2(5.6, -52.4), 275, 2.7],
	["glucose", Vector2(27.2, 52.8), 175, 2.56],
	["fructose", Vector2(37.4, 56.0), 10, 2.7],
	["glucose", Vector2(-24.1, -49.9), 225, 2.56],
	["fructose", Vector2(-14.0, -55.4), 130, 2.7],
	["glucose", Vector2(29.4, 3.6), 260, 2.56],
	["fructose", Vector2(37.8, 9.9), 85, 2.7],
	["glucose", Vector2(64.3, -41.2), 320, 2.56],
	["fructose", Vector2(72.4, -34.6), 145, 2.7],
	# What the gamma ray split out of the water on its way in from the north-west rim, in spurs along
	# its path: peroxide and oxygen where it struck hardest, near the rim, hydroxyl and water around
	# them, and a few molecules that wandered off the path.
	["peroxide", Vector2(-64.5, -45.5), 40, 2.55],
	["hydroxyl", Vector2(-57.2, -42.1), 300, 1.8],
	["h2", Vector2(-63.8, -37.0), 160, 1.35],
	["water", Vector2(-71.9, -35.2), 295, 2.04],
	["peroxide", Vector2(-60.4, -27.9), 115, 2.55],
	["o2", Vector2(-52.2, -24.6), 65, 2.1],
	["water", Vector2(-59.6, -18.9), 345, 2.04],
	["hydroxyl", Vector2(-66.9, -22.0), 95, 1.8],
	["water", Vector2(-55.3, -10.4), 230, 2.04],
	["hydroxyl", Vector2(-48.2, -7.1), 20, 1.8],
	["h2", Vector2(-58.6, -3.6), 285, 1.35],
	["o2", Vector2(-49.3, -16.2), 150, 2.1],
	["water", Vector2(-51.4, 3.2), 140, 2.04],
	["hydroxyl", Vector2(-44.6, 7.4), 185, 1.8],
	["h2", Vector2(-54.1, 9.4), 30, 1.35],
	["o2", Vector2(-35.6, -24.0), 5, 2.1],
	["water", Vector2(-26.3, -41.2), 75, 2.04],
	["h2", Vector2(-30.4, -5.1), 110, 1.35],
	# Atoms condensed in plumes past the ends of the three long tracks, lightest nearest: the north
	# plume fans out toward the middle of the drop, the south one along the rim, the west one short.
	["lithium", Vector2(-11.8, 3.1), 0, 1.1],
	["beryllium", Vector2(-7.3, 5.8), 0, 1.2],
	["boron", Vector2(-1.9, -6.4), 0, 1.3],
	["carbon", Vector2(2.6, -3.1), 0, 1.4],
	["nitrogen", Vector2(7.4, -16.9), 0, 1.42],
	["oxygen", Vector2(11.8, -12.4), 0, 1.45],
	["carbon", Vector2(15.3, -21.6), 0, 1.4],
	["helium", Vector2(-14.6, 55.0), 0, 0.85],
	["lithium", Vector2(-7.9, 53.6), 0, 1.1],
	["beryllium", Vector2(-1.8, 48.3), 0, 1.2],
	["boron", Vector2(4.1, 53.9), 0, 1.3],
	["carbon", Vector2(9.3, 46.1), 0, 1.4],
	["oxygen", Vector2(15.8, 51.2), 0, 1.45],
	["lithium", Vector2(-70.8, -1.4), 0, 1.1],
	["beryllium", Vector2(-75.6, -8.3), 0, 1.2],
	["boron", Vector2(-78.2, -15.5), 0, 1.3],
	["oxygen", Vector2(-81.1, -21.9), 0, 1.45],
	# Hydrogen atoms loose between the track ends, where a nucleus caught a stray electron.
	["hydrogen", Vector2(-33.6, 8.9), 0, 0.8],
	["hydrogen", Vector2(-9.4, 36.8), 0, 0.8],
	["hydrogen", Vector2(-70.1, 19.6), 0, 0.8],
	["hydrogen", Vector2(-45.9, 52.7), 0, 0.8],
	["hydrogen", Vector2(-5.8, 19.2), 0, 0.8],
	# Bound nuclei settled at the ends of the tracks, heaped at the three long ones, a few that
	# rolled on past them, and the lightest, which settled early between the tracks.
	["nucleus", Vector2(-29.2, 28.6), 60, 0.47],
	["nucleus", Vector2(-41.8, 16.9), 250, 0.49],
	["nucleus", Vector2(-56.9, 27.4), 130, 0.46],
	["nucleus", Vector2(-36.8, 46.3), 10, 0.5],
	["nucleus", Vector2(-32.8, 14.1), 290, 0.48],
	["nucleus", Vector2(-60.2, 36.3), 175, 0.47],
	["nucleus", NORTH_TIP, 90, 0.66],
	["nucleus", Vector2(-21.6, 18.9), 200, 0.52],
	["nucleus", Vector2(-26.8, 13.1), 310, 0.58],
	["nucleus", Vector2(-19.5, 13.8), 45, 0.48],
	["nucleus", Vector2(-17.2, 16.7), 160, 0.72],
	["nucleus", SOUTH_TIP, 210, 0.6],
	["nucleus", Vector2(-20.4, 40.3), 20, 0.5],
	["nucleus", Vector2(-19.0, 44.2), 280, 0.55],
	["nucleus", Vector2(-26.1, 46.3), 135, 0.7],
	["nucleus", Vector2(-16.6, 47.9), 240, 0.64],
	["nucleus", WEST_TIP, 330, 0.53],
	["nucleus", Vector2(-54.2, 15.6), 270, 0.46],
	["nucleus", Vector2(-62.8, 8.8), 100, 0.62],
	["nucleus", Vector2(-61.3, 14.9), 190, 0.74],
	["nucleus", Vector2(-56.9, 7.4), 15, 0.57],
	["nucleus", Vector2(-12.3, 10.2), 60, 0.68],
	["nucleus", Vector2(-11.8, 49.5), 170, 0.76],
	["nucleus", Vector2(-67.4, 4.1), 225, 0.7],
	["nucleus", Vector2(-30.8, 52.6), 300, 0.6],
	["nucleus", Vector2(-66.2, 33.8), 75, 0.64],
	["nucleus", Vector2(-14.5, 29.7), 250, 0.5],
	["nucleus", Vector2(-40.2, 55.1), 120, 0.68],
	["nucleus", Vector2(-15.9, 8.1), 205, 0.53],
	["nucleus", Vector2(-21.9, 7.4), 340, 0.5],
	["nucleus", Vector2(-60.9, 1.9), 95, 0.5],
	["nucleus", Vector2(-39.9, 45.8), 30, 0.36],
	["nucleus", Vector2(-61.4, 22.9), 285, 0.42],
	# Newly formed atoms at the vertex, where the goo starts among them.
	["new_hydrogen", Vector2(-41.1, 28.0), 0, 1.3],
	["new_helium", Vector2(-40.7, 31.2), 120, 1.3],
	["new_hydrogen", Vector2(-45.8, 27.0), 240, 1.3],
	["new_helium", Vector2(-46.0, 32.9), 20, 1.3],
	# Nucleons knocked free, in twos and threes at the bends of the tracks and alone between them.
	["proton", Vector2(-36.4, 25.4), 10, 0.18],
	["neutron", Vector2(-35.8, 24.7), 130, 0.18],
	["proton", Vector2(-37.1, 24.3), 250, 0.18],
	["neutron", Vector2(-30.4, 21.3), 40, 0.18],
	["proton", Vector2(-29.3, 20.5), 170, 0.18],
	["neutron", Vector2(-24.3, 17.2), 300, 0.18],
	["proton", Vector2(-35.7, 35.3), 80, 0.18],
	["neutron", Vector2(-34.6, 34.5), 200, 0.18],
	["neutron", Vector2(-35.1, 33.9), 320, 0.18],
	["proton", Vector2(-36.2, 34.1), 60, 0.18],
	["proton", Vector2(-29.2, 39.5), 190, 0.18],
	["neutron", Vector2(-28.4, 38.8), 280, 0.18],
	["neutron", Vector2(-50.1, 22.0), 15, 0.18],
	["proton", Vector2(-49.1, 21.2), 145, 0.18],
	["neutron", Vector2(-49.5, 20.5), 265, 0.18],
	["proton", Vector2(-55.9, 17.3), 105, 0.18],
	["neutron", Vector2(-55.4, 16.2), 225, 0.18],
	["proton", Vector2(-48.7, 36.1), 35, 0.18],
	["neutron", Vector2(-49.5, 36.9), 155, 0.18],
	["proton", Vector2(-48.2, 37.1), 275, 0.18],
	["neutron", Vector2(-42.0, 33.5), 50, 0.18],
	["proton", Vector2(-39.9, 23.4), 170, 0.18],
	["neutron", Vector2(-45.4, 25.3), 290, 0.18],
	["proton", Vector2(-32.9, 29.6), 110, 0.18],
	["neutron", Vector2(-52.5, 30.2), 230, 0.18],
	["proton", Vector2(-37.8, 41.5), 350, 0.18],
	["neutron", Vector2(-44.1, 40.1), 90, 0.18],
	["proton", Vector2(-26.8, 30.7), 210, 0.18],
	["proton", Vector2(-57.4, 24.7), 330, 0.18],
	["neutron", Vector2(-28.1, 24.8), 70, 0.18],
	# Pions scattered all round the vertex, farthest out of the shower's particles.
	["pion", Vector2(-31.9, 32.9), 25, 0.26],
	["pion", Vector2(-39.0, 18.5), 140, 0.3],
	["pion", Vector2(-54.6, 33.2), 260, 0.22],
	["pion", Vector2(-25.5, 26.5), 120, 0.28],
	["pion", Vector2(-58.7, 19.0), 235, 0.25],
	["pion", Vector2(-34.3, 43.4), 350, 0.36],
	["pion", Vector2(-42.5, 15.9), 95, 0.31],
	["pion", Vector2(-51.6, 43.2), 215, 0.27],
	["pion", Vector2(-24.0, 35.8), 330, 0.34],
	["pion", Vector2(-60.8, 29.6), 75, 0.29],
	["pion", Vector2(-37.6, 13.4), 190, 0.24],
	["pion", Vector2(-29.7, 45.2), 310, 0.32],
	["pion", Vector2(-56.7, 39.5), 50, 0.3],
	["pion", Vector2(-21.4, 22.2), 285, 0.28],
	["pion", Vector2(-47.9, 44.2), 20, 0.3],
	["pion", Vector2(-34.9, 38.2), 235, 0.28],
	["pion", Vector2(-49.3, 13.8), 140, 0.32],
	# Photons and charged particles close to the vertex: photons flew straight into the gaps between
	# the tracks, electrons and positrons curled off beside them.
	["photon", Vector2(-40.9, 24.9), 320, 0.1],
	["photon", Vector2(-37.0, 29.2), 355, 0.12],
	["photon", Vector2(-49.2, 28.6), 175, 0.09],
	["photon", Vector2(-42.8, 37.1), 95, 0.11],
	["photon", Vector2(-34.9, 30.9), 10, 0.08],
	["photon", Vector2(-53.2, 26.1), 160, 0.13],
	["photon", Vector2(-45.2, 21.2), 265, 0.1],
	["photon", Vector2(-39.3, 38.6), 60, 0.09],
	["photon", Vector2(-30.9, 28.0), 345, 0.12],
	["photon", Vector2(-50.4, 33.1), 200, 0.1],
	["photon", Vector2(-46.9, 41.2), 110, 0.11],
	["photon", Vector2(-36.3, 20.0), 300, 0.13],
	["electron", Vector2(-42.3, 26.8), 0, 0.1],
	["electron", Vector2(-39.8, 27.5), 0, 0.12],
	["electron", Vector2(-35.5, 24.4), 0, 0.09],
	["electron", Vector2(-33.9, 21.4), 0, 0.14],
	["electron", Vector2(-38.8, 34.6), 0, 0.11],
	["electron", Vector2(-34.5, 36.1), 0, 0.08],
	["electron", Vector2(-48.9, 22.4), 0, 0.12],
	["electron", Vector2(-54.7, 16.3), 0, 0.1],
	["positron", Vector2(-44.8, 34.1), 0, 0.1],
	["positron", Vector2(-47.0, 36.7), 0, 0.13],
	["positron", Vector2(-49.9, 38.9), 0, 0.09],
	["positron", Vector2(-29.5, 38.3), 0, 0.12],
	["positron", Vector2(-56.1, 20.4), 0, 0.11],
	["positron", Vector2(-31.5, 25.4), 0, 0.1],
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
var drop: Node3D
var _orbits: Array[Dictionary] = []
var _gluons: Array[Dictionary] = []
var _background: Array[Node3D] = []
var _detail_tier := -1
var _nuclei: Array[Food] = []
var _bound: Array[Food] = []
var _drifters: Array[Dictionary] = []

func definition() -> Dictionary:
	return {"title": "Sugar Water", "meters_per_unit": 1e-15,
		"initial_radius": 0.16, "goal_radius": 3.85, "start_position": Vector3(VERTEX.x, 0, VERTEX.y),
		"accent": Color("f1c78a"), "field": Rect2(-96, -75, 192, 150),
		"tiers": ["Particle soup", "Formations", "Small nuclei", "Atoms", "Molecules"],
		# The Molecules view opens before glucose is edible, so the sugars feed it and not the Atoms view.
		"jumps": [{"radius": 0.16, "view_size": 5.0}, {"radius": 0.38, "view_size": 12.0},
			{"radius": 0.85, "view_size": 20.0}, {"radius": 1.5, "view_size": 30.0, "meters_per_unit": 1e-11},
			{"radius": 2.1, "view_size": 42.0, "meters_per_unit": 1e-10}],
		"growth_scale": 0.215,
		"background_color": Color("0b1622"), "ground_color": Color("263644"),
		"key_color": Color("e4ebe8"), "fill_color": Color("8da4bb"),
		"ground_texture": "res://assets/models/ground_particle.png",
		"simple": {"proton": "", "neutron": "", "electron": "", "positron": "", "pion": ""}}

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
	Geometry.line(tracks, PackedVector3Array([Vector3(RAY_ENTRY.x, 0.02, RAY_ENTRY.y), Vector3(VERTEX.x, 0.02, VERTEX.y)]),
		Color("4b6c80"))
	for track in TRACKS:
		var points := PackedVector3Array()
		for point: Vector2 in track:
			points.append(Vector3(point.x, 0.02, point.y))
		Geometry.line(tracks, points, Color("3d5a6e"))
	var shower := "The gamma ray's shower strewed its particles along the tracks."
	var reason := "Atoms condense past the ends of the shower's tracks, lightest nearest."
	var split := "The gamma ray split the water it crossed into small molecules."
	var halves := "Water split this sucrose, and its glucose and fructose drift apart."
	var kinds := {
		"milestone": _molecule("Sucrose molecule · C12H22O11", 4, "The dissolved sugar floats across the drop from the vertex.",
			_build_sucrose),
		"sucrose": _molecule("Sucrose molecule · C12H22O11", 4, "Four sucrose molecules are still whole.",
			_floating.bind(_sucrose_atoms(), SUGAR_SPACING, SUGAR_HYDROGEN)),
		"glucose": _molecule("Glucose molecule · C6H12O6", 4, halves, _floating.bind(_sugar_half(true), SUGAR_SPACING, SUGAR_HYDROGEN)),
		"fructose": _molecule("Fructose molecule · C6H12O6", 4, halves, _floating.bind(_sugar_half(false), SUGAR_SPACING, SUGAR_HYDROGEN)),
		"h2": _molecule("Hydrogen molecule · H2", 3, split, _floating.bind(H2, 1.0, SMALL_HYDROGEN)),
		"hydroxyl": _molecule("Hydroxyl radical · OH", 3, split, _floating.bind(HYDROXYL, 1.0, SMALL_HYDROGEN)),
		"water": _molecule("Water molecule · H2O", 3, split, _floating.bind(WATER_MOLECULE, 1.0, SMALL_HYDROGEN)),
		"o2": _molecule("Oxygen molecule · O2", 3, split, _floating.bind(O2, 1.0, SMALL_HYDROGEN)),
		"peroxide": _molecule("Hydrogen peroxide · H2O2", 3, split, _floating.bind(PEROXIDE, 1.0, SMALL_HYDROGEN)),
		"new_hydrogen": {"label": "Hydrogen atom", "tier": 3, "density": NEW_CLOUD_DENSITY, "whole": drop,
			"reason": shower, "build": _new_atom.bind(1, 0)},
		"new_helium": {"label": "Helium atom", "tier": 3, "density": NEW_CLOUD_DENSITY, "whole": drop,
			"reason": shower, "build": _new_atom.bind(2, 2)},
		"nucleus": {"label": "Nucleus", "tier": 2, "density": 0.0, "whole": drop,
			"reason": "Nuclei settle at the ends of the shower's tracks.", "build": _bound_nucleus},
		"hydrogen": {"label": "Hydrogen atom", "tier": 3, "density": GROWTH_DENSITY, "whole": drop,
			"reason": reason, "build": _hydrogen},
		"photon": _particle("photon", "Gamma-ray photon", 0, shower),
		"electron": _particle("electron", "Free electron", 0, shower),
		"positron": _particle("positron", "Positron", 0, shower),
		"proton": _particle("proton", "Free proton", 1, shower),
		"neutron": _particle("neutron", "Free neutron", 1, shower),
		"pion": _particle("pion", "Pion", 1, shower),
	}
	for element in [[2, 2], [3, 4], [4, 5], [5, 6], [6, 6], [7, 7], [8, 8]]:
		kinds[ELEMENTS[element[0]].to_lower()] = {"label": ELEMENTS[element[0]] + " atom", "tier": 3, "density": 0.0,
			"whole": drop, "reason": reason, "build": _settled_atom.bind(element[0], element[1])}
	world.place(PLACED, kinds)
	_build_background()
	_build_spawns()

func _growth(size: float) -> float:
	return GROWTH_DENSITY * pow(size, 3.0)

func _particle(model: String, label: String, tier: int, reason: String) -> Dictionary:
	return {"model": model, "label": label, "tier": tier, "density": GROWTH_DENSITY, "whole": drop, "reason": reason, "lift": 0.1}

func _molecule(label: String, tier: int, reason: String, build: Callable) -> Dictionary:
	return {"label": label, "tier": tier, "density": GROWTH_DENSITY, "whole": drop, "reason": reason, "build": build}

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

# Each molecule is one solid object: a space-filling model of all its atoms, a wall to any goo
# smaller than itself and then one meal. Its atoms are not separate meals, so no goo can take it
# apart before it has grown into it. Every sugar draws its atoms at the same spacing and size, and
# every small molecule at the size of its atoms in the Atoms view.
func _solid(molecule: Food, atoms: Array, spacing: float, hydrogen: float) -> void:
	molecule.visual.add_child(_space_filling(atoms, spacing, hydrogen, false))
	# The meal's color is its atoms' colors weighted by the volume each sphere draws.
	var mix := Vector3.ZERO
	var total := 0.0
	for atom in atoms:
		var weight := 1.0 if atom[1] == 1 else 3.375
		var color := Color(COLORS[atom[1]])
		mix += Vector3(color.r, color.g, color.b) * weight
		total += weight
	mix /= total
	molecule.pigment = Color(mix.x, mix.y, mix.z)
	molecule.volume = _growth(molecule.radius)
	molecule.height = maxf(1.6, hydrogen * 3.0)
	molecule.collider_radius = molecule.radius

# A placed molecule floats in the drop's slow current, a spawned one follows its own path. Each
# sways only a little around its place, so two walls placed a goo's width apart stay that far apart.
func _floating(molecule: Food, atoms: Array, spacing: float, hydrogen: float) -> void:
	_solid(molecule, atoms, spacing, hydrogen)
	_add_drift(molecule, 0.15 if spacing == SUGAR_SPACING else 0.1, 0.012)

func _build_sucrose(molecule: Food) -> void:
	molecule.milestone = true
	_floating(molecule, _sucrose_atoms(), SUGAR_SPACING, SUGAR_HYDROGEN)

# Water splits sucrose at its bridging oxygen: the glucose keeps that oxygen and caps it with a
# hydrogen, and the fructose gains a hydroxyl where the bridge was. Each half centres on itself.
func _sugar_half(glucose: bool) -> Array:
	var whole := _sucrose_atoms()
	var bridge: Vector2 = whole[14][0]
	var atoms := whole.filter(func(atom: Array) -> bool: return (atom[0].x < 0.5) == glucose)
	if glucose:
		atoms.append([bridge + Vector2(1.75, 0.0), 1])
	else:
		atoms.append_array([[bridge - Vector2(0.3, 0.0), 8], [bridge - Vector2(2.05, 0.0), 1]])
	var center := Vector2.ZERO
	for atom in atoms:
		center += atom[0] / atoms.size()
	return atoms.map(func(atom: Array) -> Array: return [atom[0] - center, atom[1]])

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

# A nucleus that has settled at the end of its track is bound tight: one solid meal, and a wall to
# a goo smaller than itself.
func _bound_nucleus(nucleus: Food) -> void:
	var nucleons := _nucleons_in(nucleus.radius)
	nucleus.title = ELEMENTS[nucleons.x] + " nucleus"
	nucleus.pigment = Art.food_color("proton").lerp(Art.food_color("neutron"), float(nucleons.y) / (nucleons.x + nucleons.y))
	nucleus.volume = _growth(nucleus.radius)
	nucleus.collider_radius = nucleus.radius
	nucleus.height = NUCLEON_RADIUS * 2.0
	nucleus.set_meta("protons", nucleons.x)
	nucleus.set_meta("neutrons", nucleons.y)
	_bound.append(nucleus)
	_draw_bound(nucleus)

# A settled nucleus draws each nucleon's quarks while the goo is small enough to see them, and one
# batch of plain spheres once nucleons are specks.
func _draw_bound(nucleus: Food) -> void:
	for child in nucleus.visual.get_children():
		child.free()
	var protons: int = nucleus.get_meta("protons")
	var count: int = protons + nucleus.get_meta("neutrons")
	if world.is_simple(NUCLEON_RADIUS):
		for kind in ["proton", "neutron"]:
			var transforms: Array[Transform3D] = []
			for index in range(count):
				if (index < protons) == (kind == "proton"):
					var at := _packed(index)
					transforms.append(Transform3D(Basis.IDENTITY, Vector3(at.x, NUCLEON_RADIUS + (index % 3) * 0.035, at.y)))
			_add_nucleon_batch(nucleus.visual, transforms, kind)
	else:
		for index in range(count):
			var nucleon := Art.model("proton" if index < protons else "neutron", NUCLEON_RADIUS)
			nucleus.visual.add_child(nucleon)
			var at := _packed(index)
			nucleon.position = Vector3(at.x, (index % 3) * 0.035, at.y)
	nucleus.refresh_highlight()

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

# Ten spawn points keep the goo fed between placed meals. Every mover starts outside the view and
# drifts in: the shower's particles stream back across the vertex, fused nuclei leave two track
# ends, atoms and water diffuse in from the rim.
func _build_spawns() -> void:
	var shower := "Particles from the gamma ray's shower stream back across the drop."
	_world_spawn("photon", "Gamma-ray photon", 0, shower, [Vector2(-72.0, 28.0), Vector2(-60.0, 40.0)], Vector2(0.08, 0.13),
		Vector2i(0, 0), 0.7, 8, 30.0, _cross.bind(0.9))
	_world_spawn("electron", "Free electron", 0, shower, [Vector2(-29.0, 7.0), Vector2(-15.0, 24.0)], Vector2(0.08, 0.14),
		Vector2i(0, 0), 0.4, 5, 35.0, _curl.bind(1.0))
	_world_spawn("positron", "Positron", 0, shower, [Vector2(-38.0, 48.0), Vector2(-22.0, 47.0)], Vector2(0.08, 0.14),
		Vector2i(0, 0), 0.3, 4, 35.0, _curl.bind(-1.0))
	_world_spawn("pion", "Pion", 1, shower, [Vector2(-65.0, 5.0), Vector2(-46.0, -1.0)], Vector2(0.22, 0.32),
		Vector2i(0, 1), 0.5, 7, 45.0, _cross.bind(0.8))
	_world_spawn("neutron", "Free neutron", 1, shower, [Vector2(-13.0, 29.0), Vector2(-9.0, 45.0)], Vector2(0.18, 0.18),
		Vector2i(0, 0), 0.35, 5, 45.0, _cross.bind(0.7))
	var fusing := "Nucleons fuse into nuclei at the ends of the shower's tracks and drift on."
	for tip in [NORTH_TIP, WEST_TIP]:
		_world_spawn("", "Nucleus", 2, fusing, [tip], Vector2(0.45, 0.55), Vector2i(1, 2), 0.2, 4, 60.0, _drift_on, _bound_nucleus)
	var condensing := "Atoms condensed in the shower drift in across the drop."
	_world_spawn("", "Hydrogen atom", 3, condensing, WEST_RIM, Vector2(0.8, 0.9), Vector2i(2, 3), 0.4, 7, 70.0,
		_cross.bind(2.2), _light_atom.bind(1, 0))
	_world_spawn("", "Oxygen atom", 3, condensing, [Vector2(-42.0, -60.0), Vector2(-6.0, -64.0)], Vector2(1.4, 1.45), Vector2i(2, 3),
		0.2, 5, 70.0, _cross.bind(2.6), _light_atom.bind(8, 8))
	var diffusing := "Bulk water diffuses in from the drop's rim toward the sugar."
	_world_spawn("", "Water molecule · H2O", 3, diffusing, NORTH_RIM, Vector2(2.04, 2.04), Vector2i(3, 4), 0.45, 8, 80.0,
		_diffuse, _solid.bind(WATER_MOLECULE, 1.0, SMALL_HYDROGEN))
	_world_spawn("", "Water molecule · H2O", 3, diffusing, SOUTH_RIM, Vector2(2.04, 2.04), Vector2i(3, 4), 0.3, 6, 80.0,
		_jostle, _solid.bind(WATER_MOLECULE, 1.0, SMALL_HYDROGEN))

func _world_spawn(model: String, label: String, tier: int, reason: String, from: Array, sizes: Vector2,
		tiers: Vector2i, rate: float, limit: int, lifetime: float, move: Callable, composite: Callable = Callable()) -> void:
	var kind := {"model": model, "label": label, "tier": tier, "density": GROWTH_DENSITY if composite.is_null() else 0.0,
		"whole": drop, "reason": reason, "lift": 0.1 if model != "" else 0.0}
	if not composite.is_null():
		kind["build"] = composite
	world.spawn({"kind": kind, "from": from, "sizes": sizes, "tiers": tiers, "rate": rate,
		"limit": limit, "lifetime": lifetime, "move": move})

func _settled_atom(atom: Food, protons: int, neutrons: int) -> void:
	_light_atom(atom, protons, neutrons)
	_add_drift(atom, 0.6, 0.02)

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

# Streams in across the view it was released outside of, each mover on its own heading within a
# cone, so they cross the view spread out.
func _cross(mover: Dictionary, delta: float, speed: float) -> Vector2:
	var heading: Vector2 = (mover.toward - mover.from).normalized().rotated(lerpf(-0.45, 0.45, mover.seed))
	return mover.at + heading * speed * delta

# Charged particles set off into the view and curl in the drop; electrons and positrons curl
# opposite ways.
func _curl(mover: Dictionary, delta: float, handed: float) -> Vector2:
	var heading: float = (mover.toward - mover.from).angle() + lerpf(-0.4, 0.4, mover.seed) + handed * mover.age * 0.11
	return mover.at + Vector2.from_angle(heading) * 0.8 * delta

# New nuclei drift on along their track, away from the vertex, swaying.
func _drift_on(mover: Dictionary, delta: float) -> Vector2:
	var along: Vector2 = (mover.from - VERTEX).normalized().rotated(lerpf(-0.8, 0.8, mover.seed))
	return mover.at + (along + along.orthogonal() * sin(mover.age * 0.9) * 0.6) * 1.2 * delta

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


func _update_detail() -> void:
	if _detail_tier == world.current_tier:
		return
	_detail_tier = world.current_tier
	for food in world.foods:
		if food.detail_hidden:
			food.visual.hide()
	for index in range(_bound.size() - 1, -1, -1):
		if _bound[index].active:
			_draw_bound(_bound[index])
		else:
			_bound.remove_at(index)
	for index in range(_nuclei.size() - 1, -1, -1):
		var nucleus := _nuclei[index]
		if not nucleus.active:
			_nuclei.remove_at(index)
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
	nucleus.refresh_highlight()

# Nucleons drawn together are specks, so each is a plain sphere in its color, as simple nucleons draw.
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
	node.material_override = Art.material(Art.food_color(kind))
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
