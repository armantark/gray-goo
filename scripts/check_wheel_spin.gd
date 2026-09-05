extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := GameWorld.new()
	root.add_child(world)
	world.build(2)
	var item: Dictionary = world._layout._boards[0]
	var board: Food = item.food
	var center := Vector3.UP * float(Art.manifest().wheel.height) * 0.5
	var starts := {}
	for part in board.parts:
		if part.model_name == "wheel":
			starts[part] = part.visual.transform * center
	var error := 0.0
	for frame in 60:
		item.velocity = Vector2(1.0, 0.0)
		world._layout._step_board(item, 1.0 / 60.0)
		for part in starts:
			error = maxf(error, (part.visual.transform * center).distance_to(starts[part]))
	var spinning := true
	for part in starts:
		spinning = spinning and part.visual.quaternion.angle_to(Quaternion.IDENTITY) > 0.1
	var valid: bool = starts.size() == 4 and spinning and error < 0.00001
	print("WHEEL_AXLE_CHECK wheels=", starts.size(), " max_center_drift=", error, " spinning=", spinning, " pass=", valid)
	world.free()
	quit(0 if valid else 1)
