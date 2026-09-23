extends SceneTree

var _valid := true
var _checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	seed(439)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for kind in ["shell", "procedural"]:
		game.start_level(1)
		game._switch_body(kind)
		# Fixtures sit where a four-body-length drive meets them. At the default eight, the
		# shell's staged final bite misses one run in three.
		game.hud.movement_speed = 0.5
		var initial_radius: float = game.goo.radius
		var initial_tint: Color = game.goo.tint
		var initial_volume: float = game._volume
		var meal := _food_at_body(game, initial_volume * 0.4)
		game._physics_process(1.0 / 60.0)
		_check(not meal.active and meal._meal_target == game.goo, kind + " ordinary contact starts a meal")
		_check(game._volume >= initial_volume + meal.volume - 0.00001, kind + " meal adds volume")
		_check(not game.goo.tint.is_equal_approx(initial_tint), kind + " meal deposits pigment")
		var deposited_tint: Color = game.goo.tint
		for destination in ["procedural" if kind == "shell" else "shell", kind]:
			var old_position: Vector3 = game.goo.global_position
			var old_radius: float = game.goo.radius
			var old_target: float = game.goo._target_radius
			var old_tint: Color = game.goo.tint
			var old_body: Node3D = game.goo
			game._switch_body(destination)
			_check(game.goo != old_body, kind + " switch replaces body")
			_check(game.goo.global_position.is_equal_approx(old_position), kind + " switch preserves position")
			_check(is_equal_approx(game.goo.radius, old_radius), kind + " switch preserves radius")
			_check(is_equal_approx(game.goo._target_radius, old_target), kind + " switch preserves growth target")
			_check(game.goo.tint.is_equal_approx(old_tint), kind + " switch preserves tint")
			_check(meal._meal_target == game.goo and meal._meal_age < 0.34, kind + " in-flight meal rebinds")
			_check(game.rig.subject == game.goo, kind + " camera rebinds")
		for tick in 120:
			game.goo._physics_process(1.0 / 60.0)
			meal._physics_process(1.0 / 60.0)
		_check(game.goo.radius > initial_radius, kind + " body grows")
		_check(game.goo.tint.is_equal_approx(deposited_tint), kind + " pigment survives diffusion")
		_check(not meal.visible and meal._meal_age >= 0.34, kind + " meal animation finishes after switch")
		var start: Vector3 = game.goo.global_position
		Input.action_press("move_up")
		for tick in 60:
			_tick(game)
		Input.action_release("move_up")
		_check(game.goo.global_position.distance_to(start) > initial_radius, kind + " game input moves body")
		game.rig._process(1.0)
		_check(game.rig.subject == game.goo and game.rig._focus.distance_to(game.goo.global_position) < game.rig.camera.size, kind + " camera follows moving subject")
		# Stage the final bite near the current volume; the real game loop must complete it.
		game.world.config.goal_radius = pow(game._volume * 1.1, 1.0 / 3.0)
		var final_meal := _food_at_body(game, game._volume * 0.2)
		game._physics_process(1.0 / 60.0)
		_check(not final_meal.active and game._won, kind + " contact bite crosses staged goal")
		_check(game.goo._celebration > 0.0 and Engine.time_scale < 1.0, kind + " goal celebrates")
		Engine.time_scale = 1.0
		# Exercise actual terrain and field callables at an otherwise unreachable far edge.
		game.start_level(1)
		game._switch_body(kind)
		var edge_start := Vector3(game.world.field.end.x - initial_radius * 2.0, 0.0, 0.0)
		_place_body(game, edge_start, initial_radius)
		Input.action_press("move_right")
		var grounded := true
		var bounded := true
		for tick in 180:
			_tick(game)
			for point in game.goo._points:
				grounded = grounded and point.y >= game.world.get_ground_height(point) - 0.0001
				bounded = bounded and point.x >= game.world.field.position.x - 0.0001 and point.x <= game.world.field.end.x + 0.0001 and point.z >= game.world.field.position.y - 0.0001 and point.z <= game.world.field.end.y + 0.0001
		Input.action_release("move_right")
		_check(game.goo.global_position.x > edge_start.x, kind + " wall probe drives outward")
		_check(grounded, kind + " skin stays above terrain")
		_check(bounded, kind + " skin stays inside field")
		_check_eat_rule(game, kind)
		print("BODY_CASE ", kind, " radius=", game.goo.radius, " position=", game.goo.global_position)
	_check_composite_meals(game)
	_check_empty_wholes(game)
	_check_footprints(game)
	game.free()
	Engine.time_scale = 1.0
	print("BODY_CHECK_OK=", _valid, " checks=", _checks)
	quit(0 if _valid else 1)

# Size decides edibility, not tier: a smaller rock from the last tier is eaten on first contact,
# and a larger can from the first tier survives contact as an obstacle. Driven straight at it,
# the goo never gets its center inside or over the can's footprint, and slides around it.
func _check_eat_rule(game: Node3D, kind: String) -> void:
	game.start_level(1)
	game._switch_body(kind)
	var at: Vector3 = game.goo.global_position
	var small: Food = game.world._add_food("rock", Vector2(at.x, at.z), game.goo.radius * 0.5, 0.01, "Later-tier canary", false, 4)
	game._physics_process(1.0 / 60.0)
	_check(not small.active, kind + " smaller later-tier object is eaten on contact")
	# At the default speed, where the shell used to roll over the can.
	game.hud.movement_speed = 1.0
	Input.action_press("move_up")
	var heading: Vector3 = game.rig.movement_direction()
	at = game.goo.global_position + heading * game.goo.radius * 3.0
	var large: Food = game.world._add_food("trash_can", Vector2(at.x, at.z), game.goo.radius * 2.0, 0.01, "Larger canary", false, 0)
	var touched := false
	var clear := true
	for tick in 180:
		_tick(game)
		var offset: Vector3 = game.goo.global_position - large.global_position
		# Contact with a wall is judged at the goo's own height, as the route driver's stall measure does.
		touched = touched or game.goo.touches(large.global_position + Vector3.UP * offset.y, large.collider_radius * 1.05)
		clear = clear and Vector2(offset.x, offset.z).length() > large.collider_radius
	Input.action_release("move_up")
	var solid: bool = game.world.get_obstacles(large.global_position, 0.0).any(
		func(obstacle: Dictionary) -> bool: return obstacle.center == large.global_position)
	_check(touched and large.active and solid, kind + " larger object blocks")
	_check(clear, kind + " goo stays out of the larger object's footprint")
	_check((game.goo.global_position - large.global_position).dot(heading) > 0.0, kind + " goo slides past the larger object")

# Parts act as their own food until the goo eats the whole, and the whole then takes every
# surviving part once. Each case bites one part and then the whole by contact, in every level.
func _check_composite_meals(game: Node3D) -> void:
	for case in [[0, "Water molecule · H2O", "Hydrogen atom"], [1, "Coral head", "Living coral branch"],
			[1, "Hermit crab", "Hermit crab shell"], [2, "Skater", "Skateboard"], [3, "Spiral galaxy", "Spiral arm"]]:
		game.start_level(case[0])
		# Spawn points add food as the level runs; this case audits one composite in a closed level.
		game.world.spawns.clear()
		var whole := _find(game, case[1])
		var part := _find(game, case[2], whole)
		var total := _level_volume(game)
		# Emptied wholes leave with their last part and pay nothing, so only their own volume may vanish.
		var forfeit := 0.0
		for food in [whole] + _descendants(whole):
			forfeit += food.volume if food.collect_when_empty else 0.0
		_bite(game, part)
		_check(not part.active and whole.active, case[2] + " is eaten apart from its " + case[1])
		_bite(game, whole)
		var left := _descendants(whole).filter(func(food: Food) -> bool: return food.active or food.is_visible_in_tree())
		_check(not whole.active and not whole.is_visible_in_tree() and left.is_empty(), case[1] + " leaves no active or visible parts")
		var lost := total - _level_volume(game)
		_check(lost > -0.000001 and lost < forfeit + 0.000001, case[1] + " pays each part's growth at most once")
		print("COMPOSITE_CASE ", case[1], " parts=", _descendants(whole).size(), " left=", left.size(), " unpaid=", lost)

# A whole that draws nothing of its own goes with its last part instead of staying an invisible meal.
func _check_empty_wholes(game: Node3D) -> void:
	game.start_level(3)
	var cluster: Food
	for food in game.world.foods:
		if food.title == "Open star cluster" and food.radius > game.goo.radius * GameWorld.EAT_MARGIN:
			cluster = food
			break
	for star in cluster.parts:
		if star.active:
			_bite(game, star)
	_check(not cluster.active, "an open star cluster goes with its last star")
	# A nucleon that lost a quark collapses and hides its own body; once a size jump retires its
	# other quarks as detail it shows nothing, so it no longer holds its nucleus on screen.
	game.start_level(0)
	var atom := _find(game, "Helium atom")
	var nucleus := _find(game, "Helium nucleus", atom)
	var collapsed: Food = nucleus.parts[0]
	game._eat(collapsed.parts[0])
	_place_body(game, game.goo.global_position, float(game.world.config.jumps[2].radius))
	_settle(game)
	for nucleon in nucleus.parts:
		if nucleon.active and nucleon != collapsed:
			game._eat(nucleon)
	_check(not nucleus.active and not collapsed.active and atom.active, "a nucleus goes with its last visible nucleon, taking a collapsed one")

# Size decides edibility, so these composites' footprints are what they draw.
func _check_footprints(game: Node3D) -> void:
	var worst := {}
	for level in [0, 1]:
		game.start_level(level)
		for food in game.world.foods:
			if food.title.ends_with(" nucleus") or food.title == "Hermit crab":
				var drawn := _drawn_reach(food)
				if absf(food.radius / drawn - 1.0) >= absf(worst.get(food.title, [1.0])[0] - 1.0):
					worst[food.title] = [food.radius / drawn, food.radius, drawn]
	for title in worst:
		_check(absf(worst[title][0] - 1.0) < 0.12, "%s footprint %.3f matches its drawn %.3f" % [title, worst[title][1], worst[title][2]])

func _find(game: Node3D, title: String, whole: Food = null) -> Food:
	for food in game.world.foods:
		if food.title == title and (whole == null or whole.is_ancestor_of(food)):
			return food
	push_error("BODY_CHECK_FAIL no " + title)
	return null

func _descendants(food: Food) -> Array[Food]:
	var result: Array[Food] = []
	for part in food.parts:
		result.append(part)
		result.append_array(_descendants(part))
	return result

# Growth held by the goo plus growth still on the field and in pools; meals move it, never create it.
func _level_volume(game: Node3D) -> float:
	var result: float = game._volume
	for food in game.world.foods:
		if food.parent_food == null:
			result += food.remaining_volume()
	for pool in game.world.pools:
		result += pool.remaining_volume
	return result

# Sets a goo just large enough to eat the food down on it; the game's contact rule decides the meal.
func _bite(game: Node3D, food: Food) -> void:
	var radius := maxf(float(game.world.config.initial_radius), food.radius / GameWorld.EAT_MARGIN * 1.05)
	_place_body(game, food.center(), radius)
	game._physics_process(1.0 / 60.0)
	_settle(game)

# Lets meals land and scene motion, including detail changes after a size jump, catch up.
func _settle(game: Node3D) -> void:
	# The longest meal flight lasts 0.55 s.
	for tick in 40:
		game._physics_process(1.0 / 60.0)
		game.world._physics_process(1.0 / 60.0)
		for food in game.world.foods:
			if food.is_physics_processing():
				food._physics_process(1.0 / 60.0)

func _place_body(game: Node3D, at: Vector3, radius: float) -> void:
	var body_script: Script = game.goo.get_script()
	game.goo.free()
	game.goo = body_script.new()
	game.add_child(game.goo)
	game.goo.configure(at, radius, game.world.get_ground_height, game.world.get_obstacles, game.world.field)
	game.rig.subject = game.goo

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

func _food_at_body(game: Node3D, volume: float) -> Food:
	var at: Vector3 = game.goo.global_position
	var food: Food = game.world._add_food("plankton", Vector2(at.x, at.z), game.goo.radius * 0.25, volume, "Body canary contact fixture")
	food.rename(food.title, Color(1.0, 0.15, 0.25))
	return food

func _tick(game: Node3D) -> void:
	game._physics_process(1.0 / 60.0)
	game.goo._physics_process(1.0 / 60.0)

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_valid = false
		push_error("BODY_CHECK_FAIL " + label)
