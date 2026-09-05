extends SceneTree

var _game: Node3D
var _elapsed := 0.0

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	_game = load("res://main.tscn").instantiate()
	root.add_child(_game)
	current_scene = _game
	_game.start_level(1)
	_game.rig.zoom = 0.75

func _process(delta: float) -> bool:
	if _game == null:
		return false
	_elapsed += delta
	var actions := ["move_up", "move_right", "move_down", "move_left"]
	var time := fposmod(maxf(_elapsed - 2.0, 0.0), 15.0)
	var phase := -1
	if _elapsed < 2.0:
		phase = -1
	elif time < 4.0:
		phase = int(time / 2.0)
	elif time >= 11.0:
		phase = 2 + int((time - 11.0) / 2.0)
	for index in actions.size():
		Input.action_release(actions[index])
		if phase == index:
			Input.action_press(actions[index])
	return false
