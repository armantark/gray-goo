extends RefCounted

const HABITAT_SCALE := 1.5
const CROWN_POSITION := Vector2(-1, -28) * HABITAT_SCALE

var _world: GameWorld
var _rim: Node3D
var _water: LocalPool
var _animals: Array[Dictionary] = []
var _plankton: Array[Dictionary] = []
var _anemones: Array[Food] = []
var _time := 0.0

func definition() -> Dictionary:
	return {"title": "Coral Colony Tide Pool", "meters_per_unit": 0.01,
		"initial_radius": 0.55, "goal_radius": 4.65,
		"start_position": Vector3(-24.0, 0.0, 17.0) * HABITAT_SCALE, "field": Rect2(-72, -64.5, 144, 129),
		"accent": Color("73ead9"), "background_color": Color("8fc3c8"),
		"key_color": Color("fff1cc"), "fill_color": Color("85cddd"),
		"ground_color": Color("d6cca5"), "ground_texture": "res://assets/models/ground_sand.png",
		"tiers": ["Plankton and polyps", "Branches and shells", "Pool animals", "Rocks and water", "The pool"],
		"jumps": [{"radius": 0.55, "view_size": 14.0}, {"radius": 0.85, "view_size": 20.0},
			{"radius": 1.55, "view_size": 32.0}, {"radius": 2.4, "view_size": 45.0},
			{"radius": 3.2, "view_size": 64.0}]}

func ground_height(point: Vector3) -> float:
	var local := Vector2(point.x, point.z) / HABITAT_SCALE
	var radial := Vector2(local.x / 39.0, local.y / 34.0).length()
	var angle := atan2(local.y / 34.0, local.x / 39.0)
	var shore := 1.0 + 0.055 * sin(angle * 3.0 + 0.4) + 0.03 * sin(angle * 5.0 - 1.1)
	var rim := smoothstep(0.75, 1.04, radial / shore)
	var deep_end := exp(-Vector2((local.x - 10.0) / 19.0, (local.y + 20.0) / 15.0).length_squared())
	return lerpf(-0.42 - deep_end * 1.15, 1.15, rim)

func build(world: GameWorld) -> void:
	_world = world
	_build_rim()
	_water = world._pool(Vector3(0, -0.12, 0), Vector2(39, 34) * HABITAT_SCALE, Color(0.16, 0.69, 0.75, 0.36), 50.0)
	_water.name = "The basin water"
	_water.min_tier = 3
	_water.minimum_radius = 2.4
	_water.set_basin(ground_height)
	_build_coral()
	_build_current()
	_build_animals()
	var crown := _world._add_food("coral_fan", CROWN_POSITION, 5.0, 4.2, 34.0, "Great coral crown", false, 4)
	crown.context_whole = _rim
	crown.loose_reason = "The great coral colony grows from the basin's deep end."
	crown.milestone = true
	_build_beach()

func _build_rim() -> void:
	_rim = Node3D.new()
	_rim.name = "The rock rim around one tide pool"
	_world.add_child(_rim)
	for index in range(40):
		var angle := (index + _world._rng.randf_range(-0.34, 0.34)) * TAU / 40.0
		var shore := 1.0 + 0.055 * sin(angle * 3.0 + 0.4) + 0.03 * sin(angle * 5.0 - 1.1)
		var at := Vector2(cos(angle) * 36.0, sin(angle) * 31.0) * (shore + _world._rng.randf_range(-0.035, 0.035)) * HABITAT_SCALE
		var rock := _world._add_food("boulder", at, _world._rng.randf_range(1.55, 2.5), 2.4, 0.3, "Pool rim boulder", false, 3)
		rock.context_whole = _rim
		rock.loose_reason = "Exposed bedrock forms the continuous pool rim."
		if index % 4 == 0:
			_add_anemone(rock, -at.normalized().rotated(rock.rotation.y) * rock.radius * 0.95)
		var marker := Art.model("rock", _world._rng.randf_range(0.9, 1.75))
		_rim.add_child(marker)
		var between := Vector2(cos(angle + 0.07) * 40, sin(angle + 0.07) * 35) * shore * HABITAT_SCALE
		marker.rotation.y = _world._rng.randf_range(-PI, PI)
		marker.position = Vector3(between.x, ground_height(Vector3(between.x, 0, between.y)), between.y)

func _build_coral() -> void:
	var shelf := [Vector2(-25, 17), Vector2(-20, 21), Vector2(-29, 10), Vector2(-19, 9),
		Vector2(-29, -7), Vector2(-23, -14), Vector2(-15, -20), Vector2(-7, -24),
		Vector2(-17, -5), Vector2(-12, 4), Vector2(26, 8), Vector2(25, -14),
		Vector2(-24, 10), Vector2(-27, 0), Vector2(-19, -19), Vector2(-11, -27),
		Vector2(-6, -19), Vector2(-7, 14), Vector2(2, 20), Vector2(30, -4),
		Vector2(-17, 16), Vector2(-20, 1), Vector2(-11, -11), Vector2(17, -2)]
	for index in range(shelf.size()):
		var angle := _world._rng.randf_range(-PI, PI)
		var at: Vector2 = shelf[index] * HABITAT_SCALE + Vector2(_world._rng.randf_range(-0.7, 0.7), _world._rng.randf_range(-0.7, 0.7))
		var head := _world._add_food("", at, 2.0, 1.55, 0.15, "Coral head", false, 2)
		head.context_whole = _rim
		head.loose_reason = "The colony is rooted on the inner rock shelf of the pool."
		head.rotation.y = angle
		var base := Art.model("rock", 0.78)
		head.visual.add_child(base)
		base.scale.y *= 0.28
		for branch_index in range(4):
			var branch_angle := branch_index * TAU / 4.0 + _world._rng.randf_range(-0.45, 0.45)
			_add_branch(head, Vector2.from_angle(branch_angle) * _world._rng.randf_range(0.9, 1.4))
		var snail_kind := "snail" if index % 2 == 0 else "periwinkle"
		var snail := _world._add_food(snail_kind, at + Vector2.from_angle(angle) * _world._rng.randf_range(2.6, 3.4), 0.44, 0.85, 0.02, snail_kind.capitalize(), false, 1)
		snail.context_whole = head
		snail.loose_reason = "The snail grazes algae on this coral colony's rock shelf."
		_animals.append({"food": snail, "home": snail.position, "pace": 0.065, "range": 0.65, "phase": angle, "kind": "creep"})

func _add_branch(head: Food, at: Vector2) -> void:
	var size := _world._rng.randf_range(0.64, 0.77)
	var branch := _world._add_food("coral_branch", at, size, 0.85, 0.02, "Living coral branch", false, 1, head)
	branch.rotation.y = _world._rng.randf_range(-PI, PI)
	# Low-growing branches put their actual tips inside the starting goo's reach.
	branch.visual.scale.y = 0.42
	branch.height *= 0.42
	for child in branch.get_children():
		if child is CollisionShape3D:
			child.shape.height = branch.height * 0.72
			child.position.y = child.shape.height * 0.5
	branch.part_consumed.connect(_branch_changed.bind(branch))
	for tip in [Vector3(-0.61, 0.40, 0.01), Vector3(-0.43, 0.48, -0.04),
			Vector3(0.47, 0.57, 0.01), Vector3(0.64, 0.45, -0.04)]:
		_world._add_food("polyp", Vector2(tip.x, tip.z) * size / 0.72, 0.15, 0.34, 0.0027, "Living polyp", false, 0, branch, tip.y * size / 0.72)

func _branch_changed(_part: Food, branch: Food) -> void:
	var survivors := 0
	for polyp in branch.parts:
		if is_instance_valid(polyp) and polyp.active:
			survivors += 1
	if survivors == 0:
		branch.rename("Bare coral branch", Color("eee9d7"))

func _build_current() -> void:
	var eddies := [0.2, 0.58, 1.6, 2.45, 2.83, 3.7, 4.25]
	for index in range(64):
		var item := {"phase": eddies[index % eddies.size()] + _world._rng.randfn(0.0, 0.15),
			"lane": _world._rng.randf_range(-2.3, 1.8), "pace": _world._rng.randf_range(0.010, 0.017),
			"sway": _world._rng.randf_range(0.0, TAU), "bob": _world._rng.randf_range(1.1, 2.0)}
		var at := _current_position(item)
		var food := _world._add_food("plankton", Vector2(at.x, at.z), _world._rng.randf_range(0.15, 0.22), 0.32, 0.0015, "Current plankton")
		food.position = at
		food.context_whole = _water
		food.loose_reason = "The basin current gathers drifting plankton into eddies around its rock shelf."
		item.food = food
		_plankton.append(item)

func _current_position(item: Dictionary) -> Vector3:
	var angle: float = item.phase + _time * item.pace
	var lane: float = item.lane + sin(_time * 0.32 + item.sway) * 0.65
	var point := Vector2(cos(angle) * (27.0 + lane), sin(angle) * (22.0 + lane))
	# The current bends through the open basin in front of the crown's branches.
	var bend := angle_difference(angle, -1.18) / 0.48
	point.y += exp(-bend * bend) * 10.0
	var at := Vector3(point.x, 0, point.y) * HABITAT_SCALE
	at.y = ground_height(at) + 0.22 + sin(_time * item.bob + item.sway) * 0.1
	return at

func _build_animals() -> void:
	var refuges := [Vector2(-18, 15), Vector2(-28, -2), Vector2(-11, -15),
		Vector2(7, 12), Vector2(25, 0), Vector2(23, -13), Vector2(-5, 5),
		Vector2(-21, 18), Vector2(-21, -15), Vector2(-5, -25), Vector2(17, 18), Vector2(27, -7)]
	for refuge in refuges:
		var angle := _world._rng.randf_range(-PI, PI)
		var at: Vector2 = refuge * HABITAT_SCALE + Vector2(_world._rng.randf_range(-1.2, 1.2), _world._rng.randf_range(-1.2, 1.2))
		var crab := _world._add_food("", at, 0.9, 1.55, 0.22, "Hermit crab", false, 2)
		crab.context_whole = _rim
		crab.loose_reason = "The hermit crab forages between the pool's coral heads."
		crab.rotation.y = angle
		crab.visual.add_child(Art.model("crab_body", 0.72))
		_world._add_food("shell", Vector2(0.0, 0.08), 0.54, 0.85, 0.035, "Hermit crab shell", false, 1, crab, 0.14)
		crab.part_consumed.connect(_crab_changed.bind(crab))
		_animals.append({"food": crab, "home": crab.position, "pace": _world._rng.randf_range(0.16, 0.27), "range": 2.3, "phase": angle, "kind": "walk"})
		var star := _world._add_food("sea_star", at + Vector2(2.8, 2.4), 0.85, 1.55, 0.18, "Sea star", false, 2)
		star.context_whole = _rim
		star.loose_reason = "The sea star creeps over the submerged rock shelf."
		_animals.append({"food": star, "home": star.position, "pace": _world._rng.randf_range(0.025, 0.05), "range": 1.5, "phase": angle, "kind": "creep"})
		_add_anemone(null, at - Vector2(2.8, 2.4))
	_build_fish_refuge()

func _crab_changed(_part: Food, crab: Food) -> void:
	crab.rename("Hermit crab without its shell", Color("ef9b69"))

func _add_anemone(parent: Food, at: Vector2) -> void:
	var anemone := _world._add_food("anemone", at, 0.66, 1.55, 0.16, "Sea anemone", false, 2, parent)
	if parent == null:
		anemone.context_whole = _rim
		anemone.loose_reason = "The anemone is attached to submerged bedrock."
	anemone.touched.connect(_close_anemone.bind(anemone))
	_anemones.append(anemone)

func _close_anemone(anemone: Food) -> void:
	if anemone.active:
		anemone.visual.scale = Vector3(0.72, 0.34, 0.72)

func _build_fish_refuge() -> void:
	var shelter := _world._add_food("", Vector2(-10, -8) * HABITAT_SCALE, 2.5, 2.4, 0.7, "Fish shelter rock", false, 3)
	shelter.rotation.y = 0.0
	shelter.context_whole = _rim
	shelter.loose_reason = "A bedrock overhang shelters the pool's small fish."
	var roof := Art.model("boulder", 2.3)
	shelter.visual.add_child(roof)
	roof.position.y = 1.25
	roof.scale.y *= 0.3
	for side in [-1.0, 1.0]:
		_world._add_food("rock", Vector2(side * 1.75, 0), 0.6, 2.4, 0.24, "Shelter rock foot", false, 3, shelter)
	var fish := _world._add_food("small_fish", Vector2(-10, -8) * HABITAT_SCALE, 0.68, 1.55, 0.32, "Small pool fish", false, 2, null, 0.16)
	fish.context_whole = shelter
	fish.loose_reason = "The fish hides under this overhang and darts out to feed."
	_animals.append({"food": fish, "home": fish.position, "pace": 0.45, "range": 4.2, "phase": 0.0, "kind": "fish", "shelter": shelter})

func _build_beach() -> void:
	for edge in [Rect2(-76, -76, 152, 33), Rect2(-76, 43, 152, 33),
			Rect2(-76, -43, 28, 86), Rect2(48, -43, 28, 86)]:
		var beach := MeshInstance3D.new()
		beach.name = "The beach beyond the rock pool"
		var slab := BoxMesh.new()
		slab.size = Vector3(edge.size.x * HABITAT_SCALE, 0.45, edge.size.y * HABITAT_SCALE)
		beach.mesh = slab
		beach.material_override = _sand_material(Color("e4d3a2"))
		beach.position = Vector3(edge.get_center().x * HABITAT_SCALE, -0.6, edge.get_center().y * HABITAT_SCALE)
		_world.add_child(beach)
	for at in [Vector2(-61, -13), Vector2(56, 31)]:
		var water := MeshInstance3D.new()
		water.name = "Another tide pool beyond the rim"
		var surface := SphereMesh.new()
		surface.radius = 9.0
		surface.height = 0.16
		water.mesh = surface
		water.material_override = _sand_material(Color("43aebc"))
		_world.add_child(water)
		water.position = Vector3(at.x * HABITAT_SCALE, -0.23, at.y * HABITAT_SCALE)
		for index in range(12):
			var angle := (index + _world._rng.randf_range(-0.3, 0.3)) * TAU / 12
			var rock := Art.model("boulder", _world._rng.randf_range(1.15, 2.0))
			water.add_child(rock)
			rock.position = Vector3(cos(angle) * 9.0, 0.0, sin(angle) * 9.0)
			rock.rotation.y = _world._rng.randf_range(-PI, PI)

func _sand_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.albedo_texture = load("res://assets/models/ground_sand.png")
	material.uv1_scale = Vector3(12, 12, 12)
	material.roughness = 0.86
	return material

func step(delta: float) -> void:
	_time += delta
	for item in _plankton:
		var food: Food = item.food
		if not is_instance_valid(food) or not food.active:
			continue
		food.position = _current_position(item)
		food.rotation.y = -float(item.phase) - _time * float(item.pace) + sin(_time * 0.7 + item.sway) * 0.28
		food.visual.rotation.x = sin(_time * item.bob + item.sway) * 0.18
	for item in _animals:
		_step_animal(item)
	for anemone in _anemones:
		if is_instance_valid(anemone) and anemone.active:
			anemone.visual.scale = anemone.visual.scale.lerp(Vector3.ONE, 1.0 - exp(-delta * 0.45))

func _step_animal(item: Dictionary) -> void:
	var food: Food = item.food
	if not is_instance_valid(food) or not food.active:
		return
	var phase: float = _time * item.pace + item.phase
	var motion := Vector2(sin(phase), sin(phase * 0.7)) * float(item.range)
	if item.kind == "fish":
		var shelter: Food = item.shelter
		var sheltered := is_instance_valid(shelter) and shelter.active
		var excursion := pow(maxf(0.0, sin(phase)), 5.0) if sheltered else 1.0
		motion = Vector2(excursion * item.range, sin(phase * 2.0) * excursion)
	var at: Vector3 = item.home + Vector3(motion.x, 0, motion.y)
	at.y = ground_height(at) + (0.16 if item.kind == "fish" else 0.02)
	var movement := at - food.position
	if movement.length_squared() > 0.0000001:
		food.rotation.y = atan2(-movement.z, movement.x)
	food.position = at
