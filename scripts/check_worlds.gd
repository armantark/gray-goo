extends SceneTree

var _trials := 1
var _seed := 9217
var _randomized := false
# Levels built to the food mix: in each view, placed food supplies MIX_SHARE of the growth needed
# to reach the next jump and spawn points supply the rest. Other levels print their share without
# failing until their own rebalance adds them here.
const MIX_LEVELS := []
const MIX_SHARE := Vector2(0.7, 0.9)
# Seconds of spawn-point release a view may draw on to close. Only a stop for a view its spawns
# cannot close; pacing comes from the growth scale and the route's meal gaps, not from this.
const SPAWN_LIMIT := 300.0
# Whole-second steps release at most one mover per step and round every wait up to the next
# second, which undercounts a spawn point's stated rate by up to a fifth; quarter seconds do not.
const SUPPLY_STEP := 0.25
const GLOW := preload("res://shaders/star_halo.gdshader")

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

# Farthest horizontal reach of the food's own model and every part's model, from its origin. A
# galaxy group draws through its galaxies' arms, which are parts of parts.
func _drawn_reach(food: Food, origin: Food = food) -> float:
	var reach := _mesh_reach(origin, food.visual)
	for part in food.parts:
		reach = maxf(reach, _drawn_reach(part, origin))
	return reach

# A glow halo is light around a body, not its outline, so it does not count as drawn.
func _mesh_reach(food: Food, node: Node) -> float:
	var reach := 0.0
	if node is MeshInstance3D and not (node.material_override is ShaderMaterial and node.material_override.shader == GLOW):
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
		var start := volume
		# Placed food is eaten first, and spawned movers only when nothing placed is edible, so the
		# share is the part of the view's growth that its placed food supplies.
		var placed_growth := 0.0
		var supplied := 0.0
		while volume < pow(target, 3.0):
			var gained := _available_meals(world, volume, pow(target, 3.0), target_body, true)
			placed_growth += gained
			if gained <= 0.0:
				gained = _available_meals(world, volume, pow(target, 3.0), target_body, false)
			volume += gained
			if gained > 0.0:
				continue
			if world.spawns.is_empty() or supplied >= SPAWN_LIMIT:
				break
			world._physics_process(SUPPLY_STEP)
			supplied += SUPPLY_STEP
		var closes := volume + 0.00001 >= pow(target, 3.0)
		var share := placed_growth / (pow(target, 3.0) - start)
		var mixed := share >= MIX_SHARE.x and share <= MIX_SHARE.y
		valid = valid and closes and (mixed or config.title not in MIX_LEVELS)
		print("TIER_BUDGET ", config.title, " tier=", tier, " radius=", pow(volume, 1.0 / 3.0), " target=", target, " closes=", closes,
			" placed_share=", snappedf(share, 0.001), " mix=", "pass" if mixed else "fail" if config.title in MIX_LEVELS else "not-enforced",
			" spawn_seconds=", supplied)
	return valid

# Eats what is edible among the placed food, or among the spawned movers, up to the goal.
func _available_meals(world: GameWorld, volume: float, goal_volume: float, target: Node3D, placed: bool) -> float:
	var movers := {}
	for point in world.spawns:
		for mover in point.movers:
			movers[mover.food] = true
	var available := volume
	for food in world.foods:
		if not world.is_edible(food, pow(available, 1.0 / 3.0)) or _spawned(food, movers) == placed:
			continue
		available += world.growth(food)
		food.consume(target)
		if available >= goal_volume:
			return available - volume
	world._layout.step(0.0)
	if not placed:
		return available - volume
	for pool in world.pools:
		if pool.is_edible(world.current_tier, pow(available, 1.0 / 3.0)):
			available += pool.consume_whole() * world.growth_scale
	return available - volume

func _spawned(food: Food, movers: Dictionary) -> bool:
	while food != null:
		if movers.has(food):
			return true
		food = food.parent_food
	return false
