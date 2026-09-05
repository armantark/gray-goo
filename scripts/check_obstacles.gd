extends SceneTree

var _checks := 0
var _valid := true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9217
	for level in 4:
		var world := GameWorld.new()
		root.add_child(world)
		world.build(level)
		for tier in 5:
			world.advance_scale(tier)
			world.player_radius = world.config.jumps[tier].radius
			for sample in 20:
				world._physics_process(1.0 / 60.0)
				var food: Food = world.foods[rng.randi_range(0, world.foods.size() - 1)]
				_check(world, food.global_position, rng.randf_range(0.1, 8.0))
		# Revisit a smaller radius, add a solid, then move and remove it between queries.
		world.advance_scale(0)
		world.player_radius = world.config.initial_radius
		_check(world, world.get_start(), 2.0)
		var added := world._add_food("rock", Vector2.ZERO, 1.0, 100.0, 0.1, "Obstacle canary")
		_check(world, added.global_position, 2.0)
		var old_position := added.global_position
		added.position += Vector3(7, 0, 0)
		_check(world, old_position, 2.0)
		_check(world, added.global_position, 2.0)
		added.active = false
		_check(world, added.global_position, 2.0)
		world.free()
	print("OBSTACLE_CHECK queries=", _checks, " pass=", _valid)
	quit(0 if _valid else 1)

func _check(world: GameWorld, center: Vector3, reach: float) -> void:
	_checks += 1
	if world.get_obstacles(center, reach) != _reference(world, center, reach):
		_valid = false
		push_error("Obstacle query differs from the uncached scan in " + str(world.config.title))

func _reference(world: GameWorld, center: Vector3, reach: float) -> Array:
	var result: Array = []
	for food in world.foods:
		if not is_instance_valid(food) or not food.active or food.collider_radius <= 0.0 or world.is_edible(food, world.player_radius):
			continue
		var point := food.global_position
		if Vector2(point.x - center.x, point.z - center.z).length_squared() > pow(reach + food.collider_radius, 2):
			continue
		var obstacle := {"center": point, "radius": food.collider_radius,
			"bottom": point.y, "top": point.y + food.height * 0.72}
		if not food.freeze:
			obstacle["body"] = food
		result.append(obstacle)
	return result
