extends SceneTree

var _trials := 1
var _seed := 9217
var _randomized := false

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
		while changed and volume < pow(target, 3.0):
			var gained := _available_meals(world, volume, pow(target, 3.0), target_body)
			changed = gained > 0.0
			volume += gained
		var closes := volume + 0.00001 >= pow(target, 3.0)
		valid = valid and closes
		print("TIER_BUDGET ", config.title, " tier=", tier, " radius=", pow(volume, 1.0 / 3.0), " target=", target, " closes=", closes)
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
