extends RefCounted

# One stretch of the cosmic web. Four filaments meet at the great node north-east of center, where
# the Filament supercluster sits; three smaller nodes hold galaxy clusters, and thinner filaments run
# on from them to the edges. Galaxy groups and field galaxies sit along the filaments and the voids
# between them stay empty; far out along the filaments, groups too distant to pick out their
# galaxies glow as single clouds. The goo starts on an arm of the home galaxy in the Local group, on
# the long filament that runs from the west cluster to the great node. Dwarf galaxies and star-forming
# nebulae crowd around the Local group, and tides have torn streams of stars out of its galaxies.
# Runaway stars flung out of its galaxies cross its filament, gas falls in along the filament,
# and galaxies and groups stream in from past the level's edge along the filaments toward the nodes.
const NODE := Vector2(40.0, -20.0)
const WEST := Vector2(-95.0, 35.0)
const SOUTH_EAST := Vector2(115.0, 70.0)
const NORTH := Vector2(-30.0, -95.0)
const NODES := [NODE, WEST, SOUTH_EAST, NORTH]
const LOCAL := Vector2(-45.0, 15.0)
# Stretches of filament where small spawns set out: the long filament through the Local group, the
# spur from the west cluster to the north one, and the two filaments east from the great node.
const FEEDERS := [[Vector2(-80, 29), Vector2(14, -8)], [Vector2(-95, 35), Vector2(-72, -52)],
	[Vector2(40, -20), Vector2(128, -42)], [Vector2(40, -20), Vector2(84, 42)]]
# The home galaxy's center: the Local group's first entry, which is not turned.
const HOME := LOCAL + Vector2(-0.43, 0.09) * 7.0

# Filaments, [width, points]. The four at the great node leave along the arms of its knot.
const FILAMENTS := [
	[9.0, [NODE, Vector2(14, -8), Vector2(-12, 4), LOCAL, Vector2(-72, 26), WEST]],
	[8.0, [NODE, Vector2(30, -44), Vector2(8, -70), NORTH]],
	[8.0, [NODE, Vector2(55, 12), Vector2(84, 42), SOUTH_EAST]],
	[8.0, [NODE, Vector2(82, -38), Vector2(128, -42), Vector2(200, -66)]],
	[6.0, [WEST, Vector2(-132, 30), Vector2(-200, 46)]],
	[6.0, [WEST, Vector2(-98, 72), Vector2(-118, 155)]],
	[6.0, [NORTH, Vector2(-88, -108), Vector2(-200, -117)]],
	[5.0, [NORTH, Vector2(-8, -116), Vector2(18, -155)]],
	[6.0, [SOUTH_EAST, Vector2(104, 104), Vector2(94, 155)]],
	[5.0, [SOUTH_EAST, Vector2(148, 74), Vector2(200, 100)]],
	[5.0, [WEST, Vector2(-92, -2), Vector2(-72, -52), NORTH]],
]

# Group forms, one galaxy per entry: [kind, offset and size in group sizes, turn in degrees].
# Every form reaches just inside its group's size, so the group is as large as it looks.
const LOCAL_GROUP := [["home_spiral", Vector2(-0.43, 0.09), 0.49, 20], ["rich_spiral", Vector2(0.45, -0.25), 0.4, 145],
	["dwarf", Vector2(-0.05, 0.68), 0.16, 60], ["dwarf", Vector2(0.1, -0.75), 0.13, 200], ["spiral", Vector2(0.62, 0.45), 0.23, 280]]
# A compact group: four galaxies close enough to touch.
const COMPACT := [["spiral", Vector2(-0.4, -0.33), 0.44, 30], ["elliptical", Vector2(0.45, -0.28), 0.42, 0],
	["spiral", Vector2(0.3, 0.5), 0.4, 200], ["dwarf", Vector2(-0.5, 0.55), 0.22, 80]]
# A loose group around one elliptical.
const LOOSE := [["elliptical", Vector2(0.05, -0.05), 0.4, 20], ["spiral", Vector2(-0.55, 0.35), 0.36, 110],
	["dwarf", Vector2(0.62, 0.3), 0.2, 0], ["dwarf", Vector2(0.35, -0.68), 0.18, 300], ["elliptical", Vector2(-0.45, -0.55), 0.2, 60]]
# Two spirals passing each other, with a dwarf between their tails.
const PAIR := [["spiral", Vector2(-0.45, 0.1), 0.5, 60], ["spiral", Vector2(0.5, -0.15), 0.45, 250], ["dwarf", Vector2(0.05, 0.75), 0.2, 0]]
# A cluster: a giant elliptical at the center, ringed by older galaxies.
const CLUSTER := [["giant", Vector2.ZERO, 0.4, 0], ["elliptical", Vector2(0.66, 0.18), 0.24, 40],
	["elliptical", Vector2(-0.25, 0.7), 0.22, 100], ["spiral", Vector2(-0.62, -0.3), 0.3, 10],
	["elliptical", Vector2(0.22, -0.7), 0.2, 300], ["dwarf", Vector2(0.55, -0.55), 0.14, 0], ["dwarf", Vector2(-0.7, 0.35), 0.12, 0]]
# The supercluster's galaxies lie along the knot's four arms, which run out along the filaments.
const CORE := [["giant", Vector2.ZERO, 0.3, 0], ["elliptical", Vector2(-0.24, -0.49), 0.18, 30],
	["elliptical", Vector2(0.5, -0.24), 0.18, 120], ["elliptical", Vector2(0.23, 0.5), 0.18, 210],
	["elliptical", Vector2(-0.5, 0.22), 0.18, 300], ["dwarf", Vector2(-0.8, 0.35), 0.12, 0], ["dwarf", Vector2(0.35, 0.8), 0.12, 90]]

# The stars and star-forming nebula of each arm of a rich spiral, [[kind, point, size], ...] and
# [point, size]. Points are in the arm model's own units, where the arm arcs from (-0.7, -0.73) past
# (0.5, -0.3) to (0.85, 0.7); its inner half runs beside the next arm, so stars keep to the outer
# half. Blue giants stand alone: the starting goo must grow to eat them.
const ARMS := [
	[[["blue_giant", Vector2(0.84, 0.25), 0.5], ["yellow_star", Vector2(0.86, 0.66), 0.22]], [Vector2(0.36, -0.42), 0.64]],
	[[["yellow_star", Vector2(0.55, -0.3), 0.2], ["blue_giant", Vector2(0.85, 0.45), 0.52]], [Vector2(0.12, -0.58), 0.55]],
	[[["red_dwarf", Vector2(0.3, -0.46), 0.15], ["yellow_star", Vector2(0.82, 0.12), 0.22], ["red_dwarf", Vector2(0.86, 0.68), 0.16]],
		[Vector2(0.6, -0.26), 0.5]],
]
# An open cluster, [kind, offset and size in cluster sizes], young and bright at its heart.
const OPEN_CLUSTER := [["blue_giant", Vector2(0.05, 0.0), 0.3], ["yellow_star", Vector2(-0.6, -0.33), 0.22],
	["red_dwarf", Vector2(0.55, -0.5), 0.2], ["yellow_star", Vector2(0.5, 0.55), 0.22], ["red_dwarf", Vector2(-0.45, 0.62), 0.18]]
const STARS := {"red_dwarf": "Red dwarf star", "yellow_star": "Yellow star", "blue_giant": "Blue giant star"}
# The arm model draws out to 1.288 times its manifest radius.
const ARM_FIT := 1.288

# [kind, at, turn in degrees, size]
const PLACED := [
	# The milestone at the great node, its knot's arms along the four filaments.
	["supercluster", NODE, 0, 9.5],
	# Clusters at the three smaller nodes.
	["cluster", WEST, 30, 8.0],
	["cluster", SOUTH_EAST, 200, 7.6],
	["cluster", NORTH, 100, 7.2],
	# The Local group, where the goo starts, and its neighbours along the long filament.
	["local_group", LOCAL, 0, 7.0],
	["compact_group", Vector2(-14, 5), 35, 5.4],
	["loose_group", Vector2(-74, 27), 200, 6.0],
	# Groups along the other filaments, fewer and smaller toward the edges.
	["loose_group", Vector2(28, -46), 80, 5.6],
	["compact_group", Vector2(6, -71), 150, 5.0],
	["pair_group", Vector2(58, 15), 300, 6.2],
	["compact_group", Vector2(86, 44), 10, 5.2],
	["loose_group", Vector2(84, -38), 250, 6.0],
	["compact_group", Vector2(136, -43), 120, 5.4],
	["pair_group", Vector2(-138, 31), 20, 6.0],
	["compact_group", Vector2(-100, 80), 260, 5.0],
	["loose_group", Vector2(-92, -108), 170, 6.2],
	["pair_group", Vector2(-84, -28), 70, 5.8],
	["loose_group", Vector2(103, 108), 330, 5.4],
	["compact_group", Vector2(152, 76), 200, 5.2],
	["compact_group", Vector2(-6, -118), 45, 4.8],
	["pair_group", Vector2(-12.8, -80.5), 230, 4.8],
	["loose_group", Vector2(72.3, 29.4), 140, 4.4],
	["pair_group", Vector2(109.5, -39.4), 15, 4.6],
	["loose_group", Vector2(-163.5, 39.2), 290, 4.5],
	["loose_group", Vector2(-105.3, 99.6), 60, 4.6],
	["compact_group", Vector2(-139.5, -111.9), 175, 4.4],
	["compact_group", Vector2(-68.9, -58.3), 320, 4.6],
	["compact_group", Vector2(21.4, -10.8), 190, 4.3],
	["loose_group", Vector2(41.8, 5.6), 20, 4.2],
	["pair_group", Vector2(51.5, -2.4), 105, 4.4],
	["compact_group", Vector2(-47.6, -87.4), 280, 4.4],
	["loose_group", Vector2(128.6, 83.9), 235, 4.5],
	# Far out along the filaments, groups too distant to pick out their galaxies.
	["far_group", Vector2(-160.4, -118.3), 30, 7.6],
	["far_group", Vector2(165.2, 94.8), 110, 8.2],
	["far_group", Vector2(-116.0, 124.0), 250, 7.8],
	["far_group", Vector2(14.6, -123.8), 170, 7.4],
	["far_group", Vector2(96.3, 126.1), 300, 7.9],
	["far_group", Vector2(166.0, -60.5), 75, 8.4],
	["far_group", Vector2(-168.0, 52.6), 140, 7.4],
	["far_group", Vector2(-61.4, -104.2), 205, 7.6],
	["far_group", Vector2(37.4, -63.2), 320, 7.3],
	["far_group", Vector2(152.3, -50.4), 200, 4.8],
	["far_group", Vector2(-118.2, -110.8), 340, 5.2],
	["far_group", Vector2(-100.8, 61.2), 120, 4.6],
	["far_group", Vector2(111.2, 91.5), 260, 4.4],
	# Field galaxies strung along the filaments between the groups, none in the voids.
	["rich_spiral", Vector2(-63.8, 3.1), 70, 2.5],
	["rich_spiral", Vector2(-19.6, 22.8), 300, 2.3],
	["rich_spiral", Vector2(-52.6, 42.1), 150, 2.4],
	["rich_spiral", Vector2(-36.8, -20.4), 230, 2.4],
	["rich_spiral", Vector2(-58.9, 36.4), 40, 2.9],
	["elliptical", Vector2(-33.4, -8.6), 15, 2.4],
	["rich_spiral", Vector2(-3.6, 16.2), 200, 3.3],
	["elliptical", Vector2(-81.3, 12.4), 95, 2.7],
	["elliptical", Vector2(-66.1, 45.8), 160, 3.1],
	["rich_spiral", Vector2(-23.9, -15.2), 120, 2.6],
	["elliptical", Vector2(6.8, -6.1), 250, 3.5],
	["spiral", Vector2(-107.4, 51.8), 330, 3.0],
	["elliptical", Vector2(-119.2, 38.7), 50, 2.5],
	["spiral", Vector2(20.5, -30.7), 10, 3.4],
	["elliptical", Vector2(62.1, -8.9), 280, 2.9],
	["spiral", Vector2(99.2, 55.6), 185, 2.8],
	["elliptical", Vector2(101.8, -45.6), 130, 3.2],
	["spiral", Vector2(-46.3, -63.1), 265, 3.1],
	["elliptical", Vector2(-15.7, -88.2), 0, 2.6],
	["spiral", Vector2(14.2, -58.4), 145, 2.3],
	["elliptical", Vector2(98.6, 88.4), 210, 3.0],
	["spiral", Vector2(132.4, 62.5), 75, 2.7],
	["elliptical", Vector2(-97.8, 5.6), 340, 2.8],
	["spiral", Vector2(-128.5, 23.4), 220, 2.9],
	["elliptical", Vector2(-94.8, -18.3), 110, 2.6],
	["spiral", Vector2(-76.5, -42.0), 35, 2.8],
	["elliptical", Vector2(46.9, -41.6), 300, 2.7],
	["spiral", Vector2(118.8, -30.9), 160, 2.5],
	["elliptical", Vector2(-16.9, -102.5), 65, 2.4],
	["elliptical", Vector2(86.6, 65.3), 190, 2.8],
	["rich_spiral", Vector2(-100.5, 18.9), 280, 2.6],
	["elliptical", Vector2(-8.4, 30.9), 20, 2.9],
	["elliptical", Vector2(-38.5, 47.6), 140, 2.5],
	["rich_spiral", Vector2(-82.6, -3.9), 95, 2.7],
	["rich_spiral", Vector2(8.9, 4.3), 250, 2.4],
	# Dwarf galaxies and giant star-forming nebulae around the Local group.
	["dwarf", Vector2(-60.8, 8.7), 30, 1.3],
	["dwarf", Vector2(-31.5, 24.6), 200, 1.5],
	["dwarf", Vector2(-67.2, 18.3), 110, 1.15],
	["dwarf", Vector2(-22.4, 13.9), 290, 1.7],
	["dwarf", Vector2(-53.7, 30.4), 60, 1.9],
	["dwarf", Vector2(-37.6, -1.8), 150, 1.4],
	["dwarf", Vector2(-78.9, 36.2), 240, 1.6],
	["dwarf", Vector2(-5.2, -3.4), 10, 1.25],
	["dwarf", Vector2(-87.3, 22.1), 320, 1.8],
	["dwarf", Vector2(-71.8, 9.4), 140, 1.45],
	["dwarf", Vector2(-76.3, 17.9), 270, 1.25],
	["dwarf", Vector2(-43.1, 34.6), 50, 1.35],
	["dwarf", Vector2(-15.9, 26.4), 180, 1.6],
	["dwarf", Vector2(-41.2, -12.9), 300, 1.55],
	["dwarf", Vector2(-84.6, 42.8), 90, 1.2],
	["nursery", Vector2(-64.7, 13.6), 200, 1.7],
	["nursery", Vector2(-28.9, 31.7), 30, 1.5],
	["nursery", Vector2(-4.4, 8.3), 150, 1.4],
	["nursery", Vector2(-26.8, 1.3), 80, 1.35],
	["nursery", Vector2(-69.4, 33.1), 170, 1.6],
	["nursery", Vector2(-50.2, -3.7), 260, 1.2],
	# Nurseries closer in, where the Local group's gas collects.
	["nursery", Vector2(-58.4, 15.2), 20, 0.7],
	["nursery", Vector2(-34.2, 20.8), 130, 0.75],
	["nursery", Vector2(-46.9, 4.2), 240, 0.65],
	["nursery", Vector2(-29.3, 13.6), 310, 0.8],
	["nursery", Vector2(-62.3, 29.8), 90, 0.72],
	["nursery", Vector2(-39.8, 29.7), 250, 0.78],
	["nursery", Vector2(-55.9, -1.2), 40, 0.68],
	# Stars torn from the Local group's galaxies: a stream trailing west from the home galaxy, one
	# leading east from its big neighbour along the filament, and a thin halo around the group.
	["yellow_star", Vector2(-52.3, 17.9), 0, 0.34],
	["red_dwarf", Vector2(-53.6, 19.2), 0, 0.26],
	["blue_giant", Vector2(-55.9, 19.7), 0, 0.55],
	["red_dwarf", Vector2(-57.1, 21.8), 0, 0.3],
	["yellow_star", Vector2(-59.8, 22.4), 0, 0.42],
	["red_dwarf", Vector2(-60.7, 24.9), 0, 0.28],
	["yellow_star", Vector2(-63.4, 24.1), 0, 0.38],
	["red_dwarf", Vector2(-38.2, 11.4), 0, 0.24],
	["yellow_star", Vector2(-36.9, 12.8), 0, 0.36],
	["red_dwarf", Vector2(-35.1, 10.1), 0, 0.3],
	["blue_giant", Vector2(-32.8, 9.6), 0, 0.6],
	["yellow_star", Vector2(-30.6, 7.2), 0, 0.4],
	["red_dwarf", Vector2(-28.1, 8.4), 0, 0.27],
	["yellow_star", Vector2(-26.5, 5.9), 0, 0.46],
	["red_dwarf", Vector2(-47.2, 21.6), 0, 0.25],
	["yellow_star", Vector2(-50.9, 11.3), 0, 0.32],
	["red_dwarf", Vector2(-43.8, 6.1), 0, 0.29],
	["yellow_star", Vector2(-38.9, 21.9), 0, 0.35],
	["blue_giant", Vector2(-52.6, 9.0), 0, 0.5],
	["red_dwarf", Vector2(-36.4, 16.9), 0, 0.31],
	["yellow_star", Vector2(-49.5, 24.2), 0, 0.44],
	["red_dwarf", Vector2(-42.1, 25.3), 0, 0.33],
	["yellow_star", Vector2(-55.0, 13.4), 0, 0.39],
	["blue_giant", Vector2(-40.5, 3.9), 0, 0.58],
	# Open clusters that tides have pulled out of the Local group's galaxies.
	["star_cluster", Vector2(-81.2, 30.6), 0, 1.0],
	["star_cluster", Vector2(-50.4, 35.1), 250, 0.9],
	["star_cluster", Vector2(-61.8, -6.9), 10, 1.0],
	["star_cluster", Vector2(-30.7, -3.2), 140, 0.8],
	["star_cluster", Vector2(-72.9, 38.8), 205, 0.9],
	["star_cluster", Vector2(-14.3, 34.9), 75, 1.0],
	["star_cluster", Vector2(-36.1, 40.3), 320, 0.8],
	["star_cluster", Vector2(-70.1, 51.6), 160, 0.9],
	["star_cluster", Vector2(-20.3, -5.9), 285, 0.9],
	["star_cluster", Vector2(-66.8, 36.9), 35, 0.8],
	["star_cluster", Vector2(-44.2, -2.6), 190, 0.8],
	["star_cluster", Vector2(-27.8, 18.7), 300, 0.8],
	["star_cluster", Vector2(-60.2, 18.6), 120, 0.8],
	["star_cluster", Vector2(-12.5, 18.4), 55, 1.0],
	["star_cluster", Vector2(-78.2, 3.6), 230, 0.9],
	["star_cluster", Vector2(-47.9, 48.9), 15, 0.9],
	["star_cluster", Vector2(-24.6, 38.2), 170, 0.9],
	["star_cluster", Vector2(-54.2, -12.3), 260, 1.0],
	["star_cluster", Vector2(-6.6, -12.8), 85, 1.0],
	["star_cluster", Vector2(-88.3, 12.9), 310, 0.9],
	["star_cluster", Vector2(-31.2, -27.4), 145, 0.9],
	["red_dwarf", Vector2(-54.4, 26.6), 0, 0.27],
	["yellow_star", Vector2(-51.8, 28.9), 0, 0.37],
	["blue_giant", Vector2(-57.6, 30.3), 0, 0.52],
	["red_dwarf", Vector2(-46.0, 29.4), 0, 0.3],
	["yellow_star", Vector2(-47.7, 0.6), 0, 0.41],
	["red_dwarf", Vector2(-41.3, -4.4), 0, 0.28],
	["yellow_star", Vector2(-56.2, 5.1), 0, 0.36],
	["red_dwarf", Vector2(-33.7, 3.2), 0, 0.26],
	["blue_giant", Vector2(-24.3, 10.8), 0, 0.56],
	["yellow_star", Vector2(-44.9, 39.8), 0, 0.34],
	["red_dwarf", Vector2(-35.5, 36.2), 0, 0.29],
	["yellow_star", Vector2(-61.2, 41.8), 0, 0.45],
	["red_dwarf", Vector2(-68.7, 2.4), 0, 0.31],
	["blue_giant", Vector2(-33.1, -15.6), 0, 0.48],
	["red_dwarf", Vector2(-45.2, -8.8), 0, 0.27],
	["yellow_star", Vector2(-18.7, 17.9), 0, 0.38],
	["red_dwarf", Vector2(-25.8, 26.9), 0, 0.25],
	["yellow_star", Vector2(-66.3, 24.4), 0, 0.35],
	["red_dwarf", Vector2(-56.4, 10.6), 0, 0.29],
]

var _world: GameWorld
var _web: Node3D
var _spinning: Array[Food] = []
var _detail_tier := 0

func definition() -> Dictionary:
	return {"title": "Cosmic Web", "meters_per_unit": 9.4607e15,
		"initial_radius": 0.4, "goal_radius": 8.6, "growth_scale": 0.145, "start_position": Vector3(HOME.x, 0, HOME.y + 1.9),
		"accent": Color("e3c393"), "field": Rect2(-180, -135, 360, 270),
		"tiers": ["Stars", "Nebulae and clusters", "Galaxies", "Groups and clusters", "The web"],
		"jumps": [{"radius": 0.4, "view_size": 9.0}, {"radius": 0.85, "view_size": 15.0},
			{"radius": 1.75, "view_size": 25.0, "meters_per_unit": 1e20},
			{"radius": 3.2, "view_size": 39.0, "meters_per_unit": 1e21},
			{"radius": 6.0, "view_size": 180.0, "meters_per_unit": 1e22}],
		"background_color": Color("020407"), "ground_color": Color("0c1017"),
		"key_color": Color("eee5d7"), "fill_color": Color("6c8199"),
		"ground_texture": "res://assets/models/ground_space.png", "visible_ground": false}

func ground_height(_point: Vector3) -> float:
	return 0.0

func build(world: GameWorld) -> void:
	_world = world
	_web = Node3D.new()
	_web.name = "The filaments of the cosmic web"
	world.add_child(_web)
	for filament in FILAMENTS:
		_filament(filament[1], filament[0])
	var reason := "Galaxies gather where the web's filaments run and meet."
	var field := "Galaxies strung along a filament of the web between its groups."
	var kinds := {
		"far_group": {"model": "galaxy_group", "label": "Distant galaxy group", "tier": 3, "density": 0.3, "whole": _web,
			"reason": reason, "build": _nonblocking},
		"rich_spiral": {"label": "Spiral galaxy", "tier": 2, "density": 0.185, "whole": _web,
			"reason": field, "build": _spiral.bind("rich_spiral")},
		"spiral": {"label": "Spiral galaxy", "tier": 2, "density": 0.185, "whole": _web,
			"reason": field, "build": _spiral.bind("spiral")},
		"elliptical": {"model": "elliptical_galaxy", "label": "Elliptical galaxy", "tier": 2, "density": 0.185, "whole": _web,
			"reason": field, "build": _nonblocking},
		"dwarf": {"model": "dwarf_galaxy", "label": "Dwarf galaxy", "tier": 1, "density": 0.33, "whole": _web,
			"reason": "Dwarf galaxies orbit the Local group.", "build": _nonblocking},
		"star_cluster": {"label": "Open star cluster", "tier": 0, "density": 0.0, "whole": _web,
			"reason": "Tides tear stars out of the Local group's galaxies.", "build": _cluster},
		"nursery": {"model": "nebula", "label": "Stellar nursery nebula", "tier": 1, "density": 0.37, "whole": _web,
			"reason": "Gas falling into the Local group collects and forms stars.", "build": _nursery},
		"supercluster": {"label": "Filament supercluster", "tier": 4, "density": 0.46, "whole": _web,
			"reason": "The great node, where four filaments of the web meet.", "build": _supercluster},
		"cluster": {"label": "Galaxy cluster", "tier": 4, "density": 0.35, "whole": _web,
			"reason": "Clusters sit where filaments of the web meet.", "build": _group.bind(CLUSTER, Color(0.3, 0.26, 0.2))},
		"local_group": {"label": "Local galaxy group", "tier": 3, "density": 0.2, "whole": _web,
			"reason": reason, "build": _group.bind(LOCAL_GROUP, Color(0.2, 0.24, 0.3))},
		"compact_group": {"label": "Compact galaxy group", "tier": 3, "density": 0.2, "whole": _web,
			"reason": reason, "build": _group.bind(COMPACT, Color(0.2, 0.24, 0.3))},
		"loose_group": {"label": "Loose galaxy group", "tier": 3, "density": 0.2, "whole": _web,
			"reason": reason, "build": _group.bind(LOOSE, Color(0.2, 0.24, 0.3))},
		"pair_group": {"label": "Interacting galaxy pair", "tier": 3, "density": 0.2, "whole": _web,
			"reason": reason, "build": _group.bind(PAIR, Color(0.2, 0.24, 0.3))},
	}
	for star in STARS:
		kinds[star] = {"model": star, "label": STARS[star], "tier": 0, "density": 0.58, "whole": _web, "lift": 0.025,
			"reason": "Tides tear stars out of the Local group's galaxies."}
	world.place(PLACED, kinds)
	_build_spawns()

# A soft band of light along hand-placed points, smoothed between them.
func _filament(points: Array, width: float) -> void:
	var line := PackedVector2Array()
	for index in points.size() - 1:
		for step in 12:
			line.append(points[index].cubic_interpolate(points[index + 1], points[maxi(index - 1, 0)],
				points[mini(index + 2, points.size() - 1)], step / 12.0))
	line.append(points[-1])
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for index in line.size():
		# Matter drains along filaments into the nodes, so a filament swells and brightens toward one.
		var near := INF
		for node in NODES:
			near = minf(near, line[index].distance_to(node))
		var swell := exp(-near / 30.0)
		var along := (line[mini(index + 1, line.size() - 1)] - line[maxi(index - 1, 0)]).normalized()
		var side := along.orthogonal() * width * (0.3 + 0.35 * swell)
		for edge in [-1.0, 1.0]:
			var point: Vector2 = line[index] + side * edge
			vertices.append(Vector3(point.x, -0.3, point.y))
			# The halo shader fades with distance from the UV center, so this fades across the band.
			uvs.append(Vector2(0.5, 0.5 + edge * 0.5))
			colors.append(Color(1.0, 1.0, 1.0, 0.35 + 0.65 * swell))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	_web.add_child(_glow_node(mesh, Color(0.42, 0.5, 0.64)))

func _glow(parent: Node3D, size: float, color: Color) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * size
	var glow := _glow_node(plane, color)
	parent.add_child(glow)
	glow.position.y = -0.2

func _glow_node(mesh: Mesh, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/star_halo.gdshader")
	material.set_shader_parameter("color", color)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

# A group or cluster: its hot gas glows as far as its galaxies reach, and stays when they are eaten.
func _group(group: Food, form: Array, gas: Color) -> void:
	_composite(group)
	_glow(group.visual, group.radius * 2.2, gas)
	for entry in form:
		_galaxy(group, entry[0], entry[1] * group.radius, entry[2] * group.radius, entry[3])

func _supercluster(core: Food) -> void:
	core.milestone = true
	_group(core, CORE, Color(0.36, 0.32, 0.26))
	# The knot's model reaches 1.08 times its manifest radius.
	var knot := Art.model("knot", core.radius / 1.08)
	core.visual.add_child(knot)

func _galaxy(parent: Food, kind: String, at: Vector2, size: float, turn: float) -> void:
	match kind:
		"home_spiral", "rich_spiral", "spiral":
			_spiral(_part("", parent, at, size, 0.003, "Spiral galaxy", 2, turn), kind)
		"elliptical", "giant":
			_nonblocking(_part("elliptical_galaxy", parent, at, size, 0.005,
				"Giant elliptical galaxy" if kind == "giant" else "Elliptical galaxy", 2, turn))
		"dwarf":
			_nonblocking(_part("dwarf_galaxy", parent, at, size, 0.002, "Dwarf galaxy", 1, turn))

func _spiral(galaxy: Food, kind: String) -> void:
	var size := galaxy.radius
	_composite(galaxy)
	galaxy.visual.add_child(Art.model("galaxy_bulge", size * 0.2))
	# Only the spirals rich enough to feed the smallest goo, around the Local group, offer their black
	# hole as a meal of its own. Elsewhere it is drawn with the bulge, so a small goo is not drawn
	# across the web from one worthless speck to the next.
	if kind == "spiral":
		var drawn := Art.model("black_hole", size * 0.16)
		drawn.position.y = 0.05
		galaxy.visual.add_child(drawn)
	else:
		_part("black_hole", galaxy, Vector2.ZERO, size * 0.16, 0.01, "Black hole with accretion disk", 1, 0).position.y = 0.05
	for index in 3:
		# Arms reach a little short of the galaxy, so the goo that can eat an arm cannot yet eat the galaxy.
		var arm := _part("galaxy_arm", galaxy, Vector2.ZERO, size * 0.91, 0.001, "Spiral arm", 2, index * 120.0)
		arm.visual.scale /= ARM_FIT
		arm.height /= ARM_FIT
		_nonblocking(arm)
		if kind != "spiral":
			_arm_stars(arm, arm.radius / ARM_FIT, ARMS[index])
	galaxy.part_consumed.connect(_spiral_changed.bind(galaxy))
	_spinning.append(galaxy)

# `unit` is the arm model's drawn scale, so the stars and nebula follow the arm's curve.
func _arm_stars(arm: Food, unit: float, layout: Array) -> void:
	for entry in layout[0]:
		_part(entry[0], arm, entry[1] * unit, entry[2], 0.03, STARS[entry[0]], 0, 0, 0.025)
	_nursery(_part("nebula", arm, layout[1][0] * unit, layout[1][1], 0.02, "Stellar nursery nebula", 1, 0))

func _nursery(nebula: Food) -> void:
	_nonblocking(nebula)
	_cluster(_part("", nebula, Vector2.ZERO, nebula.radius * 0.85, 0.0, "Open star cluster", 0, 0))

func _cluster(cluster: Food) -> void:
	_composite(cluster)
	# The cluster draws nothing but its stars, so it goes with the last one.
	cluster.collect_when_empty = true
	for entry in OPEN_CLUSTER:
		_part(entry[0], cluster, entry[1] * cluster.radius, entry[2] * cluster.radius, 0.03, STARS[entry[0]], 0, 0, 0.025)

func _part(model: String, parent: Food, at: Vector2, size: float, density: float, label: String, tier: int, turn: float, lift: float = 0.0) -> Food:
	var food := _world._add_food(model, at, size, density * size * size * size, label, false, tier, parent, lift)
	food.rotation.y = deg_to_rad(turn)
	return food

# A whole drawn only by its parts and gas lies flat, so contact is judged at the plane of its galaxies.
func _composite(food: Food) -> void:
	food.height = 0.4

func _nonblocking(food: Food) -> void:
	food.collider_radius = 0.0
	food.collision_layer = 0
	food.collision_mask = 0

func _spiral_changed(part: Food, galaxy: Food) -> void:
	if part.model_name != "galaxy_arm":
		return
	var arms := _arms(galaxy)
	galaxy.title = "Bare galactic bulge" if arms == 0 else "Spiral galaxy · " + str(arms) + " arms"

# Every mover is small enough to eat from the moment its view opens, so none blocks the goo.
func _build_spawns() -> void:
	# Stars and gas cross the filaments around the Local group and on toward the great node, wherever
	# the small goo roams, each released out of view along its stretch of filament.
	for stretch in FEEDERS:
		_world.spawn({"kind": {"model": "yellow_star", "label": "Runaway star", "tier": 0, "density": 1.3,
				"whole": _web, "reason": "Galaxies' black holes fling stars out across the filaments.", "lift": 0.025},
			"from": stretch, "sizes": Vector2(0.16, 0.3), "tiers": Vector2i(0, 1),
			"rate": 0.45, "limit": 4, "lifetime": 18.0, "move": _cross})
		_world.spawn({"kind": {"model": "nebula", "label": "Infalling gas cloud", "tier": 1, "density": 0.35,
				"whole": _web, "reason": "Gas flows in along the filaments of the web."},
			"from": stretch, "sizes": Vector2(0.7, 1.0), "tiers": Vector2i(1, 2),
			"rate": 0.25, "limit": 2, "lifetime": 40.0, "move": _infall})
	# Streams start past the field's edge, where the filaments run on out of the level, so a mover
	# is never released in view, even in the widest view.
	for path in [[Vector2(-192, 44), Vector2(-132, 30), WEST], [Vector2(192, -64), Vector2(128, -42), Vector2(82, -38), NODE],
			[Vector2(95, 145), Vector2(104, 104), SOUTH_EAST]]:
		_world.spawn({"kind": {"model": "dwarf_galaxy", "label": "Satellite galaxy", "tier": 2, "density": 0.14,
				"whole": _web, "reason": "Galaxies stream along the filament toward its node."},
			"from": [path[0]], "sizes": Vector2(1.5, 2.05), "tiers": Vector2i(2, 3),
			"rate": 0.35, "limit": 4, "lifetime": 60.0, "move": _stream.bind(path, 7.0)})
	for path in [[Vector2(-192, -116), Vector2(-88, -108), NORTH], [Vector2(14, -145), Vector2(-8, -116), NORTH],
			[Vector2(192, 96), Vector2(148, 74), SOUTH_EAST], [Vector2(-117, 145), Vector2(-98, 72), WEST]]:
		_world.spawn({"kind": {"model": "galaxy_group", "label": "Infalling galaxy group", "tier": 3, "density": 0.3,
				"whole": _web, "reason": "Small groups fall along the filaments into the clusters."},
			"from": [path[0]], "sizes": Vector2(2.8, 3.8), "tiers": Vector2i(3, 4),
			"rate": 0.15, "limit": 4, "lifetime": 60.0, "move": _stream.bind(path, 12.0)})
	for path in [[Vector2(-192, 44), Vector2(-132, 30), WEST, Vector2(-45, 15), NODE], [Vector2(192, -64), Vector2(128, -42), NODE],
			[Vector2(95, 145), Vector2(104, 104), SOUTH_EAST, Vector2(55, 12), NODE]]:
		_world.spawn({"kind": {"model": "galaxy_group", "label": "Infalling galaxy cluster", "tier": 4, "density": 0.12,
				"whole": _web, "reason": "Whole clusters fall along the filaments toward the great node."},
			"from": [path[0]], "sizes": Vector2(5.5, 7.0), "tiers": Vector2i(4, 4),
			"rate": 0.1, "limit": 4, "lifetime": 60.0, "move": _stream.bind(path, 20.0)})

# Runaway stars cross the filament in straight lines, each through where the goo was when it set out.
func _cross(mover: Dictionary, delta: float) -> Vector2:
	return mover.at + (mover.toward - mover.from).normalized() * 2.4 * delta

# Gas clouds drift in along the filament, toward where the goo was when they set out, and swirl.
func _infall(mover: Dictionary, delta: float) -> Vector2:
	var offset: Vector2 = mover.at - mover.toward
	var inward := -offset.normalized()
	var around := inward.orthogonal() * (0.6 if mover.seed > 0.5 else -0.6)
	return mover.at + (inward + around) * 2.6 * delta

# Movers follow a filament's points toward its node, each in its own lane beside the spine, and
# circle the node once there instead of piling onto it.
func _stream(mover: Dictionary, delta: float, path: Array, speed: float) -> Vector2:
	var leg: int = mover.get("leg", 1)
	var end: Vector2 = path[-1]
	if leg == path.size() - 1 and mover.at.distance_to(end) < 14.0:
		var orbit: Vector2 = end + (mover.at - end).normalized().rotated(0.6) * lerpf(6.0, 12.0, mover.seed)
		return mover.at + (orbit - mover.at).limit_length(speed * delta)
	if mover.at.distance_to(path[leg]) < 3.0 and leg < path.size() - 1:
		leg += 1
		mover.leg = leg
	var lane: Vector2 = (path[leg] - path[leg - 1]).normalized().orthogonal() * (mover.seed - 0.5) * 5.0
	return mover.at + (path[leg] + lane - mover.at).limit_length(speed * delta)

func _arms(galaxy: Food) -> int:
	var arms := 0
	for child in galaxy.parts:
		if is_instance_valid(child) and child.active and child.model_name == "galaxy_arm":
			arms += 1
	return arms

# Once a spiral's black hole is a speck (the world's detail rule for a view's smaller objects), its
# arms, stars, and nebulae no longer read apart, so an intact spiral draws as one galaxy model and
# is eaten whole. Its parts' growth moves into it and the parts leave the level, which also spares
# their draws and scans in the widest views.
func _simplify_spirals() -> void:
	var speck := float(_world.config.jumps[_world.current_tier].radius) * 0.12
	for galaxy in _spinning:
		if galaxy.active and not galaxy.simple and _world.current_tier > 1 and galaxy.radius * 0.16 < speck and _arms(galaxy) == 3:
			galaxy.volume = galaxy.remaining_volume()
			for part in galaxy.parts:
				_world._retire(part)
			galaxy.simplify("galaxy")

func step(delta: float) -> void:
	if _detail_tier != _world.current_tier:
		_detail_tier = _world.current_tier
		_simplify_spirals()
	for index in _spinning.size():
		var galaxy := _spinning[index]
		if galaxy.active:
			galaxy.rotation.y += delta * (0.02 if index % 2 else -0.02)
