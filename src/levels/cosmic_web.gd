extends RefCounted

# One stretch of the cosmic web. Four filaments meet at the great node north-east of center, where
# the Filament supercluster sits; three smaller nodes hold galaxy clusters, and thinner filaments run
# on from them to the edges. Galaxy groups sit along the filaments and the voids between them stay
# empty. The goo starts on an arm of the home galaxy in the Local group, on the long filament that
# runs from the west cluster to the great node. Runaway stars fly out of the home galaxy's core, gas
# falls into the Local group along its filament, and galaxies and groups stream along the filaments
# toward the nodes.
const NODE := Vector2(40.0, -20.0)
const WEST := Vector2(-95.0, 35.0)
const SOUTH_EAST := Vector2(115.0, 70.0)
const NORTH := Vector2(-30.0, -95.0)
const NODES := [NODE, WEST, SOUTH_EAST, NORTH]
const LOCAL := Vector2(-45.0, 15.0)
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
	[[["blue_giant", Vector2(0.84, 0.25), 0.5], ["yellow_star", Vector2(0.86, 0.66), 0.22]], [Vector2(0.36, -0.42), 0.55]],
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
]

var _world: GameWorld
var _web: Node3D
var _home: Food
var _spinning: Array[Food] = []
var _clusters: Array[Food] = []
var _tier := 0

func definition() -> Dictionary:
	return {"title": "Cosmic Web", "meters_per_unit": 9.4607e15,
		"initial_radius": 0.4, "goal_radius": 8.6, "start_position": Vector3(HOME.x, 0, HOME.y + 1.9),
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
	var kinds := {
		"supercluster": {"label": "Filament supercluster", "tier": 4, "density": 0.18, "whole": _web,
			"reason": "The great node, where four filaments of the web meet.", "build": _supercluster},
		"cluster": {"label": "Galaxy cluster", "tier": 4, "density": 0.04, "whole": _web,
			"reason": "Clusters sit where filaments of the web meet.", "build": _group.bind(CLUSTER, Color(0.3, 0.26, 0.2))},
		"local_group": {"label": "Local galaxy group", "tier": 3, "density": 0.025, "whole": _web,
			"reason": reason, "build": _group.bind(LOCAL_GROUP, Color(0.2, 0.24, 0.3))},
		"compact_group": {"label": "Compact galaxy group", "tier": 3, "density": 0.025, "whole": _web,
			"reason": reason, "build": _group.bind(COMPACT, Color(0.2, 0.24, 0.3))},
		"loose_group": {"label": "Loose galaxy group", "tier": 3, "density": 0.025, "whole": _web,
			"reason": reason, "build": _group.bind(LOOSE, Color(0.2, 0.24, 0.3))},
		"pair_group": {"label": "Interacting galaxy pair", "tier": 3, "density": 0.025, "whole": _web,
			"reason": reason, "build": _group.bind(PAIR, Color(0.2, 0.24, 0.3))},
	}
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
			var galaxy := _part("", parent, at, size, 0.012, "Spiral galaxy", 2, turn)
			_composite(galaxy)
			galaxy.visual.add_child(Art.model("galaxy_bulge", size * 0.2))
			var hole := _part("black_hole", galaxy, Vector2.ZERO, size * 0.16, 0.2, "Black hole with accretion disk", 1, 0)
			hole.position.y = 0.05
			for index in 3:
				# Arms reach a little short of the galaxy, so the goo that can eat an arm cannot yet eat the galaxy.
				var arm := _part("galaxy_arm", galaxy, Vector2.ZERO, size * 0.91, 0.005, "Spiral arm", 2, index * 120.0)
				arm.visual.scale /= ARM_FIT
				arm.height /= ARM_FIT
				_nonblocking(arm)
				if kind != "spiral":
					_arm_stars(arm, arm.radius / ARM_FIT, ARMS[index])
			galaxy.part_consumed.connect(_spiral_changed.bind(galaxy))
			_spinning.append(galaxy)
			if kind == "home_spiral":
				_home = galaxy
		"elliptical", "giant":
			_nonblocking(_part("elliptical_galaxy", parent, at, size, 0.024,
				"Giant elliptical galaxy" if kind == "giant" else "Elliptical galaxy", 2, turn))
		"dwarf":
			_nonblocking(_part("dwarf_galaxy", parent, at, size, 0.06, "Dwarf galaxy", 1, turn))

# `unit` is the arm model's drawn scale, so the stars and nebula follow the arm's curve.
func _arm_stars(arm: Food, unit: float, layout: Array) -> void:
	for entry in layout[0]:
		_part(entry[0], arm, entry[1] * unit, entry[2], 0.15, STARS[entry[0]], 0, 0, 0.025)
	var nebula := _part("nebula", arm, layout[1][0] * unit, layout[1][1], 0.04, "Stellar nursery nebula", 1, 0)
	_nonblocking(nebula)
	var cluster := _part("", nebula, Vector2.ZERO, nebula.radius * 0.85, 0.0, "Open star cluster", 0, 0)
	_composite(cluster)
	# The cluster draws nothing but its stars, so it goes with the last one.
	cluster.collect_when_empty = true
	_clusters.append(cluster)
	for entry in OPEN_CLUSTER:
		_part(entry[0], cluster, entry[1] * cluster.radius, entry[2] * cluster.radius, 0.15, STARS[entry[0]], 0, 0, 0.025)

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
	var arms := 0
	for child in galaxy.parts:
		if is_instance_valid(child) and child.active and child.model_name == "galaxy_arm":
			arms += 1
	galaxy.title = "Bare galactic bulge" if arms == 0 else "Spiral galaxy · " + str(arms) + " arms"

# Every mover is small enough to eat from the moment its view opens, so none blocks the goo.
func _build_spawns() -> void:
	_world.spawn({"kind": {"model": "yellow_star", "label": "Runaway star", "tier": 0, "density": 0.6,
			"whole": _home, "reason": "The home galaxy's black hole flings stars out of its core.", "lift": 0.025},
		"from": [HOME], "sizes": Vector2(0.16, 0.3), "tiers": Vector2i(0, 1),
		"rate": 0.4, "limit": 5, "lifetime": 14.0, "move": _fling})
	for source in [Vector2(-70, 25), Vector2(-20, 6)]:
		_world.spawn({"kind": {"model": "nebula", "label": "Infalling gas cloud", "tier": 1, "density": 0.15,
				"whole": _web, "reason": "Gas flows along the filament into the Local group."},
			"from": [source], "sizes": Vector2(0.7, 1.0), "tiers": Vector2i(1, 2),
			"rate": 0.15, "limit": 2, "lifetime": 40.0, "move": _infall})
	for path in [[Vector2(-168, 41), Vector2(-132, 30), WEST], [Vector2(168, -56), Vector2(128, -42), Vector2(82, -38), NODE],
			[Vector2(97, 124), Vector2(104, 104), SOUTH_EAST]]:
		_world.spawn({"kind": {"model": "dwarf_galaxy", "label": "Satellite galaxy", "tier": 2, "density": 0.06,
				"whole": _web, "reason": "Galaxies stream along the filament toward its node."},
			"from": [path[0]], "sizes": Vector2(1.5, 2.05), "tiers": Vector2i(2, 3),
			"rate": 0.12, "limit": 2, "lifetime": 60.0, "move": _stream.bind(path, 7.0)})
	for path in [[Vector2(-166, -114), Vector2(-88, -108), NORTH], [Vector2(13, -124), Vector2(-8, -116), NORTH],
			[Vector2(167, 93), Vector2(148, 74), SOUTH_EAST], [Vector2(-114, 124), Vector2(-98, 72), WEST]]:
		_world.spawn({"kind": {"model": "galaxy_group", "label": "Infalling galaxy group", "tier": 3, "density": 0.13,
				"whole": _web, "reason": "Small groups fall along the filaments into the clusters."},
			"from": [path[0]], "sizes": Vector2(2.8, 3.8), "tiers": Vector2i(3, 4),
			"rate": 0.055, "limit": 2, "lifetime": 60.0, "move": _stream.bind(path, 12.0)})
	for path in [[Vector2(-160, 38), Vector2(-132, 30), WEST, Vector2(-45, 15), NODE], [Vector2(160, -53), Vector2(128, -42), NODE],
			[Vector2(98, 118), Vector2(104, 104), SOUTH_EAST, Vector2(55, 12), NODE]]:
		_world.spawn({"kind": {"model": "galaxy_group", "label": "Infalling galaxy cluster", "tier": 4, "density": 0.08,
				"whole": _web, "reason": "Whole clusters fall along the filaments toward the great node."},
			"from": [path[0]], "sizes": Vector2(5.5, 7.0), "tiers": Vector2i(4, 4),
			"rate": 0.022, "limit": 2, "lifetime": 60.0, "move": _stream.bind(path, 20.0)})

# Runaway stars leave the core in straight lines, each on its own heading.
func _fling(mover: Dictionary, _delta: float) -> Vector2:
	return mover.from + Vector2.from_angle(mover.seed * TAU) * (1.0 + mover.age * 2.4)

# Gas clouds drift toward the Local group and swirl into it.
func _infall(mover: Dictionary, delta: float) -> Vector2:
	var offset: Vector2 = mover.at - LOCAL
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

func step(delta: float) -> void:
	# A size jump retires a cluster's stars as detail; the cluster then shows nothing, so it retires too.
	if _world.current_tier != _tier:
		_tier = _world.current_tier
		for cluster in _clusters:
			if cluster._last_visible_part(null):
				cluster.detail_hidden = true
	for index in _spinning.size():
		var galaxy := _spinning[index]
		if galaxy.active:
			galaxy.rotation.y += delta * (0.02 if index % 2 else -0.02)
