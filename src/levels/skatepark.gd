extends RefCounted

# One concrete skate bowl in a small city park. The bowl sits east of center; the wind off the
# street to the north blows litter over its north coping, and the litter rolls down and gathers
# in the south gutter. Riders carve laps on its walls. The park's big vert quarter pipe stands on
# the bowl's west lip, where skaters drop in, with spectator benches, gear piles, and shade trees
# on the deck behind it. A street course fills the south plaza: a cone slalom, three grind rails,
# and two quarter pipes facing each other. A line of pipes backs onto the north fence. Skaters
# and the park's service vehicles come in through the gate in the east fence.
const BOWL := Vector2(14.0, -4.0)
# The bowl is an ellipse this many times wider east to west than north to south.
const STRETCH := 1.2
const FLOOR_RADIUS := 9.0
const COPING_RADIUS := 19.0
const DEPTH := 2.6
# The north coping, where wind-blown litter tops the rim, and the deck beside the vert pipe, where
# a skater's bail sends the board rolling into the bowl, out of view while the goo is in the bowl.
const NORTH_COPING := [Vector2(2.6, -20.5), Vector2(25.4, -20.5)]
const WEST_DECK := [Vector2(-29.0, 4.0), Vector2(-29.0, 9.0)]
# The street beyond the east gate, past the field's edge, so the park's traffic comes in from out
# of view even when the view takes in the whole park.
const GATE := [Vector2(55.0, 18.0), Vector2(55.0, 20.0)]
# The service lane runs from the gate along the bowl's south side to the west lip and back,
# between the coping and the cone slalom.
const LANE_END := 2.0
# Parking bays inside the gate, north of the lane: one for every vehicle that can be live at once.
const PARKING := [Vector2(44.0, 4.0), Vector2(44.0, 11.0), Vector2(37.0, 4.0), Vector2(37.0, 11.0)]
# A rider's board is this share of the rider's footprint, and the rider's figure this share.
const RIDER_BOARD := 0.79
const RIDER_FIGURE := 0.98

# [kind, at, turn in degrees, size]
const PLACED := [
	# The milestone: the big vert quarter pipe on the bowl's west lip, facing east into it.
	["big_pipe", Vector2(-16.0, -4.0), 0, 4.8],
	# Litter the wind left in the bowl: a drift in each half of the south gutter, a few pieces in
	# the west gutter where the goo starts, and strays along the rest of the gutter.
	["cap", Vector2(16.2, 3.9), 30, 0.18],
	["pebble", Vector2(17.3, 4.6), 0, 0.16],
	["cap", Vector2(18.7, 3.5), 200, 0.2],
	["bolt", Vector2(17.1, 2.9), 75, 0.14],
	["bearing", Vector2(19.8, 2.4), 0, 0.15],
	["pebble", Vector2(15.2, 4.5), 120, 0.14],
	["cap", Vector2(8.0, 3.4), 310, 0.19],
	["pebble", Vector2(9.3, 3.3), 60, 0.15],
	["bolt", Vector2(7.1, 2.4), 140, 0.13],
	["cap", Vector2(9.0, 2.0), 90, 0.17],
	["pebble", Vector2(6.6, 1.1), 250, 0.16],
	["bearing", Vector2(4.6, -5.4), 0, 0.15],
	["cap", Vector2(4.9, -3.0), 170, 0.17],
	["bolt", Vector2(5.4, -6.6), 20, 0.13],
	["bolt", Vector2(14.0, -12.0), 100, 0.14],
	["pebble", Vector2(20.5, -11.4), 0, 0.15],
	["cap", Vector2(23.6, -4.2), 240, 0.18],
	["bearing", Vector2(23.0, 1.0), 0, 0.14],
	# A board left on the bowl floor.
	["board", Vector2(13.0, -6.5), 30, 1.25],
	# Riders carving laps on the bowl walls, each on its own line.
	["rider", Vector2(0.5, -8.1), 20, 1.35],
	["rider", Vector2(26.0, -12.4), 110, 1.4],
	["rider", Vector2(16.4, 7.3), 200, 1.3],
	["rider", Vector2(1.6, 4.7), 290, 1.35],
	# Spectator benches on the west lip, north and south of the vert pipe, turned to the bowl, each
	# with a trash can behind it and a rider's gear pile and board in front.
	["bench", Vector2(-10.0, -20.0), 65, 2.1],
	["trash_can", Vector2(-16.0, -23.0), 0, 1.0],
	["helmet", Vector2(-6.5, -18.6), 40, 0.7],
	["shoe", Vector2(-4.8, -16.7), 300, 0.6],
	["water_bottle", Vector2(-7.6, -16.2), 0, 0.5],
	["board", Vector2(-3.5, -20.8), 150, 1.25],
	["bench", Vector2(-10.0, 12.0), 115, 2.1],
	["trash_can", Vector2(-16.0, 15.0), 0, 1.0],
	["shoe", Vector2(-6.8, 9.0), 80, 0.6],
	["helmet", Vector2(-5.0, 10.8), 210, 0.7],
	["water_bottle", Vector2(-7.9, 11.4), 0, 0.5],
	["board", Vector2(-3.5, 14.6), 20, 1.25],
	# The shaded lawn behind the vert pipe: two trees, a bench under each looking east, a can.
	["tree", Vector2(-36.0, -28.0), 40, 4.4],
	["bench", Vector2(-28.0, -20.0), 90, 2.0],
	["trash_can", Vector2(-28.0, -13.5), 0, 1.0],
	["tree", Vector2(-37.0, 8.0), 160, 4.2],
	["bench", Vector2(-28.0, 28.0), 90, 2.0],
	["water_bottle", Vector2(-24.3, 26.6), 0, 0.5],
	["helmet", Vector2(-24.4, 29.4), 120, 0.7],
	# The pipe line along the north fence: two quarter pipes facing the bowl and a flat rail
	# between them, with boards dropped on the way in.
	["pipe", Vector2(-8.0, -35.0), 270, 3.4],
	["rail", Vector2(12.0, -36.0), 0, 3.0],
	["pipe", Vector2(32.0, -35.0), 270, 3.6],
	["board", Vector2(-1.5, -30.0), 200, 1.25],
	["board", Vector2(24.0, -30.5), 340, 1.25],
	# The east deck by the gate: one bench looking west over the bowl, its can, and a lost shoe.
	["bench", Vector2(43.0, -8.0), 270, 2.0],
	["trash_can", Vector2(43.0, -15.0), 0, 1.0],
	["shoe", Vector2(39.6, -6.5), 150, 0.6],
	# The south plaza's street course, south of the service lane: a cone slalom, three grind rails
	# at easy angles, two quarter pipes facing each other, and benches along the far edge.
	["cone", Vector2(-8.0, 28.0), 0, 0.9],
	["cone", Vector2(-3.0, 28.0), 0, 0.9],
	["cone", Vector2(2.0, 28.0), 0, 0.9],
	["cone", Vector2(7.0, 28.0), 0, 0.9],
	["cone", Vector2(12.0, 28.0), 0, 0.9],
	["rail", Vector2(-22.0, 35.0), 10, 2.7],
	["rail", Vector2(0.0, 37.0), 0, 3.2],
	["rail", Vector2(22.0, 35.0), 350, 2.9],
	["pipe", Vector2(-35.0, 33.0), 0, 3.4],
	["pipe", Vector2(40.0, 27.0), 180, 3.5],
	["board", Vector2(-14.0, 30.0), 80, 1.25],
	["bench", Vector2(-12.0, 42.0), 180, 2.0],
	["trash_can", Vector2(-4.0, 43.0), 0, 1.0],
	["bench", Vector2(14.0, 42.0), 180, 2.0],
	["helmet", Vector2(10.4, 40.2), 300, 0.7],
	["shoe", Vector2(17.8, 40.0), 20, 0.6],
	["tree", Vector2(36.0, 42.0), 250, 4.2],
]

# The street north of the park fence: [at, turn in degrees, size].
const PARKED_CARS := [
	[Vector2(-40.0, -61.5), 2, 2.6], [Vector2(-27.0, -61.0), -3, 2.5], [Vector2(-3.0, -61.8), 1, 2.7],
	[Vector2(11.0, -61.2), 178, 2.6], [Vector2(33.0, -61.6), -2, 2.6],
]
const STREET_TREES := [
	[Vector2(-44.0, -73.0), 20, 3.6], [Vector2(-22.0, -74.0), 200, 4.4], [Vector2(-6.0, -72.0), 80, 3.1],
	[Vector2(19.0, -73.5), 140, 4.1], [Vector2(41.0, -72.5), 300, 3.4],
]

var _world: GameWorld
var _bowl: Node3D
var _street: Node3D
var _boards: Array[Dictionary] = []
var _riders: Array[Dictionary] = []
# The vehicle parked in or bound for each bay.
var _parked: Array[Food] = [null, null, null, null]
var _runaways: Dictionary
var _time := 0.0

func definition() -> Dictionary:
	return {"title": "Skatepark Bowl", "meters_per_unit": 0.25,
		"initial_radius": 0.55, "goal_radius": 4.3,
		"start_position": Vector3(7.5, 0.0, -4.0), "field": Rect2(-45, -44, 94, 92),
		"accent": Color("ffaf68"), "background_color": Color("9db8c7"),
		"key_color": Color("fff0d0"), "fill_color": Color("98dcff"),
		"ground_color": Color("a4b6b7"), "ground_texture": "res://assets/models/ground_concrete.png",
		"tiers": ["Litter in the gutter", "Boards and gear", "Skaters and furniture", "Rails and pipes", "The park"],
		"jumps": [{"radius": 0.55, "view_size": 16.0}, {"radius": 0.85, "view_size": 21.0},
			{"radius": 1.4, "view_size": 30.0}, {"radius": 2.3, "view_size": 41.0},
			{"radius": 3.0, "view_size": 53.0}]}

func ground_height(point: Vector3) -> float:
	var distance := _bowl_distance(Vector2(point.x, point.z))
	var slope := smoothstep(FLOOR_RADIUS, COPING_RADIUS, distance)
	return -DEPTH * (1.0 - slope)

# Distance from the bowl's center in the bowl's own round coordinates.
func _bowl_distance(at: Vector2) -> float:
	return Vector2((at.x - BOWL.x) / STRETCH, at.y - BOWL.y).length()

func build(world: GameWorld) -> void:
	_world = world
	_build_bowl()
	_build_street()
	var litter := "Wind off the street blows litter over the north coping, and it rolls down into the bowl's gutter."
	var hardware := "Hardware shaken loose from riders' trucks rolls down into the bowl's gutter."
	var gear := "Skaters leave their gear by the benches before they ride."
	var kinds := {
		"big_pipe": {"model": "ramp", "label": "Big vert quarter pipe", "tier": 4, "density": 0.07, "whole": _bowl,
			"reason": "The park's biggest quarter pipe stands on the bowl's west lip, where skaters drop in.",
			"fit": 1.25, "build": func(pipe: Food) -> void: pipe.milestone = true},
		"cap": {"model": "bottle_cap", "label": "Bottle cap", "tier": 0, "density": 0.35, "whole": _bowl, "reason": litter},
		"pebble": {"model": "pebble", "label": "Pebble", "tier": 0, "density": 0.35, "whole": _bowl, "reason": litter},
		"bolt": {"model": "bolt", "label": "Bolt", "tier": 0, "density": 0.35, "whole": _bowl, "reason": hardware},
		"bearing": {"model": "bearing", "label": "Bearing", "tier": 0, "density": 0.35, "whole": _bowl, "reason": hardware},
		"board": {"label": "Skateboard", "tier": 1, "density": 0.01, "whole": _bowl,
			"reason": "A rider left this board while resting.", "build": _loose_board},
		"rider": {"label": "Skater", "tier": 2, "density": 0.04, "whole": _bowl,
			"reason": "This skater carves laps on the bowl's walls.", "build": _rider},
		"helmet": {"model": "helmet", "label": "Helmet", "tier": 1, "density": 0.025, "whole": _bowl, "reason": gear},
		"shoe": {"model": "shoe", "label": "Shoe", "tier": 1, "density": 0.025, "whole": _bowl, "reason": gear},
		"water_bottle": {"model": "water_bottle", "label": "Water bottle", "tier": 1, "density": 0.025, "whole": _bowl, "reason": gear},
		"cone": {"model": "cone", "label": "Practice cone", "tier": 1, "density": 0.012, "whole": _bowl,
			"reason": "The cones mark a slalom line across the plaza.", "fit": 1.362},
		"bench": {"model": "bench", "label": "Park bench", "tier": 2, "density": 0.055, "whole": _bowl,
			"reason": "Benches face the bowl and the street course for spectators."},
		"trash_can": {"model": "trash_can", "label": "Park trash can", "tier": 2, "density": 0.04, "whole": _bowl,
			"reason": "Each trash can stands by a bench."},
		"rail": {"label": "Grind rail", "tier": 3, "density": 0.02, "whole": _bowl,
			"reason": "The grind rail belongs to the park's street course.", "build": _rail},
		"pipe": {"model": "ramp", "label": "Quarter pipe", "tier": 3, "density": 0.065, "whole": _bowl,
			"reason": "Quarter pipes face each other across the street course and line the north fence.", "fit": 1.25},
		"tree": {"model": "tree", "label": "Shade tree", "tier": 4, "density": 0.07, "whole": _bowl,
			"reason": "Shade trees stand over the park's benches."},
	}
	world.place(PLACED, kinds)
	_build_spawns()

func _build_bowl() -> void:
	_bowl = Node3D.new()
	_bowl.name = "The concrete bowl and its low gutter"
	_world.add_child(_bowl)
	# The dark gutter line where the floor meets the walls, and the pale steel coping on the rim.
	for ring in [[8.6, Color("657a82")], [COPING_RADIUS, Color("d4eee7")]]:
		var strip := SurfaceTool.new()
		strip.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(96):
			var a := _ring_point(ring[0], index * TAU / 96.0)
			var b := _ring_point(ring[0], (index + 1) * TAU / 96.0)
			var side := (b - a).cross(Vector3.UP).normalized() * 0.12
			for point in [a - side, b + side, a + side, a - side, b - side, b + side]:
				strip.set_normal(Vector3.UP)
				strip.set_uv(Vector2(point.x, point.z) * 0.2)
				strip.add_vertex(point)
		var mesh := MeshInstance3D.new()
		mesh.mesh = strip.commit()
		mesh.material_override = _concrete_material(ring[1])
		_bowl.add_child(mesh)

func _ring_point(radius: float, angle: float) -> Vector3:
	var point := Vector3(BOWL.x + cos(angle) * radius * STRETCH, 0.0, BOWL.y + sin(angle) * radius)
	point.y = ground_height(point) + 0.035
	return point

# A board is a deck on two trucks with two wheels each. It draws nothing of its own, so it goes
# with its last deck, truck, or wheel.
func _board_parts(board: Food) -> void:
	var scale := board.radius / 1.18
	board.height = 0.5 * scale
	board.collect_when_empty = true
	var deck := _world._add_food("board", Vector2.ZERO, 1.15 * scale, 0.025 * pow(1.15 * scale, 3.0), "Skate deck", false, 1, board, 0.22 * scale)
	deck.rotation.y = 0.0
	for axle in [-1.0, 1.0]:
		var truck := _world._add_food("truck", Vector2(axle * 0.68, 0) * scale, 0.34 * scale, 0.05 * pow(0.34 * scale, 3.0), "Skateboard truck", false, 1, board, 0.11 * scale)
		truck.rotation.y = 0.0
		for side in [-1.0, 1.0]:
			var wheel := _world._add_food("wheel", Vector2(axle * 0.68, side * 0.44) * scale, 0.16 * scale, 0.15 * pow(0.16 * scale, 3.0), "Skateboard wheel", false, 0, board)
			wheel.rotation.y = 0.0
	board.part_consumed.connect(_board_changed.bind(board))

func _loose_board(board: Food) -> void:
	_board_parts(board)
	_align_to_ground(board)
	_boards.append({"food": board, "velocity": Vector2.ZERO})

# A rider stands on its own board and carves an elliptical lap around the bowl at its placed
# distance, swinging up and down the wall; the row's turn sets where in that swing it starts.
func _rider(rider: Food) -> void:
	var size := rider.radius
	rider.height = 2.2 * size
	var board := _world._add_food("", Vector2.ZERO, RIDER_BOARD * size, 0.01 * pow(RIDER_BOARD * size, 3.0), "Skateboard", false, 1, rider)
	board.rotation.y = 0.0
	_board_parts(board)
	var person := Art.model("skater", RIDER_FIGURE * size)
	rider.visual.add_child(person)
	person.position.y = 0.3 * board.radius / 1.18
	var offset := Vector2((rider.position.x - BOWL.x) / STRETCH, rider.position.z - BOWL.y)
	rider.part_consumed.connect(_rider_changed.bind(rider))
	_riders.append({"food": rider, "board": board, "phase": offset.angle(), "radius": offset.length(),
		"pace": 2.0 / (offset.length() * STRETCH), "sway": rider.rotation.y})
	_step_rider(_riders[-1])

# The bar rests on two posts; the goo can eat a post first, and the bar then tips toward it.
func _rail(rail: Food) -> void:
	var size := rail.radius
	var unit := size / 2.6
	rail.height = 1.25 * unit
	var bar := Art.model("rail_bar", size * 0.952)
	rail.visual.add_child(bar)
	bar.position.y = 0.94 * unit
	for side in [-1.0, 1.0]:
		var post := _world._add_food("rail_post", Vector2(side * size * 0.643, 0), 0.42 * unit, 0.03 * pow(0.42 * unit, 3.0), "Grind rail post", false, 2, rail)
		post.rotation.y = 0.0
	rail.part_consumed.connect(_rail_changed.bind(rail))

func _board_changed(part: Food, board: Food) -> void:
	if part.model_name == "wheel":
		board.set_meta("lost_wheel", true)
		board.rotation.x = signf(part.position.z) * 0.28
		board.rotation.z = -signf(part.position.x) * 0.12
		board.title = "Tipped skateboard"
	elif part.model_name == "board":
		board.title = "Skateboard trucks and wheels"
	elif part.model_name == "truck":
		board.set_meta("lost_wheel", true)
		board.rotation.z = -signf(part.position.x) * 0.25

func _rider_changed(part: Food, rider: Food) -> void:
	if part.title == "Skateboard" or part.model_name.is_empty():
		rider.title = "Standing skater"
		rider.visual.get_child(0).position.y = 0.0

func _rail_changed(part: Food, rail: Food) -> void:
	var bar: Node3D = rail.visual.get_child(0)
	bar.rotation.z = -signf(part.position.x) * 0.24
	bar.position.y = 0.58 * rail.radius / 2.6
	rail.title = "Tilted grind rail"

func _build_spawns() -> void:
	_world.spawn({"kind": {"model": "bottle_cap", "label": "Blown bottle cap", "tier": 0, "density": 0.5,
			"whole": _bowl, "reason": "Wind off the street blows litter over the north coping, and it rolls down into the bowl."},
		"from": NORTH_COPING, "sizes": Vector2(0.16, 0.24), "tiers": Vector2i(0, 0),
		"rate": 0.76, "limit": 6, "lifetime": 35.0, "move": _roll.bind(0.5, 0.6)})
	_runaways = {"kind": {"model": "skateboard", "label": "Runaway skateboard", "tier": 1, "density": 0.06,
			"whole": _bowl, "reason": "A skater bails on the deck beside the vert pipe, and the board rolls away into the bowl."},
		"from": WEST_DECK, "sizes": Vector2(0.8, 1.05), "tiers": Vector2i(1, 1),
		"rate": 0.35, "limit": 3, "lifetime": 35.0, "move": _roll.bind(0.12, 0.0)}
	_world.spawn(_runaways)
	_world.spawn({"kind": {"model": "skater", "label": "Skater on foot", "tier": 2, "density": 0.11,
			"whole": _bowl, "reason": "Skaters walk in through the east gate to ride the park."},
		"from": GATE, "sizes": Vector2(1.45, 1.7), "tiers": Vector2i(2, 2),
		"rate": 0.2, "limit": 3, "lifetime": 40.0, "move": _walk})
	_world.spawn({"kind": {"model": "parked_car", "label": "Park service cart", "tier": 3, "density": 0.07,
			"whole": _street, "reason": "The park's service cart drives in through the east gate to empty the trash cans."},
		"from": GATE, "sizes": Vector2(2.3, 2.7), "tiers": Vector2i(3, 3),
		"rate": 0.115, "limit": 2, "lifetime": 40.0, "move": _drive})
	_world.spawn({"kind": {"model": "parked_car", "label": "Park maintenance truck", "tier": 4, "density": 0.07,
			"whole": _street, "reason": "The maintenance truck drives in through the east gate to work on the ramps."},
		"from": GATE, "sizes": Vector2(3.0, 3.5), "tiers": Vector2i(4, 4),
		"rate": 0.093, "limit": 2, "lifetime": 40.0, "move": _drive})

# Litter and runaway boards roll under gravity on the bowl's walls from a push toward its center,
# and settle at the given friction. The wind off the street pushes light litter on to the south
# wall, where it comes to rest just above the gutter.
func _roll(mover: Dictionary, delta: float, friction: float, wind: float) -> Vector2:
	var velocity: Vector2 = mover.get("velocity", (BOWL - mover.from).normalized() * 4.0)
	var gradient := _slope(mover.at)
	velocity -= gradient * 9.8 / (1.0 + gradient.length_squared()) * delta
	velocity.y += wind * delta
	velocity *= exp(-delta * friction)
	mover["velocity"] = velocity
	return mover.at + velocity * delta

# Skaters on foot walk in along the service lane and head for a spot on the south plaza.
func _walk(mover: Dictionary, delta: float) -> Vector2:
	var goal := Vector2(lerpf(-18.0, 26.0, mover.seed), 22.0 + 3.0 * sin(mover.seed * 17.0))
	var step: Vector2 = (goal - mover.at).limit_length(1.8 * delta)
	return mover.at + step + step.orthogonal() * sin(mover.age * 6.0) * 0.15

# Service vehicles drive west along the lane to the west lip, turn, and drive back to park in the
# first free bay by the gate until their work is done.
func _drive(mover: Dictionary, delta: float) -> Vector2:
	if mover.at.x <= LANE_END + 0.5 and not mover.has("bay"):
		var bay := _parked.find_custom(func(vehicle: Food) -> bool: return vehicle == null or not vehicle.active)
		_parked[bay] = mover.food
		mover["bay"] = PARKING[bay]
	var goal: Vector2 = mover.get("bay", Vector2(LANE_END, mover.from.y))
	return mover.at + (goal - mover.at).limit_length(3.5 * delta)

func _slope(at: Vector2) -> Vector2:
	var point := Vector3(at.x, 0.0, at.y)
	return Vector2(ground_height(point + Vector3(0.1, 0, 0)) - ground_height(point - Vector3(0.1, 0, 0)),
		ground_height(point + Vector3(0, 0, 0.1)) - ground_height(point - Vector3(0, 0, 0.1))) / 0.2

func _build_street() -> void:
	_street = Node3D.new()
	_street.name = "The street beyond the park fence"
	_world.add_child(_street)
	var road := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(150, 0.18, 18)
	road.mesh = slab
	road.material_override = _concrete_material(Color("515963"))
	road.position = Vector3(2, -0.15, -59)
	_street.add_child(road)
	for row in PARKED_CARS:
		var car := Art.model("parked_car", row[2])
		_street.add_child(car)
		car.position = Vector3(row[0].x, 0.0, row[0].y)
		car.rotation.y = deg_to_rad(row[1])
	for row in STREET_TREES:
		var tree := Art.model("tree", row[2])
		_street.add_child(tree)
		tree.position = Vector3(row[0].x, -0.1, row[0].y)
		tree.rotation.y = deg_to_rad(row[1])
	# The park fence: a straight run along the street and down each side, with the gate in the
	# east run where the service lane meets it.
	for index in range(17):
		_fence(Vector3(-46.0 + index * 6.0, 0, -47.0), 0.0)
	for index in range(15):
		var z := -41.0 + index * 6.0
		_fence(Vector3(-48.0, 0, z), PI * 0.5)
		if absf(z - 20.0) > 5.0:
			_fence(Vector3(52.0, 0, z), PI * 0.5)

func _fence(at: Vector3, turn: float) -> void:
	var fence := Art.model("fence_section", 3.1)
	_street.add_child(fence)
	fence.position = at
	fence.rotation.y = turn

func _concrete_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = load("res://assets/models/ground_concrete.png")
	material.uv1_scale = Vector3(6, 6, 6)
	material.roughness = 0.9
	return material

func step(delta: float) -> void:
	_time += delta
	for item in _boards:
		_step_board(item, delta)
	for item in _riders:
		_step_rider(item)
	# A runaway board rides flat on the bowl's curved walls, as a placed board does.
	for mover in _runaways.movers:
		if mover.food.active:
			_align_to_ground(mover.food)

func _step_rider(item: Dictionary) -> void:
	var rider: Food = item.food
	var board: Food = item.board
	if not rider.active or not board.active or board.get_meta("lost_wheel", false):
		return
	var phase: float = item.phase + _time * item.pace
	var radius: float = item.radius + (sin(phase * 2.0 + item.sway) - sin(item.phase * 2.0 + item.sway)) * 1.1
	var at: Vector2 = BOWL + Vector2(cos(phase) * STRETCH, sin(phase)) * radius
	var movement := Vector2(at.x - rider.position.x, at.y - rider.position.z)
	rider.position = Vector3(at.x, ground_height(Vector3(at.x, 0, at.y)), at.y)
	if movement.length_squared() > 0.0000001:
		rider.rotation.y = atan2(-movement.y, movement.x)
	else:
		rider.rotation.y = atan2(-cos(phase), -sin(phase) * STRETCH)
	_align_to_ground(rider)

func _step_board(item: Dictionary, delta: float) -> void:
	var board: Food = item.food
	if not board.active:
		return
	var at := board.position
	var gradient := _slope(Vector2(at.x, at.z))
	var velocity: Vector2 = item.velocity
	velocity -= gradient * 9.8 / (1.0 + gradient.length_squared()) * delta
	velocity *= exp(-delta * (2.8 if board.get_meta("lost_wheel", false) else 0.08))
	var position := Vector2(at.x, at.z) + velocity * delta
	position = position.clamp(_world.field.position + Vector2.ONE * 2, _world.field.end - Vector2.ONE * 2)
	board.position = Vector3(position.x, 0, position.y)
	board.position.y = ground_height(board.position) + 0.015
	if velocity.length_squared() > 0.0001:
		board.rotation.y = atan2(-velocity.y, velocity.x)
		if not board.get_meta("lost_wheel", false):
			_align_to_ground(board)
			for part in board.parts:
				if part.active and part.model_name == "wheel":
					part.visual.rotation.z -= velocity.length() / part.radius * delta
					var axle := Vector3.UP * float(Art.manifest().wheel.height) * 0.5
					part.visual.position = Vector3.UP * part.height * 0.5 - part.visual.basis * axle
	item.velocity = velocity

func _align_to_ground(food: Food) -> void:
	var at := food.global_position
	var dx := ground_height(at + Vector3(0.1, 0, 0)) - ground_height(at - Vector3(0.1, 0, 0))
	var dz := ground_height(at + Vector3(0, 0, 0.1)) - ground_height(at - Vector3(0, 0, 0.1))
	var up := Vector3(-dx, 0.2, -dz).normalized()
	var forward := Vector3(cos(food.rotation.y), 0, -sin(food.rotation.y))
	var side := forward.cross(up).normalized()
	food.basis = Basis(up.cross(side).normalized(), up, side)
