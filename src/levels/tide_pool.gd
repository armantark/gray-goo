extends RefCounted

# One rock pool at low tide. The Great coral crown stands on a reef in the deep end, and its
# colony of coral heads rings the reef where the goo starts. Waves top the low south-east rim at
# the spill, and the current they drive carries plankton across the open floor and around the
# reef. Pool animals keep to the rocks and sand of the south half; the rim is a cliff of big
# boulders behind the deep end and a low, broken wall on the beach side.
const BASIN := Vector2(58.5, 51.0)
const REEF := Vector2(6.0, -26.0)
# Angle of the spill in the basin's ellipse coordinates, where the rim dips.
const SPILL_ANGLE := 0.9
const SPILL := [Vector2(27.5, 34.0), Vector2(33.0, 30.0)]
const SHELTER := Vector2(-27.0, 12.0)
# The overhang's open side, where the fry hatch.
const NURSERY := Vector2(-26.1, 14.3)
# Coral growth forms, one branch per entry: [outward angle, distance per head size, twist],
# angles in degrees. A head is a squat cross, a bush branches all round, and a spray fans one way.
const HEAD := [[25.0, 0.64, 10.0], [110.0, 0.58, -30.0], [170.0, 0.65, 25.0], [275.0, 0.6, -10.0]]
const BUSH := [[10.0, 0.65, 20.0], [80.0, 0.58, -15.0], [150.0, 0.64, 30.0], [215.0, 0.56, 0.0], [290.0, 0.65, -25.0]]
const SPRAY := [[-50.0, 0.65, 15.0], [-5.0, 0.6, -10.0], [40.0, 0.64, 20.0]]

# [kind, at, turn in degrees, size]
const PLACED := [
	# The milestone, on its reef in the deep end, a few body lengths above the start.
	["crown", Vector2(6.0, -26.0), 12, 4.4],
	# The colony rings the reef on the deep end's lip. Four heads close around the start, a pair
	# and then single heads spaced out along the lip, and an older patch against the west wall.
	["coral_bush", Vector2(-6.5, -20.0), 20, 2.1],
	["coral_head", Vector2(-10.5, -15.0), 75, 1.8],
	["coral_spray", Vector2(-2.5, -9.5), 200, 1.7],
	["coral_head", Vector2(3.5, -13.0), 310, 1.9],
	["coral_bush", Vector2(13.0, -15.0), 45, 2.2],
	["coral_spray", Vector2(19.0, -20.5), 160, 1.8],
	["coral_head", Vector2(27.0, -30.0), 115, 1.8],
	["coral_head", Vector2(18.0, -38.0), 15, 2.0],
	["coral_head", Vector2(-15.0, -24.0), 140, 1.9],
	["coral_spray", Vector2(-14.0, -32.0), 250, 1.8],
	["coral_bush", Vector2(-4.0, -38.0), 95, 1.9],
	["coral_spray", Vector2(-39.0, -6.0), 330, 1.7],
	["coral_bush", Vector2(-35.0, 2.5), 60, 2.0],
	# Snails graze a trail along the west waterline and the algae at the colony's edge.
	["snail", Vector2(-47.0, -12.0), 95, 1.0],
	["snail", Vector2(-48.5, -4.0), 80, 1.1],
	["snail", Vector2(-47.0, 4.5), 100, 0.9],
	["snail", Vector2(-44.0, 12.0), 70, 1.2],
	["snail", Vector2(-11.0, -9.5), 210, 0.9],
	["snail", Vector2(9.0, -9.5), 20, 1.0],
	["snail", Vector2(-19.5, -28.5), 300, 1.1],
	["snail", Vector2(23.0, -15.5), 150, 0.9],
	# The fish shelter: an overhang on two rock feet, with its fish beneath and two hermit
	# crabs picking over the scraps beside it. A third crab works the open sand.
	["shelter", SHELTER, 20, 3.6],
	["fish", SHELTER, 20, 1.7],
	["hermit_crab", Vector2(-17.0, 17.0), 30, 2.2],
	["hermit_crab", Vector2(-22.0, 21.5), 200, 2.1],
	["hermit_crab", Vector2(12.0, 20.0), 290, 2.3],
	# Boulders in the pool, each with an anemone on its sunny side. Sea stars creep over the open
	# shelf between them, well clear of every rock: a star against a rock makes a corner that traps the goo.
	["anemone_rock", Vector2(33.0, -2.0), 30, 3.1],
	["anemone_rock", Vector2(38.0, -15.0), 110, 2.7],
	["anemone_rock", Vector2(-30.0, 26.0), 220, 3.0],
	["anemone_rock", Vector2(-9.0, 36.0), 300, 2.6],
	["sea_star", Vector2(26.0, -10.0), 10, 1.9],
	["sea_star", Vector2(44.5, 3.0), 70, 2.1],
	["sea_star", Vector2(-21.0, 31.0), 150, 1.8],
	["sea_star", Vector2(-40.0, 17.0), 100, 2.0],
	# Anemones spaced along the spill's inner lip, each claiming its own share of the wash. The gaps
	# are wider than the goo that still cannot eat them: a narrow gap or an overlap is a trap.
	["anemone", Vector2(19.0, 28.0), 0, 1.5],
	["anemone", Vector2(25.5, 23.0), 60, 1.4],
	["anemone", Vector2(31.5, 20.5), 80, 1.6],
	["anemone", Vector2(-40.0, -16.5), 10, 1.6],
	# The rim: an unbroken cliff of big boulders behind the deep end, a pair and a single on
	# each side wall, two big ones flanking the spill, and two low ones on the beach side.
	["rim_boulder", Vector2(-33.5, -37.4), 40, 3.2],
	["rim_boulder", Vector2(-26.4, -41.5), 170, 3.9],
	["rim_boulder", Vector2(-18.6, -44.5), 250, 4.3],
	["anemone_rim", Vector2(-10.4, -46.5), 10, 3.6],
	["rim_boulder", Vector2(-1.9, -47.4), 300, 4.4],
	["rim_boulder", Vector2(6.6, -47.0), 130, 3.8],
	["anemone_rim", Vector2(15.0, -45.6), 80, 4.2],
	["rim_boulder", Vector2(23.0, -43.0), 200, 3.5],
	["rim_boulder", Vector2(30.4, -39.3), 330, 2.9],
	["rim_boulder", Vector2(-52.0, -13.9), 60, 3.3],
	["rim_boulder", Vector2(-53.7, -7.4), 290, 2.6],
	["anemone_rim", Vector2(-53.9, 6.6), 180, 3.2],
	["rim_boulder", Vector2(-48.0, 22.3), 20, 2.5],
	["rim_boulder", Vector2(48.0, -22.3), 230, 3.4],
	["rim_boulder", Vector2(50.5, -16.5), 110, 2.7],
	["anemone_rim", Vector2(53.9, 6.6), 280, 3.1],
	["rim_boulder", Vector2(51.1, 16.2), 150, 2.4],
	["rim_boulder", Vector2(42.9, 29.2), 20, 4.0],
	["rim_boulder", Vector2(22.1, 43.3), 230, 3.7],
	["rim_boulder", Vector2(-11.3, 46.4), 110, 2.4],
	["rim_boulder", Vector2(-38.5, 33.5), 280, 2.9],
]

# Scree fallen from the cliff behind the deep end and from the west pair: scenery only,
# [at, turn in degrees, size].
const SHINGLE := [
	[Vector2(-28.0, -50.0), 30, 1.3], [Vector2(-21.5, -52.5), 120, 1.0], [Vector2(-8.0, -54.5), 200, 1.4],
	[Vector2(4.5, -55.0), 70, 1.1], [Vector2(9.0, -54.0), 10, 0.8], [Vector2(21.0, -51.5), 160, 1.2],
	[Vector2(-59.0, -10.5), 250, 1.0], [Vector2(-60.0, -4.0), 300, 0.8],
]

# The two pools beyond the rim, each ringed by its own rocks: [center, [[offset, turn, size], ...]].
const OTHER_POOLS := [
	[Vector2(-91.5, -19.5), [[Vector2(-9.0, -2.0), 20, 1.9], [Vector2(-4.0, 8.5), 140, 1.4],
		[Vector2(6.0, 7.0), 250, 1.7], [Vector2(9.5, -3.0), 60, 1.3], [Vector2(1.0, -9.5), 310, 2.0]]],
	[Vector2(84.0, 46.5), [[Vector2(-8.5, 4.0), 200, 1.6], [Vector2(-2.0, -9.0), 90, 1.9],
		[Vector2(8.0, -5.0), 330, 1.3], [Vector2(6.5, 7.0), 10, 1.8]]],
]

var _world: GameWorld
var _rim: Node3D
var _beach: Node3D
var _water: LocalPool
var _shelter: Food
var _animals: Array[Dictionary] = []
var _anemones: Array[Dictionary] = []
var _time := 0.0

func definition() -> Dictionary:
	return {"title": "Coral Colony Tide Pool", "meters_per_unit": 0.01,
		"initial_radius": 0.55, "goal_radius": 4.65,
		"start_position": Vector3(-2.0, 0.0, -16.0), "field": Rect2(-72, -64.5, 144, 129),
		"accent": Color("73ead9"), "background_color": Color("8fc3c8"),
		"key_color": Color("fff1cc"), "fill_color": Color("85cddd"),
		"ground_color": Color("d6cca5"), "ground_texture": "res://assets/models/ground_sand.png",
		"tiers": ["Plankton and polyps", "Branches and shells", "Pool animals", "Rocks and water", "The pool"],
		"jumps": [{"radius": 0.55, "view_size": 14.0}, {"radius": 0.85, "view_size": 20.0},
			{"radius": 1.55, "view_size": 32.0}, {"radius": 2.4, "view_size": 45.0},
			{"radius": 3.4, "view_size": 64.0}]}

func ground_height(point: Vector3) -> float:
	var local := Vector2(point.x / BASIN.x, point.z / BASIN.y)
	var angle := local.angle()
	var shore := 1.0 + 0.055 * sin(angle * 3.0 + 0.4) + 0.03 * sin(angle * 5.0 - 1.1)
	var spill := exp(-pow(angle_difference(angle, SPILL_ANGLE) / 0.1, 2.0))
	var rim := smoothstep(0.75, 1.04, local.length() / shore) * (1.0 - 0.55 * spill)
	var at := Vector2(point.x, point.z)
	var deep_end := exp(-((at - REEF) / Vector2(22.0, 16.0)).length_squared())
	# The reef lifts the crown clear of the water, so no wet cell hides behind the crown.
	var reef := smoothstep(4.4, 2.6, at.distance_to(REEF)) * 1.75
	return lerpf(-0.42 - deep_end * 1.15, 1.15, rim) + reef

func build(world: GameWorld) -> void:
	_world = world
	_rim = Node3D.new()
	_rim.name = "The rock rim around one tide pool"
	world.add_child(_rim)
	for row in SHINGLE:
		var rock := Art.model("rock", row[2])
		_rim.add_child(rock)
		rock.position = Vector3(row[0].x, ground_height(Vector3(row[0].x, 0.0, row[0].y)), row[0].y)
		rock.rotation.y = deg_to_rad(row[1])
	_water = world._pool(Vector3(0, -0.12, 0), BASIN, Color(0.16, 0.69, 0.75, 0.36), 3.0)
	_water.name = "The basin water"
	_water.min_tier = 3
	_water.minimum_radius = 2.4
	_water.set_basin(ground_height)
	_build_beach()
	var kinds := {
		"crown": {"model": "coral_fan", "label": "Great coral crown", "tier": 4, "density": 0.65,
			"whole": _rim, "reason": "The great coral colony grows from the reef in the basin's deep end.", "build": _crown},
		"coral_head": _head(HEAD),
		"coral_bush": _head(BUSH),
		"coral_spray": _head(SPRAY),
		"snail": {"model": "snail", "label": "Snail", "tier": 1, "density": 0.045, "whole": _rim,
			"reason": "The snail grazes algae on the pool's rock.", "build": _creep.bind(0.05, 0.6)},
		"shelter": {"label": "Fish shelter rock", "tier": 4, "density": 0.02, "whole": _rim,
			"reason": "A bedrock overhang shelters the pool's small fish.", "build": _build_shelter},
		"fish": {"model": "small_fish", "label": "Small pool fish", "tier": 2, "density": 0.06,
			"whole": _rim, "reason": "The fish hides under the overhang and darts out to feed.",
			"lift": 0.16, "build": _hide},
		"hermit_crab": {"label": "Hermit crab", "tier": 2, "density": 0.03, "whole": _rim,
			"reason": "The hermit crab forages between the pool's rocks.", "build": _hermit_crab},
		"sea_star": {"model": "sea_star", "label": "Sea star", "tier": 2, "density": 0.045, "whole": _rim,
			"reason": "The sea star creeps over the pool's rock.", "fit": 1.123, "build": _creep.bind(0.03, 1.2)},
		"anemone": {"model": "anemone", "label": "Sea anemone", "tier": 2, "density": 0.05, "whole": _rim,
			"reason": "The anemone is attached to bedrock where the wash brings food.", "build": _anemone},
		"anemone_rock": {"model": "boulder", "label": "Boulder with an anemone", "tier": 3, "density": 0.01, "whole": _rim,
			"reason": "A boulder broken from the rim lies in the pool.", "build": _anemone_on},
		"rim_boulder": {"model": "boulder", "label": "Pool rim boulder", "tier": 3, "density": 0.02,
			"whole": _rim, "reason": "Exposed bedrock forms the pool rim."},
		"anemone_rim": {"model": "boulder", "label": "Rim boulder with an anemone", "tier": 3, "density": 0.02,
			"whole": _rim, "reason": "Exposed bedrock forms the pool rim.", "build": _anemone_on},
	}
	world.place(PLACED, kinds)
	_build_spawns()

# Five fans crossed at the reef read as one crown from above; the model's own fan is the first.
func _crown(crown: Food) -> void:
	crown.milestone = true
	for index in range(1, 5):
		var fan := Art.model("coral_fan", float(Art.manifest().coral_fan.radius) * (1.0 - index * 0.06))
		crown.visual.add_child(fan)
		fan.rotation.y = index * PI / 5.0

func _head(form: Array) -> Dictionary:
	return {"label": "Coral head", "tier": 2, "density": 0.014, "whole": _rim,
		"reason": "The colony's heads ring the reef on the deep end's lip.", "build": _coral_head.bind(form)}

# Low branches around a rock base, each tipped with polyps. The form turns with the head. A branch
# is a third of its head's size, so the starting goo eats a few polyps and then whole branches.
func _coral_head(head: Food, form: Array) -> void:
	var base := Art.model("rock", head.radius * 0.39)
	head.visual.add_child(base)
	base.scale.y *= 0.28
	for branch in form:
		var toward := Vector2.from_angle(deg_to_rad(branch[0]))
		_add_branch(head, toward * head.radius * branch[1], head.radius * 0.34, -deg_to_rad(branch[0] + branch[2]))

func _add_branch(head: Food, at: Vector2, size: float, turn: float) -> void:
	var branch := _world._add_food("coral_branch", at, size, 0.004 * size * size * size, "Living coral branch", false, 1, head)
	branch.rotation.y = turn
	# Low-growing branches put their actual tips inside the starting goo's reach.
	branch.visual.scale.y = 0.42
	branch.height *= 0.42
	for child in branch.get_children():
		if child is CollisionShape3D:
			child.shape.height = branch.height * 0.72
			child.position.y = child.shape.height * 0.5
	branch.part_consumed.connect(_branch_changed.bind(branch))
	# Polyps tip only the outer half of a branch: one on an inner tip sits between branches, where
	# the goo wedges before it can eat them.
	for tip in [Vector3(0.47, 0.57, 0.01), Vector3(0.64, 0.45, -0.04)]:
		var polyp := _world._add_food("polyp", Vector2(tip.x, tip.z) * size / 0.9, 0.15, 0.0003, "Living polyp", false, 0, branch, tip.y * size / 0.72)
		polyp.rotation.y = 0.0

func _branch_changed(_part: Food, branch: Food) -> void:
	for polyp in branch.parts:
		if polyp.active:
			return
	branch.rename("Bare coral branch", Color("eee9d7"))

# The crab's origin sits between its body and the shell it drags, so its footprint circle hugs
# both. The shell's mesh reaches 1.337 times its manifest radius, so it draws within its footprint.
func _hermit_crab(crab: Food) -> void:
	var size := crab.radius
	var body := Art.model("crab_body", 0.72 * size)
	crab.visual.add_child(body)
	body.position.z = 0.22 * size
	var shell := _world._add_food("hermit_shell", Vector2(0.0, -0.556 * size), 0.635 * size, 0.04 * pow(0.635 * size, 3.0), "Hermit crab shell", false, 1, crab)
	shell.rotation.y = 0.0
	shell.visual.scale /= 1.337
	shell.height /= 1.337
	crab.part_consumed.connect(func(_part: Food) -> void: crab.title = "Hermit crab without its shell")
	_animals.append({"food": crab, "home": crab.position, "pace": 0.2, "range": 2.3, "phase": crab.rotation.y, "kind": "walk"})

func _creep(food: Food, pace: float, reach: float) -> void:
	_animals.append({"food": food, "home": food.position, "pace": pace, "range": reach, "phase": food.rotation.y, "kind": "creep"})

func _anemone(anemone: Food) -> void:
	_close_on_touch(anemone, anemone.visual)

# An anemone grows on the boulder's pool side, near its top. The goo cannot reach up there, so it
# is drawn as part of the boulder, goes with it, and closes when the goo bumps the boulder.
func _anemone_on(rock: Food) -> void:
	var inward := rock.to_local(Vector3(0.0, rock.global_position.y, 0.0))
	var side := Vector2(inward.x, inward.z).normalized() * rock.radius * 0.45
	var unit := rock.visual.scale.x
	var anemone := Art.model("anemone", rock.radius * 0.5 / unit)
	rock.visual.add_child(anemone)
	anemone.position = Vector3(side.x, rock.height * 0.62, side.y) / unit
	_close_on_touch(rock, anemone)

func _close_on_touch(food: Food, anemone: Node3D) -> void:
	var rest := anemone.scale
	food.touched.connect(func() -> void: anemone.scale = rest * Vector3(0.72, 0.34, 0.72))
	_anemones.append({"food": food, "node": anemone, "rest": rest})

func _build_shelter(shelter: Food) -> void:
	_shelter = shelter
	var roof := Art.model("boulder", shelter.radius * 0.92)
	shelter.visual.add_child(roof)
	roof.position.y = shelter.radius * 0.5
	roof.scale.y *= 0.3
	for side in [-1.0, 1.0]:
		var foot := _world._add_food("rock", Vector2(side * shelter.radius * 0.6, 0), shelter.radius * 0.4, 0.035 * pow(shelter.radius * 0.4, 3.0), "Shelter rock foot", false, 2, shelter)
		foot.rotation.y = 0.0
	# A lost foot drops the roof onto that side.
	shelter.part_consumed.connect(func(part: Food) -> void:
		roof.rotation.z = signf(part.position.x) * 0.3
		roof.position.y = shelter.radius * 0.32)

func _hide(fish: Food) -> void:
	_animals.append({"food": fish, "home": fish.position, "pace": 0.45, "range": 4.2, "phase": 0.0, "kind": "fish", "shelter": _shelter})

func _build_spawns() -> void:
	_world.spawn({"kind": {"model": "plankton", "label": "Drifting plankton", "tier": 0, "density": 0.6,
			"whole": _water, "reason": "Waves topping the spill wash plankton in, and the current carries them around the reef.",
			"lift": 0.22},
		"from": SPILL, "sizes": Vector2(0.15, 0.22), "tiers": Vector2i(0, 1),
		"rate": 1.0, "limit": 6, "lifetime": 70.0, "move": _ride_current})
	_world.spawn({"kind": {"model": "small_fish", "label": "Fish fry", "tier": 1, "density": 0.12,
			"whole": _shelter, "reason": "Fry hatch under the overhang and dart out across the pool.",
			"lift": 0.3},
		"from": [NURSERY], "sizes": Vector2(0.45, 0.75), "tiers": Vector2i(1, 2),
		"rate": 0.4, "limit": 2, "lifetime": 18.0, "move": _dart})
	_world.spawn({"kind": {"model": "small_fish", "label": "Blenny", "tier": 2, "density": 0.09,
			"whole": _water, "reason": "Blennies nose in through the spill and loop over the open sand.",
			"lift": 0.3},
		"from": SPILL, "sizes": Vector2(1.3, 1.8), "tiers": Vector2i(2, 3),
		"rate": 0.16, "limit": 2, "lifetime": 45.0, "move": _loop})
	_world.spawn({"kind": {"model": "crab_body", "label": "Shore crab", "tier": 3, "density": 0.09,
			"whole": _beach, "reason": "Shore crabs cross the beach and enter the pool through the spill.", "fit": 1.155},
		"from": [Vector2(18.0, 64.0), Vector2(46.0, 64.0)], "sizes": Vector2(2.2, 2.8), "tiers": Vector2i(3, 4),
		"rate": 0.1, "limit": 1, "lifetime": 60.0, "move": _scuttle})

# Plankton drift from the spill toward the reef and circle it in the current, each in its own lane.
func _ride_current(mover: Dictionary, delta: float) -> Vector2:
	var offset: Vector2 = mover.at - REEF
	var distance := offset.length()
	var lane := lerpf(10.0, 15.0, mover.seed)
	var along := Vector2(offset.y, -offset.x) / distance
	var inward := -offset / distance * clampf((distance - lane) * 0.2, -1.0, 1.0)
	var sway := along.orthogonal() * sin(mover.age * 0.8 + mover.seed * TAU) * 0.35
	return mover.at + (along * 0.7 + inward + sway) * 1.6 * delta

# Fry dart out from the shelter in straight lines, fanned toward the open pool.
func _dart(mover: Dictionary, delta: float) -> Vector2:
	var heading := Vector2.from_angle(lerpf(-1.0, 0.6, mover.seed))
	return mover.at + (heading + heading.orthogonal() * sin(mover.age * 7.0) * 0.12) * 3.2 * delta

# Blennies swim in from the spill and loop over the open south sand.
func _loop(mover: Dictionary, delta: float) -> Vector2:
	var center := Vector2(8.0, 16.0)
	var radius := lerpf(9.0, 15.0, mover.seed)
	var angle: float = (mover.from - center).angle() - mover.age * 2.2 / radius
	var target := center + Vector2.from_angle(angle) * radius
	return mover.at + (target - mover.at).limit_length(3.0 * delta)

# Shore crabs walk up the beach to the spill, then sidle into the pool toward the south sand.
func _scuttle(mover: Dictionary, delta: float) -> Vector2:
	var goal: Vector2 = SPILL[0] if mover.at.y > SPILL[0].y + 1.0 else Vector2(lerpf(-20.0, 20.0, mover.seed), 12.0)
	var step: Vector2 = (goal - mover.at).limit_length(2.8 * delta)
	return mover.at + step + step.orthogonal() * sin(mover.age * 5.0) * 0.4

func _build_beach() -> void:
	_beach = Node3D.new()
	_beach.name = "The beach and other pools beyond the rim"
	_world.add_child(_beach)
	for edge in [Rect2(-114, -114, 228, 49.5), Rect2(-114, 64.5, 228, 49.5),
			Rect2(-114, -64.5, 42, 129), Rect2(72, -64.5, 42, 129)]:
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(edge.size.x, 0.45, edge.size.y)
		slab.mesh = box
		slab.material_override = _sand_material(Color("e4d3a2"))
		slab.position = Vector3(edge.get_center().x, -0.6, edge.get_center().y)
		_beach.add_child(slab)
	for pool in OTHER_POOLS:
		var water := MeshInstance3D.new()
		water.name = "Another tide pool beyond the rim"
		var surface := SphereMesh.new()
		surface.radius = 9.0
		surface.height = 0.16
		water.mesh = surface
		water.material_override = _sand_material(Color("43aebc"))
		_beach.add_child(water)
		water.position = Vector3(pool[0].x, -0.23, pool[0].y)
		for rock in pool[1]:
			var boulder := Art.model("boulder", rock[2])
			water.add_child(boulder)
			boulder.position = Vector3(rock[0].x, 0.0, rock[0].y)
			boulder.rotation.y = deg_to_rad(rock[1])

func _sand_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = load("res://assets/models/ground_sand.png")
	material.uv1_scale = Vector3(12, 12, 12)
	material.roughness = 0.86
	return material

func step(delta: float) -> void:
	_time += delta
	for item in _animals:
		_step_animal(item)
	for anemone in _anemones:
		if anemone.food.active:
			anemone.node.scale = anemone.node.scale.lerp(anemone.rest, 1.0 - exp(-delta * 0.45))

func _step_animal(item: Dictionary) -> void:
	var food: Food = item.food
	if not food.active:
		return
	var phase: float = _time * item.pace + item.phase
	var motion := Vector2(sin(phase), sin(phase * 0.7)) * float(item.range)
	if item.kind == "fish":
		var shelter: Food = item.shelter
		var excursion := pow(maxf(0.0, sin(phase)), 5.0) if shelter.active else 1.0
		motion = Vector2(excursion * item.range, sin(phase * 2.0) * excursion)
	var at: Vector3 = item.home + Vector3(motion.x, 0, motion.y)
	at.y = ground_height(at) + (0.16 if item.kind == "fish" else 0.02)
	var movement := at - food.position
	if movement.length_squared() > 0.0000001:
		food.rotation.y = atan2(-movement.z, movement.x)
	food.position = at
