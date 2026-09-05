extends RefCounted

const BOWL_CENTER := Vector2(16.0, -6.0)
var _world: GameWorld
var _bowl: Node3D
var _boards: Array[Dictionary] = []
var _riders: Array[Dictionary] = []
var _bottles: Array[Food] = []
var _time := 0.0

func definition() -> Dictionary:
	return {"title": "Skatepark Bowl", "meters_per_unit": 0.25,
		"initial_radius": 0.55, "goal_radius": 3.85,
		"start_position": Vector3(7.0, 0.0, -6.0), "field": Rect2(-45, -44, 94, 92),
		"accent": Color("ffaf68"), "background_color": Color("9db8c7"),
		"key_color": Color("fff0d0"), "fill_color": Color("98dcff"),
		"ground_color": Color("a4b6b7"), "ground_texture": "res://assets/models/ground_concrete.png",
		"tiers": ["Litter in the gutter", "Boards and gear", "Skaters and furniture", "Rails and pipes", "The park"],
		"jumps": [{"radius": 0.55, "view_size": 16.0}, {"radius": 0.85, "view_size": 21.0},
			{"radius": 1.35, "view_size": 29.0}, {"radius": 2.1, "view_size": 40.0},
			{"radius": 3.0, "view_size": 53.0}]}

func ground_height(point: Vector3) -> float:
	var distance := Vector2((point.x - 16.0) / 1.2, point.z + 6.0).length()
	var slope := clampf((distance - 9.0) / 10.0, 0.0, 1.0)
	return -2.6 * (1.0 - slope * slope * (3.0 - 2.0 * slope))

func build(world: GameWorld) -> void:
	_world = world
	_build_bowl()
	_build_boards()
	_build_litter()
	_build_furniture()
	_build_rails()
	_build_pipes()
	_build_street()

func _build_bowl() -> void:
	_bowl = Node3D.new()
	_bowl.name = "The concrete bowl and its low gutter"
	_world.add_child(_bowl)
	for radius in [8.6, 19.0]:
		var strip := SurfaceTool.new()
		strip.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in range(96):
			var angle := index * TAU / 96.0
			var next_angle := (index + 1) * TAU / 96.0
			var a := Vector3(16.0 + cos(angle) * radius * 1.2, 0, -6.0 + sin(angle) * radius)
			var b := Vector3(16.0 + cos(next_angle) * radius * 1.2, 0, -6.0 + sin(next_angle) * radius)
			a.y = ground_height(a) + 0.035
			b.y = ground_height(b) + 0.035
			var side := (b - a).cross(Vector3.UP).normalized() * 0.12
			for point in [a - side, b + side, a + side, a - side, b - side, b + side]:
				strip.set_normal(Vector3.UP)
				strip.set_uv(Vector2(point.x, point.z) * 0.2)
				strip.add_vertex(point)
		var mesh := MeshInstance3D.new()
		mesh.mesh = strip.commit()
		mesh.material_override = _concrete_material(Color("657a82") if radius < 10 else Color("d4eee7"))
		_bowl.add_child(mesh)

func _build_litter() -> void:
	var kinds := ["bolt", "bearing", "bottle_cap", "pebble"]
	var catches := [0.3, 0.6, 2.6, 2.85, 4.55]
	for index in range(144):
		var angle: float = catches[index % catches.size()] + _world._rng.randfn(0.0, 0.13)
		var radius := _world._rng.randf_range(6.9, 8.8)
		var at := BOWL_CENTER + Vector2(cos(angle) * 1.2, sin(angle)) * radius
		var kind: String = kinds[index % kinds.size()]
		var food := _world._add_food(kind, at, _world._rng.randf_range(0.1, 0.19), 0.32, 0.0035, kind.replace("_", " ").capitalize())
		food.context_whole = _bowl
		food.loose_reason = "Pebbles broke from the concrete rim and washed into the low gutter."
		if kind in ["bolt", "bearing"]:
			food.context_whole = _boards[index % _boards.size()].food
			food.loose_reason = "Worn skateboard hardware rolled downhill into the gutter."
		elif kind == "bottle_cap":
			food.context_whole = _bottles[index % _bottles.size()]
			food.loose_reason = "A cap dropped from a skater's rim-side water bottle and washed downhill."

func _build_boards() -> void:
	var riders := [Vector2(27, 3), Vector2(23, 6), Vector2(2, 1), Vector2(7, -13),
		Vector2(30, -11), Vector2(24, -16), Vector2(18, 6), Vector2(11, -20)]
	for at in riders:
		_add_rider(at)
	var boards := [Vector2(32, -3), Vector2(31, 0), Vector2(30, 4), Vector2(5, -15),
		Vector2(3, -14), Vector2(22, -22), Vector2(24, -21), Vector2(-8, -15),
		Vector2(-10, -14), Vector2(-11, 17), Vector2(-9, 16), Vector2(36, 9)]
	for point in boards:
		var at: Vector2 = point + Vector2(_world._rng.randf_range(-0.45, 0.45), _world._rng.randf_range(-0.45, 0.45))
		var board := _add_board(at)
		board.context_whole = _bowl
		board.loose_reason = "A rider's board rolls from the rim toward the low bowl."
		board.rotation.y = _world._rng.randf_range(-PI, PI)
		_boards.append({"food": board, "velocity": Vector2.ZERO})
	var rests := [Vector2(-11, -17), Vector2(4, 16), Vector2(39, -12), Vector2(22, -28)]
	for index in range(12):
		var at: Vector2 = rests[index / 3] + Vector2(_world._rng.randf_range(-1.5, 1.5), _world._rng.randf_range(-1.5, 1.5))
		var kinds := ["helmet", "shoe", "water_bottle"]
		var kind: String = kinds[index % 3]
		var gear := _world._add_food(kind, at, 0.48, 0.85, 0.05, kind.replace("_", " ").capitalize(), false, 1)
		gear.context_whole = _bowl
		gear.loose_reason = "Skaters leave their gear in small piles on the dry rim before riding."
		if kind == "water_bottle":
			_bottles.append(gear)

func _add_board(at: Vector2, parent: Food = null) -> Food:
	var board := _world._add_food("", at, 1.18, 0.85, 0.04, "Skateboard", false, 1, parent)
	board.rotation.y = 0.0
	board.height = 0.5
	var deck := _world._add_food("board", Vector2.ZERO, 1.15, 0.85, 0.025, "Skate deck", false, 1, board, 0.22)
	deck.rotation.y = 0.0
	for axle in [-1.0, 1.0]:
		var truck := _world._add_food("truck", Vector2(axle * 0.68, 0), 0.34, 0.85, 0.01, "Skateboard truck", false, 1, board, 0.11)
		truck.rotation.y = 0.0
		for side in [-1.0, 1.0]:
			var wheel := _world._add_food("wheel", Vector2(axle * 0.68, side * 0.44), 0.16, 0.4, 0.003, "Skateboard wheel", false, 0, board)
			wheel.rotation.y = 0.0
	board.part_consumed.connect(_board_changed.bind(board))
	return board

func _add_rider(at: Vector2) -> void:
	var rider := _world._add_food("", at, 0.9, 1.35, 0.45, "Skater", false, 2)
	rider.context_whole = _bowl
	rider.loose_reason = "This skater rides a board through the concrete bowl."
	rider.height = 2.0
	rider.rotation.y = 0.0
	var person := Art.model("skater", 0.62)
	rider.visual.add_child(person)
	person.position.y = 0.36
	var board := _add_board(Vector2.ZERO, rider)
	rider.part_consumed.connect(_rider_changed.bind(rider))
	var route_center := BOWL_CENTER + Vector2(_world._rng.randf_range(-2, 2), _world._rng.randf_range(-2, 2))
	var offset := Vector2((at.x - route_center.x) / 1.2, at.y - route_center.y)
	_riders.append({"food": rider, "board": board, "phase": offset.angle(), "radius": offset.length(),
		"center": route_center, "pace": _world._rng.randf_range(0.065, 0.12), "sway": _world._rng.randf_range(0, TAU)})

func _board_changed(part: Food, board: Food) -> void:
	if part.model_name == "wheel":
		board.set_meta("lost_wheel", true)
		board.rotation.x = signf(part.position.z) * 0.28
		board.rotation.z = -signf(part.position.x) * 0.12
		board.rename("Tipped skateboard", Color("d99b79"))
	elif part.model_name == "board":
		board.rename("Skateboard trucks and wheels", Color("a8b4be"))
	elif part.model_name == "truck":
		board.set_meta("lost_wheel", true)
		board.rotation.z = -signf(part.position.x) * 0.25

func _rider_changed(part: Food, rider: Food) -> void:
	if part.title == "Skateboard" or part.model_name.is_empty():
		rider.rename("Standing skater", Color("dfa179"))
		rider.visual.get_child(0).position.y = 0.0

func _build_furniture() -> void:
	var seats := [Vector2(-18, -26), Vector2(-16, -16), Vector2(-21, -3),
		Vector2(-17, 13), Vector2(-19, 22), Vector2(-13, 34)]
	for point in seats:
		var at: Vector2 = point + Vector2(_world._rng.randf_range(-0.7, 0.7), _world._rng.randf_range(-0.7, 0.7))
		var bench := _world._add_food("bench", at, 1.65, 1.35, 0.6, "Park bench", false, 2)
		bench.context_whole = _bowl
		bench.loose_reason = "Seating lines the flat spectator side of the bowl."
		bench.rotation.y = PI * 0.5 + _world._rng.randf_range(-0.25, 0.25)
	for at in [Vector2(-23, -24), Vector2(-24, -5), Vector2(-22, 20), Vector2(-9, 36)]:
		var bin := _world._add_food("trash_can", at, 0.9, 1.35, 0.45, "Park trash can", false, 2)
		bin.context_whole = _bowl
		bin.loose_reason = "The park's trash cans stand beside its spectator benches."
	for at in [Vector2(-4, 25), Vector2(1, 28), Vector2(7, 24), Vector2(10, 29),
			Vector2(18, 25), Vector2(24, 30), Vector2(27, 26), Vector2(33, 29)]:
		var cone := _world._add_food("cone", at, 0.55, 1.35, 0.06, "Practice cone", false, 2)
		cone.context_whole = _bowl
		cone.loose_reason = "The cone line marks the approach to the quarter pipes."

func _build_rails() -> void:
	for at in [Vector2(-34, -34), Vector2(-12, -36), Vector2(3, -31), Vector2(26, -36),
			Vector2(-30, 33), Vector2(-8, 39), Vector2(13, 36), Vector2(34, 35)]:
		var rail := _world._add_food("", at, 2.1, 2.1, 0.6, "Grind rail", false, 3)
		rail.context_whole = _bowl
		rail.loose_reason = "The grind rail belongs to the bowl's flat trick course."
		rail.rotation.y = _world._rng.randf_range(-0.45, 0.45)
		rail.height = 1.25
		var bar := Art.model("rail_bar", 2.0)
		rail.visual.add_child(bar)
		bar.position.y = 0.94
		for side in [-1.0, 1.0]:
			var post := _world._add_food("rail_post", Vector2(side * 1.35, 0), 0.42, 1.35, 0.1, "Grind rail post", false, 2, rail)
			post.rotation.y = 0.0
		rail.part_consumed.connect(_rail_changed.bind(rail))

func _rail_changed(part: Food, rail: Food) -> void:
	var bar: Node3D = rail.visual.get_child(0)
	bar.rotation.z = -signf(part.position.x) * 0.24
	bar.position.y = 0.58
	rail.rename("Tilted grind rail", Color("8f9aa0"))

func _build_pipes() -> void:
	for at in [Vector2(-32, -23), Vector2(-4, -31), Vector2(40, -14),
			Vector2(30, 22), Vector2(2, 29), Vector2(-24, 22)]:
		var pipe := _world._add_food("ramp", at, 2.75, 2.1, 1.55, "Quarter pipe", false, 3)
		pipe.context_whole = _bowl
		pipe.loose_reason = "Quarter pipes face the connected bowl and trick course."
		pipe.rotation.y = atan2(at.y - BOWL_CENTER.y, BOWL_CENTER.x - at.x)
	var final := _world._add_food("ramp", Vector2(-33, 7), 4.7, 3.0, 30.0, "Big quarter pipe", false, 4)
	final.context_whole = _bowl
	final.loose_reason = "The park's biggest quarter pipe anchors its western deck."
	final.rotation.y = 0.0
	final.milestone = true

func _build_street() -> void:
	var street := MeshInstance3D.new()
	street.name = "Street beyond the skatepark fence"
	var road := BoxMesh.new()
	road.size = Vector3(150, 0.18, 18)
	street.mesh = road
	street.material_override = _concrete_material(Color("515963"))
	street.position = Vector3(0, -0.15, -59)
	_world.add_child(street)
	for index in range(17):
		var fence := Art.model("fence_section", 3.1)
		_world.add_child(fence)
		fence.position = Vector3(-48 + index * 6, 0, -47)
	for index in range(7):
		var car := Art.model("parked_car", 2.6)
		street.add_child(car)
		car.position = Vector3(-42 + index * 14 + _world._rng.randf_range(-2, 2), 0.15, _world._rng.randf_range(-3.0, -2.0))
		car.rotation.y = _world._rng.randf_range(-0.08, 0.08)
		var tree := Art.model("tree", _world._rng.randf_range(2.8, 4.7))
		_world.add_child(tree)
		tree.position = Vector3(-44 + index * 15 + _world._rng.randf_range(-4, 4), -0.1, _world._rng.randf_range(-75, -71))
	for side in [-1.0, 1.0]:
		for index in range(12):
			var fence := Art.model("fence_section", 3.1)
			_world.add_child(fence)
			fence.position = Vector3(-48 if side < 0 else 52, 0, -42 + index * 8)
			fence.rotation.y = PI * 0.5

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
		var rider: Food = item.food
		var board: Food = item.board
		if not is_instance_valid(rider) or not rider.active:
			continue
		if not is_instance_valid(board) or not board.active or board.get_meta("lost_wheel", false):
			continue
		var phase: float = item.phase + _time * item.pace
		var radius: float = item.radius + (sin(phase * 2.0 + item.sway) - sin(item.phase * 2.0 + item.sway)) * 1.1
		var at: Vector2 = item.center + Vector2(cos(phase) * 1.2, sin(phase)) * radius
		var movement := Vector2(at.x - rider.position.x, at.y - rider.position.z)
		rider.position = Vector3(at.x, ground_height(Vector3(at.x, 0, at.y)), at.y)
		rider.rotation.y = atan2(-movement.y, movement.x)

func _step_board(item: Dictionary, delta: float) -> void:
	var board: Food = item.food
	if not is_instance_valid(board) or not board.active:
		return
	var at := board.position
	var gradient := Vector2(ground_height(at + Vector3(0.1, 0, 0)) - ground_height(at - Vector3(0.1, 0, 0)),
		ground_height(at + Vector3(0, 0, 0.1)) - ground_height(at - Vector3(0, 0, 0.1))) / 0.2
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
			board.rotation.z = atan(gradient.dot(velocity.normalized()))
			for part in board.parts:
				if is_instance_valid(part) and part.active and part.model_name == "wheel":
					part.visual.rotation.z -= velocity.length() / part.radius * delta
	item.velocity = velocity
