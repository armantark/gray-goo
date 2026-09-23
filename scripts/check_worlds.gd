extends SceneTree

var _trials := 1
var _seed := 9217
var _randomized := false
# Levels built from a placement table; tickets 09 to 11 add the other three.
const HAND_PLACED := [1]
# Seconds of spawn-point release each tier may draw on to reach its next jump, on top of the food
# it already holds; about the time the route should spend in a view.
const SUPPLY_SECONDS := 90.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--trials="):
			_trials = int(arg.trim_prefix("--trials="))
		elif arg.begins_with("--seed="):
			_seed = int(arg.trim_prefix("--seed="))
	if _trials < 1:
		push_error("The world check requires at least one trial")
		quit(1)
		return
	var success := true
	for level in 4:
		for trial in _trials:
			_randomized = trial > 0
			var trial_seed := _seed + level * 197 + trial * 1009
			seed(trial_seed)
			var world := GameWorld.new()
			root.add_child(world)
			world.build(level)
			if trial == 0:
				success = _check_membership(world) and success
				if level in HAND_PLACED:
					success = _check_placement(world, level) and success
			var valid := _check_ladder(world)
			success = valid and success
			print("WORLD_TRIAL level=", level, " seed=", trial_seed, " randomized=", _randomized, " pass=", valid)
			world.free()
	print("WORLD_CHECK_OK=", success)
	quit(0 if success else 1)

func _check_membership(world: GameWorld) -> bool:
	var valid := true
	for food in world.foods:
		var whole: Node3D = food.parent_food if is_instance_valid(food.parent_food) else food.context_whole
		if not is_instance_valid(whole) or not _has_geometry(whole):
			print("MISSING_WHOLE ", world.config.title, " ", food.title)
			valid = false
	var rng := RandomNumberGenerator.new()
	rng.seed = 9217
	var candidates := world.foods.duplicate()
	for index in mini(10, candidates.size()):
		var chosen := rng.randi_range(0, candidates.size() - 1)
		var food: Food = candidates.pop_at(chosen)
		var whole: Node3D = food.parent_food if is_instance_valid(food.parent_food) else food.context_whole
		var label: String = whole.title if whole is Food else str(whole.name) if is_instance_valid(whole) else "MISSING"
		print("OBJECT_WHOLE ", world.config.title, " | ", food.title, " | ", label)
	return valid

# A placed level draws nothing from the random stream: a build with another seed places every object,
# part, and turn identically. Every object's footprint matches what it draws, and no object sits
# inside the outline of a larger one it does not belong to, where the goo could never reach it.
func _check_placement(world: GameWorld, level: int) -> bool:
	var valid := true
	var other := GameWorld.new()
	root.add_child(other)
	other.build(level, 1234567)
	var same: bool = other.foods.size() == world.foods.size() and not world.placed.is_empty()
	for index in mini(world.foods.size(), other.foods.size()):
		var a := world.foods[index]
		var b := other.foods[index]
		same = same and a.title == b.title and is_equal_approx(a.radius, b.radius) \
			and a.global_transform.is_equal_approx(b.global_transform)
	print("PLACEMENT_IDENTICAL ", world.config.title, " placed=", world.placed.size(), " foods=", world.foods.size(), " pass=", same)
	valid = valid and same
	# One mover from each spawn point joins the footprint audit; they are released in the copy, so
	# the world the budget audits keeps its authored start.
	for point in other.spawns:
		other._release(point)
	for food in other.foods:
		var drawn := _drawn_reach(food)
		if absf(food.radius / drawn - 1.0) >= 0.12:
			print("FOOTPRINT_MISMATCH ", world.config.title, " ", food.title, " footprint=", food.radius, " drawn=", drawn)
			valid = false
	for food in world.foods:
		for solid in world.foods:
			if solid.radius <= food.radius or solid.collider_radius <= 0.0 or solid.is_ancestor_of(food) or food.is_ancestor_of(solid):
				continue
			var gap := Vector2(food.global_position.x - solid.global_position.x, food.global_position.z - solid.global_position.z).length()
			if gap < solid.collider_radius:
				print("FOOD_INSIDE_LARGER ", world.config.title, " ", food.title, " at ", food.global_position, " inside ", solid.title, " at ", solid.global_position)
				valid = false
	other.free()
	return valid

# Farthest horizontal reach of the food's own model and its parts' models, from its origin.
func _drawn_reach(food: Food) -> float:
	var reach := _mesh_reach(food, food.visual)
	for part in food.parts:
		reach = maxf(reach, _mesh_reach(food, part.visual))
	return reach

func _mesh_reach(food: Food, node: Node) -> float:
	var reach := 0.0
	if node is MeshInstance3D:
		var local: Transform3D = food.global_transform.affine_inverse() * node.global_transform
		for surface in node.mesh.get_surface_count():
			for vertex in node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				var point: Vector3 = local * vertex
				reach = maxf(reach, Vector2(point.x, point.z).length())
	for child in node.get_children():
		reach = maxf(reach, _mesh_reach(food, child))
	return reach

func _has_geometry(node: Node) -> bool:
	if node is MeshInstance3D or node is MultiMeshInstance3D:
		return true
	for child in node.get_children():
		if _has_geometry(child):
			return true
	return false

func _check_ladder(world: GameWorld) -> bool:
	var config := world.config
	var valid: bool = config.tiers.size() == 5 and config.jumps.size() == 5
	var previous := 0.0
	for jump in config.jumps:
		valid = valid and jump.radius > previous and jump.view_size > 0.0
		previous = jump.radius
	var volume := pow(float(config.initial_radius), 3.0)
	var target_body := Node3D.new()
	world.add_child(target_body)
	for tier in config.tiers.size():
		world.advance_scale(tier)
		if _randomized:
			world.foods.shuffle()
		var target: float = config.jumps[tier + 1].radius if tier + 1 < config.jumps.size() else config.goal_radius
		var changed := true
		var supplied := 0.0
		while changed and volume < pow(target, 3.0):
			var gained := _available_meals(world, volume, pow(target, 3.0), target_body)
			changed = gained > 0.0
			volume += gained
			if not changed and not world.spawns.is_empty() and supplied < SUPPLY_SECONDS:
				world._physics_process(1.0)
				supplied += 1.0
				changed = true
		var closes := volume + 0.00001 >= pow(target, 3.0)
		valid = valid and closes
		print("TIER_BUDGET ", config.title, " tier=", tier, " radius=", pow(volume, 1.0 / 3.0), " target=", target, " closes=", closes, " spawn_seconds=", supplied)
	return valid

func _available_meals(world: GameWorld, volume: float, goal_volume: float, target: Node3D) -> float:
	var available := volume
	for food in world.foods:
		if not world.is_edible(food, pow(available, 1.0 / 3.0)):
			continue
		available += food.remaining_volume()
		food.consume(target)
		if available >= goal_volume:
			return available - volume
	world._layout.step(0.0)
	for pool in world.pools:
		if pool.is_edible(world.current_tier, pow(available, 1.0 / 3.0)):
			available += pool.consume_whole()
	return available - volume
