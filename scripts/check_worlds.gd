extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var success := true
	for level in 4:
		var world := GameWorld.new()
		root.add_child(world)
		world.build(level)
		success = _check_ladder(world) and success
		world.free()
	print("WORLD_CHECK_OK=", success)
	quit(0 if success else 1)

func _check_ladder(world: GameWorld) -> bool:
	var config := world.config
	var valid: bool = config.tiers.size() == 5 and config.jumps.size() == 5
	var previous := 0.0
	for jump in config.jumps:
		valid = valid and jump.radius > previous and jump.view_size > 0.0
		previous = jump.radius
	var consumed := {}
	var volume := pow(float(config.initial_radius), 3.0)
	var pools_taken := {}
	for tier in config.tiers.size():
		world.advance_scale(tier)
		var target: float = config.jumps[tier + 1].radius if tier + 1 < config.jumps.size() else config.goal_radius
		var changed := true
		while changed and volume < pow(target, 3.0):
			changed = false
			for food in world.foods:
				if consumed.has(food.get_instance_id()) or not world.is_edible(food, pow(volume, 1.0 / 3.0)):
					continue
				volume += _take(food, consumed)
				changed = true
			for pool in world.pools:
				if not pools_taken.has(pool.get_instance_id()):
					volume += pool.remaining_volume
					pools_taken[pool.get_instance_id()] = true
					changed = true
		var closes := volume + 0.00001 >= pow(target, 3.0)
		valid = valid and closes
		print("TIER_BUDGET ", config.title, " tier=", tier, " radius=", pow(volume, 1.0 / 3.0), " target=", target, " closes=", closes)
	return valid

func _take(food: Food, consumed: Dictionary) -> float:
	if consumed.has(food.get_instance_id()):
		return 0.0
	consumed[food.get_instance_id()] = true
	var volume := food.volume
	for part in food.parts:
		volume += _take(part, consumed)
	return volume
