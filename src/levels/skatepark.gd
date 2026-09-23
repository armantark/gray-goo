extends RefCounted

# One concrete skate bowl in a small city park. The bowl sits east of center; the wind off the
# street to the north blows litter over its north coping, and the litter rolls down and gathers
# in the south gutter. Riders carve laps on its walls. The park's big vert quarter pipe stands on
# the bowl's west lip, where skaters drop in, with spectator benches, gear piles, and shade trees
# on the decks and the lawn behind it. A street course fills the south plaza: practice cones
# knocked out of their slalom line, three grind rails, and two quarter pipes facing each other.
# Pipes and rails back onto the north fence. Skaters and the park's service vehicles come in
# through the gate in the east fence.
const BOWL := Vector2(14.0, -4.0)
# The bowl is an ellipse this many times wider east to west than north to south.
const STRETCH := 1.2
const FLOOR_RADIUS := 9.0
const COPING_RADIUS := 19.0
const DEPTH := 2.6
# The north coping, where wind-blown litter tops the rim, and the deck beside the vert pipe, where
# a skater's bail sends the board rolling into the bowl, out of view while the goo is in the bowl.
const NORTH_COPING := [Vector2(2.6, -20.5), Vector2(25.4, -20.5)]
# The north fence, where the same wind blows litter through on to the lawn and the north deck.
const NORTH_FENCE := [Vector2(-40.0, -44.0), Vector2(40.0, -44.0)]
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
	# More litter the wind dropped over the north coping, still on the north wall, and pieces that
	# rolled on across the floor and up the east and west walls before settling.
	["cap", Vector2(11.2, -15.8), 80, 0.19],
	["pebble", Vector2(12.6, -17.4), 0, 0.15],
	["bolt", Vector2(8.3, -13.9), 215, 0.14],
	["cap", Vector2(19.4, -16.3), 330, 0.2],
	["pebble", Vector2(22.1, -14.9), 40, 0.17],
	["bearing", Vector2(16.9, -14.3), 0, 0.15],
	["cap", Vector2(6.1, -10.2), 150, 0.18],
	["pebble", Vector2(3.1, -8.7), 290, 0.16],
	["bolt", Vector2(2.4, -2.2), 65, 0.13],
	["cap", Vector2(3.8, 0.6), 10, 0.17],
	["pebble", Vector2(10.7, 5.2), 180, 0.17],
	["bearing", Vector2(12.4, 4.1), 0, 0.14],
	["cap", Vector2(13.9, 5.6), 275, 0.2],
	["bolt", Vector2(21.6, 4.9), 120, 0.15],
	["pebble", Vector2(23.9, 3.2), 95, 0.14],
	["cap", Vector2(25.7, 0.3), 45, 0.18],
	["bearing", Vector2(26.8, -3.5), 0, 0.16],
	["bolt", Vector2(25.3, -7.8), 300, 0.14],
	["pebble", Vector2(24.4, -10.1), 205, 0.16],
	["cap", Vector2(29.5, -9.2), 160, 0.19],
	["pebble", Vector2(30.6, 2.8), 25, 0.15],
	["bolt", Vector2(-1.6, -6.4), 250, 0.14],
	["cap", Vector2(-3.3, -10.9), 115, 0.18],
	["pebble", Vector2(14.9, -9.1), 330, 0.15],
	["cap", Vector2(18.3, -7.7), 195, 0.18],
	["bolt", Vector2(10.3, -1.5), 85, 0.13],
	["cap", Vector2(7.2, -17.9), 250, 0.17],
	["pebble", Vector2(15.8, -19.6), 70, 0.16],
	["bolt", Vector2(24.2, -17.8), 5, 0.15],
	["cap", Vector2(31.9, -6.1), 225, 0.18],
	["pebble", Vector2(33.2, -1.4), 140, 0.15],
	["bearing", Vector2(28.6, 6.9), 0, 0.15],
	["cap", Vector2(18.9, 10.6), 310, 0.19],
	["bolt", Vector2(7.9, 9.4), 175, 0.14],
	["pebble", Vector2(-4.6, 1.9), 35, 0.16],
	["cap", Vector2(-6.1, -4.8), 100, 0.18],
	["bearing", Vector2(0.2, -14.4), 0, 0.14],
	["bolt", Vector2(19.6, -11.9), 265, 0.13],
	["cap", Vector2(9.1, -8.3), 35, 0.17],
	["pebble", Vector2(16.4, -3.1), 200, 0.15],
	["bolt", Vector2(20.7, -5.2), 110, 0.14],
	["cap", Vector2(5.3, -6.9), 285, 0.18],
	["bearing", Vector2(22.9, -9.6), 0, 0.15],
	["pebble", Vector2(27.4, -10.8), 15, 0.16],
	["cap", Vector2(29.9, -1.1), 160, 0.17],
	["bolt", Vector2(24.6, 7.8), 240, 0.14],
	["pebble", Vector2(15.1, 9.8), 300, 0.16],
	["cap", Vector2(9.8, 7.9), 75, 0.19],
	["bearing", Vector2(2.1, 6.4), 0, 0.15],
	["bolt", Vector2(-2.8, -1.3), 185, 0.13],
	["cap", Vector2(0.9, -11.8), 220, 0.18],
	["pebble", Vector2(4.4, -16.1), 55, 0.16],
	["cap", Vector2(13.1, -12.7), 330, 0.17],
	["bolt", Vector2(18.2, -13.6), 20, 0.14],
	["pebble", Vector2(31.4, -13.2), 265, 0.15],
	["cap", Vector2(34.2, 4.2), 140, 0.18],
	# A second board on the floor, and more riders, the older ones bigger, on laps of their own.
	["board", Vector2(21.4, -1.8), 115, 1.2],
	["rider", Vector2(30.8, -2.2), 60, 1.45],
	["rider", Vector2(9.6, -15.2), 170, 1.5],
	["rider", Vector2(-0.9, -1.1), 330, 1.65],
	["rider", Vector2(27.9, 6.8), 250, 1.75],
	["rider", Vector2(6.4, 11.2), 140, 1.85],
	# The deck north of the vert pipe: a spectator bench turned to the bowl, its trash can, and a
	# rider's gear pile and board in front of it, with caps dropped around the bench.
	["bench", Vector2(-10.0, -20.0), 65, 2.1],
	["trash_can", Vector2(-16.0, -23.0), 0, 1.0],
	["helmet", Vector2(-6.5, -18.6), 40, 0.7],
	["shoe", Vector2(-4.8, -16.7), 300, 0.6],
	["water_bottle", Vector2(-7.6, -16.2), 0, 0.5],
	["board", Vector2(-3.5, -20.8), 150, 1.25],
	["dropped_cap", Vector2(-12.9, -17.4), 20, 0.18],
	["dropped_cap", Vector2(-14.6, -19.8), 245, 0.2],
	["dropped_cap", Vector2(-6.1, -22.7), 130, 0.18],
	["helmet", Vector2(-18.2, -15.6), 190, 0.65],
	# The deck south of it, where a bench sits closer to the coping and a rider dumped a board by
	# the pipe on the way in.
	["bench", Vector2(-7.2, 13.8), 130, 1.9],
	["trash_can", Vector2(-13.1, 17.9), 0, 1.1],
	["shoe", Vector2(-3.9, 10.1), 290, 0.55],
	["helmet", Vector2(-1.6, 12.9), 210, 0.75],
	["water_bottle", Vector2(-9.6, 18.4), 0, 0.5],
	["board", Vector2(-11.6, 9.3), 55, 1.15],
	["dropped_cap", Vector2(-5.4, 17.2), 170, 0.17],
	["shoe", Vector2(-21.3, 12.6), 65, 0.6],
	# The shaded lawn behind the vert pipe: three trees, benches under them, cans, and gear and
	# boards left on the grass.
	["tree", Vector2(-36.0, -28.0), 40, 4.4],
	["tree", Vector2(-40.2, -7.5), 300, 4.6],
	["tree", Vector2(-37.0, 8.0), 160, 4.2],
	["bench", Vector2(-26.4, -21.7), 75, 2.0],
	["trash_can", Vector2(-29.8, -14.9), 0, 1.0],
	["dropped_cap", Vector2(-22.4, -24.9), 15, 0.18],
	["dropped_cap", Vector2(-27.8, -18.1), 280, 0.17],
	["bench", Vector2(-25.8, 4.6), 105, 1.8],
	["trash_can", Vector2(-26.9, -4.6), 0, 1.4],
	["helmet", Vector2(-31.6, -3.2), 45, 0.7],
	["board", Vector2(-31.8, 15.8), 200, 1.3],
	["shoe", Vector2(-33.8, -15.2), 140, 0.65],
	["helmet", Vector2(-22.8, -27.6), 355, 0.65],
	["board", Vector2(-20.9, -31.3), 250, 1.3],
	["board", Vector2(-41.0, -19.4), 20, 1.3],
	["bench", Vector2(-30.2, 24.5), 105, 2.4],
	["dropped_cap", Vector2(-33.4, 27.6), 90, 0.18],
	["trash_can", Vector2(-35.4, 21.9), 0, 1.2],
	["water_bottle", Vector2(-25.1, 27.9), 0, 0.5],
	["helmet", Vector2(-26.9, 29.6), 120, 0.7],
	["water_bottle", Vector2(-38.6, 19.3), 0, 0.55],
	["dropped_cap", Vector2(-31.8, 20.9), 60, 0.19],
	# The north fence: a small quarter pipe in the lawn's corner, a low ledge rail, two quarter pipes
	# facing the bowl with a flat rail and a bench between them, and boards and gear dropped on the
	# way in. A bench and its can look over the north coping.
	["pipe", Vector2(-39.5, -39.8), 30, 2.9],
	["rail", Vector2(-26.0, -38.5), 350, 2.4],
	["bench", Vector2(0.6, -38.8), 10, 1.8],
	["trash_can", Vector2(6.8, -40.9), 0, 1.15],
	["board", Vector2(13.6, -40.3), 290, 1.25],
	["bench", Vector2(15.6, -26.3), 160, 1.8],
	["trash_can", Vector2(8.4, -25.6), 0, 1.35],
	["rail", Vector2(27.6, -26.6), 25, 2.2],
	["water_bottle", Vector2(6.1, -28.6), 0, 0.5],
	["helmet", Vector2(26.4, -31.6), 250, 0.7],
	["pipe", Vector2(-9.5, -36.5), 270, 3.3],
	["rail", Vector2(10.5, -33.2), 12, 3.0],
	["pipe", Vector2(29.8, -37.2), 255, 3.7],
	["board", Vector2(-1.5, -30.0), 200, 1.25],
	["board", Vector2(21.2, -29.1), 340, 1.2],
	["shoe", Vector2(-14.1, -29.4), 110, 0.6],
	["helmet", Vector2(3.1, -35.4), 30, 0.7],
	["water_bottle", Vector2(37.9, -30.8), 0, 0.5],
	# The north-east corner: a quarter pipe angled at the bowl under a shade tree.
	["pipe", Vector2(39.8, -26.4), 200, 3.2],
	["tree", Vector2(43.6, -39.2), 70, 4.3],
	# The east deck by the gate: one bench looking west over the bowl, its can, and a rider's
	# scattered gear.
	["bench", Vector2(42.1, -9.3), 260, 2.3],
	["dropped_cap", Vector2(45.9, -11.6), 55, 0.18],
	["dropped_cap", Vector2(38.4, -10.9), 195, 0.17],
	["shoe", Vector2(33.1, -17.6), 320, 0.6],
	["trash_can", Vector2(44.8, -16.4), 0, 1.05],
	["shoe", Vector2(39.6, -6.5), 150, 0.6],
	["helmet", Vector2(36.9, -13.8), 85, 0.7],
	["board", Vector2(46.4, -3.2), 95, 1.2],
	["water_bottle", Vector2(40.8, -19.9), 0, 0.5],
	# The south plaza's street course, south of the service lane: practice cones knocked out of
	# their slalom line, three grind rails at easy angles, two quarter pipes facing each other, and
	# benches, cans, and trees along the far edge.
	["cone", Vector2(-17.6, 25.3), 0, 0.85],
	["cone", Vector2(-9.3, 27.1), 0, 0.9],
	["cone", Vector2(-2.1, 29.6), 0, 0.85],
	["cone", Vector2(4.6, 26.4), 0, 0.95],
	["cone", Vector2(6.9, 31.8), 0, 0.8],
	["cone", Vector2(13.8, 28.9), 0, 0.9],
	["cone", Vector2(19.4, 25.8), 0, 1.0],
	["cone", Vector2(-12.8, 34.9), 0, 0.9],
	["cone", Vector2(10.8, 24.2), 0, 0.85],
	["cone", Vector2(25.6, 30.7), 0, 0.95],
	["board", Vector2(-21.4, 22.2), 140, 1.2],
	["board", Vector2(29.4, 24.6), 30, 1.2],
	["shoe", Vector2(-2.8, 24.1), 160, 0.55],
	["water_bottle", Vector2(22.9, 28.4), 0, 0.5],
	["rail", Vector2(-23.4, 31.9), 18, 2.6],
	["rail", Vector2(-1.2, 39.4), 356, 3.2],
	["rail", Vector2(18.3, 33.6), 334, 2.9],
	["pipe", Vector2(-35.6, 31.2), 15, 3.4],
	["pipe", Vector2(40.5, 28.8), 190, 3.5],
	["board", Vector2(-13.2, 30.8), 80, 1.25],
	["bench", Vector2(-11.4, 43.1), 175, 2.0],
	["trash_can", Vector2(-3.2, 44.6), 0, 1.0],
	["bench", Vector2(15.3, 41.2), 190, 2.1],
	["trash_can", Vector2(24.8, 40.9), 0, 1.1],
	["bench", Vector2(31.2, 35.8), 215, 1.9],
	["helmet", Vector2(9.6, 38.7), 300, 0.7],
	["shoe", Vector2(18.9, 38.7), 20, 0.6],
	["water_bottle", Vector2(-15.8, 40.4), 0, 0.5],
	["shoe", Vector2(-7.6, 45.1), 235, 0.6],
	["dropped_cap", Vector2(2.3, 42.1), 100, 0.18],
	["dropped_cap", Vector2(-18.7, 37.6), 310, 0.17],
	["dropped_cap", Vector2(27.9, 38.4), 205, 0.19],
	["dropped_cap", Vector2(12.1, 44.9), 35, 0.18],
	["dropped_cap", Vector2(-9.2, 40.1), 250, 0.17],
	["dropped_cap", Vector2(17.9, 44.6), 140, 0.2],
	["tree", Vector2(-26.8, 43.2), 130, 4.0],
	["tree", Vector2(34.8, 42.6), 250, 4.2],
	# Grit the service carts track in from the street, strewn along the lane south of the bowl.
	["grit", Vector2(-1.4, 19.9), 40, 0.16],
	["grit", Vector2(2.7, 22.3), 190, 0.15],
	["grit", Vector2(6.2, 17.8), 305, 0.18],
	["grit", Vector2(11.9, 19.6), 90, 0.16],
	["grit", Vector2(14.6, 21.9), 230, 0.17],
	["grit", Vector2(17.4, 16.9), 10, 0.15],
	["grit", Vector2(23.8, 18.4), 145, 0.18],
	["grit", Vector2(28.6, 20.7), 275, 0.16],
	["grit", Vector2(33.9, 17.1), 60, 0.17],
	# A busy day's leftovers across the park: boards dropped between runs, gear kicked off, and caps.
	["board", Vector2(4.2, -21.6), 310, 1.2],
	["board", Vector2(-6.8, -25.4), 45, 1.25],
	["board", Vector2(-20.6, -12.1), 165, 1.2],
	["board", Vector2(-35.0, -19.0), 280, 1.25],
	["board", Vector2(-18.9, 14.6), 20, 1.25],
	["board", Vector2(33.0, -21.0), 120, 1.2],
	["board", Vector2(45.0, -31.0), 235, 1.15],
	["board", Vector2(3.1, 32.9), 95, 1.2],
	["board", Vector2(11.6, 34.4), 350, 1.2],
	["board", Vector2(-35.2, 41.3), 60, 1.15],
	["cone", Vector2(-7.4, 33.8), 0, 0.9],
	["cone", Vector2(23.4, 22.9), 0, 0.85],
	["cone", Vector2(-17.2, 30.6), 0, 0.95],
	["helmet", Vector2(-12.4, -26.8), 150, 0.7],
	["shoe", Vector2(11.9, -29.6), 75, 0.6],
	["water_bottle", Vector2(30.8, -15.4), 0, 0.5],
	["helmet", Vector2(-23.9, 17.6), 260, 0.65],
	["shoe", Vector2(-39.2, -1.6), 305, 0.6],
	["water_bottle", Vector2(27.8, 34.3), 0, 0.5],
	["helmet", Vector2(-5.8, 36.1), 20, 0.7],
	["shoe", Vector2(37.1, -3.1), 190, 0.55],
	["water_bottle", Vector2(-1.9, -33.4), 0, 0.5],
	["helmet", Vector2(20.4, -23.5), 95, 0.65],
	["dropped_cap", Vector2(-33.1, -10.8), 120, 0.18],
	["dropped_cap", Vector2(-19.7, -35.2), 40, 0.17],
	["dropped_cap", Vector2(38.9, -3.4), 290, 0.18],
	["dropped_cap", Vector2(19.8, 40.4), 175, 0.17],
	["dropped_cap", Vector2(-14.3, 46.1), 65, 0.18],
	["dropped_cap", Vector2(0.8, 26.9), 230, 0.17],
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
var _detail_tier := 0
# The one-piece skateboard model's texture with its red deck repainted in the placed boards' deck color.
var _deck_texture: Texture2D

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
			{"radius": 3.0, "view_size": 53.0}],
		"growth_scale": 0.19}

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
	_paint_deck()
	_build_street()
	var litter := "Wind off the street blows litter over the north coping, and it rolls down into the bowl's gutter."
	var hardware := "Hardware shaken loose from riders' trucks rolls down into the bowl's gutter."
	var gear := "Skaters leave their gear by the benches before they ride."
	var kinds := {
		"big_pipe": {"model": "ramp", "label": "Big vert quarter pipe", "tier": 4, "density": 0.336, "whole": _bowl,
			"reason": "The park's biggest quarter pipe stands on the bowl's west lip, where skaters drop in.",
			"fit": 1.25, "build": func(pipe: Food) -> void: pipe.milestone = true},
		"cap": {"model": "bottle_cap", "label": "Bottle cap", "tier": 0, "density": 0.94, "whole": _bowl, "reason": litter},
		"pebble": {"model": "pebble", "label": "Pebble", "tier": 0, "density": 0.94, "whole": _bowl, "reason": litter},
		"bolt": {"model": "bolt", "label": "Bolt", "tier": 0, "density": 0.94, "whole": _bowl, "reason": hardware},
		"bearing": {"model": "bearing", "label": "Bearing", "tier": 0, "density": 0.94, "whole": _bowl, "reason": hardware},
		"grit": {"model": "pebble", "label": "Pebble", "tier": 0, "density": 0.94, "whole": _bowl,
			"reason": "The service carts track grit in from the street along the lane."},
		"dropped_cap": {"model": "bottle_cap", "label": "Bottle cap", "tier": 0, "density": 0.94, "whole": _bowl,
			"reason": "Spectators drop bottle caps around the benches."},
		"board": {"label": "Skateboard", "tier": 1, "density": 0.01, "whole": _bowl,
			"reason": "A rider left this board while resting.", "build": _loose_board},
		"rider": {"label": "Skater", "tier": 2, "density": 0.139, "whole": _bowl,
			"reason": "This skater carves laps on the bowl's walls.", "build": _rider},
		"helmet": {"model": "helmet", "label": "Helmet", "tier": 1, "density": 0.083, "whole": _bowl, "reason": gear},
		"shoe": {"model": "shoe", "label": "Shoe", "tier": 1, "density": 0.083, "whole": _bowl, "reason": gear},
		"water_bottle": {"model": "water_bottle", "label": "Water bottle", "tier": 1, "density": 0.083, "whole": _bowl, "reason": gear},
		"cone": {"model": "cone", "label": "Practice cone", "tier": 1, "density": 0.035, "whole": _bowl,
			"reason": "The cones mark a slalom line across the plaza.", "fit": 1.362},
		"bench": {"model": "bench", "label": "Park bench", "tier": 2, "density": 0.347, "whole": _bowl,
			"reason": "Benches face the bowl and the street course for spectators."},
		"trash_can": {"model": "trash_can", "label": "Park trash can", "tier": 2, "density": 0.127, "whole": _bowl,
			"reason": "Each trash can stands by a bench."},
		"rail": {"label": "Grind rail", "tier": 3, "density": 0.098, "whole": _bowl,
			"reason": "The grind rail belongs to the park's street course.", "build": _rail},
		"pipe": {"model": "ramp", "label": "Quarter pipe", "tier": 3, "density": 0.313, "whole": _bowl,
			"reason": "Quarter pipes face each other across the street course and line the north fence.", "fit": 1.25},
		"tree": {"model": "tree", "label": "Shade tree", "tier": 4, "density": 0.336, "whole": _bowl,
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
	var deck := _world._add_food("board", Vector2.ZERO, 1.15 * scale, 0.065 * pow(1.15 * scale, 3.0), "Skate deck", false, 1, board, 0.22 * scale)
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
		"from": NORTH_COPING, "sizes": Vector2(0.16, 0.24),
		"tiers": Vector2i(0, 1), "rate": 1.4, "limit": 8, "lifetime": 35.0, "move": _roll.bind(0.5, 0.6)})
	_world.spawn({"kind": {"model": "bottle_cap", "label": "Blown bottle cap", "tier": 0, "density": 0.5,
			"whole": _bowl, "reason": "Wind off the street blows litter through the north fence."},
		"from": NORTH_FENCE, "sizes": Vector2(0.16, 0.24),
		"tiers": Vector2i(0, 1), "rate": 0.4, "limit": 4, "lifetime": 35.0, "move": _roll.bind(0.5, 0.6)})
	_runaways = {"kind": {"model": "skateboard", "label": "Runaway skateboard", "tier": 1, "density": 0.1,
			"whole": _bowl, "reason": "A skater bails on the deck beside the vert pipe, and the board rolls away into the bowl."},
		"from": WEST_DECK, "sizes": Vector2(0.8, 1.05), "tiers": Vector2i(1, 3),
		"rate": 0.7, "limit": 4, "lifetime": 35.0, "move": _roll.bind(0.12, 0.0)}
	_world.spawn(_runaways)
	_world.spawn({"kind": {"model": "skater", "label": "Skater on foot", "tier": 2, "density": 0.11,
			"whole": _bowl, "reason": "Skaters walk in through the east gate to ride the park."},
		"from": GATE, "sizes": Vector2(1.45, 1.7), "tiers": Vector2i(2, 4),
		"rate": 0.8, "limit": 8, "lifetime": 40.0, "move": _walk})
	_world.spawn({"kind": {"model": "parked_car", "label": "Park service cart", "tier": 3, "density": 0.07,
			"whole": _street, "reason": "The park's service cart drives in through the east gate to empty the trash cans."},
		"from": GATE, "sizes": Vector2(2.3, 2.7), "tiers": Vector2i(3, 4),
		"rate": 0.25, "limit": 2, "lifetime": 40.0, "move": _drive})
	_world.spawn({"kind": {"model": "parked_car", "label": "Park maintenance truck", "tier": 4, "density": 0.1,
			"whole": _street, "reason": "The maintenance truck drives in through the east gate to work on the ramps."},
		"from": GATE, "sizes": Vector2(3.0, 3.5), "tiers": Vector2i(4, 4),
		"rate": 0.2, "limit": 2, "lifetime": 40.0, "move": _drive})

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
	if _detail_tier != _world.current_tier:
		_detail_tier = _world.current_tier
		for item in _boards:
			_one_piece(item.food)
		for item in _riders:
			_one_piece(item.board)
	for item in _boards:
		_step_board(item, delta)
	for item in _riders:
		_step_rider(item)
	# A runaway board rides flat on the bowl's curved walls, as a placed board does.
	for mover in _runaways.movers:
		if mover.food.active:
			_align_to_ground(mover.food)

# Once a board's trucks are specks, an untouched board draws as one skateboard and goes down in one
# bite: its parts leave the level and their volume moves to the board. A board already missing a
# part keeps drawing what is left of it.
func _one_piece(board: Food) -> void:
	var truck: Food = board.parts[1]
	if not board.active or board.simple or not _world.is_simple(truck.radius) \
			or board.parts.any(func(part: Food) -> bool: return not part.active):
		return
	board.volume = board.remaining_volume()
	for part in board.parts:
		_world._retire(part)
	board.collect_when_empty = false
	board.simplify("skateboard")
	for mesh: MeshInstance3D in board.visual.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			mesh.set_surface_override_material(surface, Art.material(Color.WHITE, 0.0, _deck_texture))

# The skateboard model paints its deck red and a placed board's deck is teal, so the one-piece form
# repaints the red, keeping its shading, and the board keeps its color across the jump. Built once
# with the level, so the jump does not stall on it.
func _paint_deck() -> void:
	var model := Art.model("skateboard", 1.0)
	var mesh: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
	var image: Image = (mesh.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture.get_image()
	model.free()
	image.decompress()
	var red := Art.food_color("skateboard")
	var deck := Art.food_color("board")
	for y in image.get_height():
		for x in image.get_width():
			var texel := image.get_pixel(x, y)
			if absf(texel.r - red.r) + absf(texel.g - red.g) + absf(texel.b - red.b) < 0.3:
				image.set_pixel(x, y, deck * (texel.get_luminance() / red.get_luminance()))
	_deck_texture = ImageTexture.create_from_image(image)

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
