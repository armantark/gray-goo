extends Node3D

var world: GameWorld
var goo: GooBody
var rig: GooCamera
var hud: GameHUD
var _volume := 0.0
var _level := 0
var _won := false
var _revealed := false
var _cinematic := -1.0
var _bite_sound: AudioStreamPlayer
var _win_sound: AudioStreamPlayer
var _last_sound := 0
var _frame_times := PackedFloat64Array()
var _record_performance := false
var _last_frame_usec := 0
var _closing := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_install_controls()
	hud = GameHUD.new()
	add_child(hud)
	hud.scene_requested.connect(start_level)
	hud.pause_requested.connect(_set_paused)
	_bite_sound = AudioStreamPlayer.new()
	_bite_sound.stream = load("res://assets/audio/bite.wav")
	_bite_sound.volume_db = -13.0
	_bite_sound.max_polyphony = 5
	add_child(_bite_sound)
	_win_sound = AudioStreamPlayer.new()
	_win_sound.stream = load("res://assets/audio/complete.wav")
	_win_sound.volume_db = -10.0
	add_child(_win_sound)
	for arg in OS.get_cmdline_user_args():
		if arg == "--performance":
			_record_performance = true
	start_level(0)

func _install_controls() -> void:
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func start_level(index: int) -> void:
	_last_frame_usec = 0
	get_tree().paused = false
	Engine.time_scale = 1.0
	_cinematic = -1.0
	_bite_sound.stop()
	_win_sound.stop()
	if is_instance_valid(rig):
		rig.free()
	if is_instance_valid(goo):
		goo.free()
	if is_instance_valid(world):
		world.free()
	_level = index
	_won = false
	_revealed = false
	world = GameWorld.new()
	add_child(world)
	world.build(index)
	goo = GooBody.new()
	add_child(goo)
	goo.configure(world.config.start_position, world.config.initial_radius,
		world.get_ground_height, world.get_obstacles, world.field)
	_volume = pow(world.config.initial_radius, 3.0)
	world.player_radius = goo.radius
	rig = GooCamera.new()
	add_child(rig)
	rig.configure(world.field, world.config.camera_sizes[0], goo, world.get_ground_height)
	hud.configure(index, world.config)
	print("LEVEL_READY ", index, " ", world.config.title)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(world):
		return
	world.player_radius = goo.radius
	goo.set_drive(rig.movement_direction(), 2.8 + goo.radius * 0.8)
	var eaten := 0
	for food in world.foods:
		if not is_instance_valid(food) or not food.active or food.threshold > goo.radius:
			continue
		if goo.touches(food.center(), food.radius * 0.72):
			_eat(food)
			eaten += 1
			if eaten == 5:
				break
	for pool in world.pools:
		if pool.remaining_volume <= 0.00001:
			continue
		var contact := Vector3.ZERO
		var portion := 0.0
		if pool.whole_threshold > 0.0 and goo.radius >= pool.whole_threshold and pool.touches(goo.global_position, goo.radius):
			contact = pool.closest_point(goo.global_position)
			portion = pool.consume_whole()
		else:
			portion = pool.consume_at(goo.global_position, goo.radius, delta)
			contact = pool.last_contact
		if portion > 0.0:
			_add_growth(portion, pool.pigment, contact)
	if not _revealed and world.config.jump_radius > 0.0 and goo.radius >= world.config.jump_radius:
		_revealed = true
		world.advance_scale()
		rig.reveal(world.config.camera_sizes[1])
	if not _won and _volume >= pow(world.config.goal_radius, 3.0):
		_complete()

func _eat(food: Food) -> void:
	var portion := food.remaining_volume()
	var color := food.meal_color()
	var point := food.center()
	food.consume(goo)
	_add_growth(portion, color, point)
	_bite_particles(point, color, clampf(portion / _volume, 0.02, 1.0))
	if Time.get_ticks_msec() - _last_sound > 65:
		_bite_sound.pitch_scale = clampf(1.3 - food.radius * 0.12 + randf_range(-0.1, 0.1), 0.55, 1.4)
		_bite_sound.play()
		_last_sound = Time.get_ticks_msec()

func _add_growth(portion: float, color: Color, point: Vector3) -> void:
	var fraction := portion / _volume
	_volume += portion
	goo.absorb(point, color, clampf(fraction, 0.0, 1.0))
	goo.grow_to(pow(_volume, 1.0 / 3.0))

func _complete() -> void:
	_won = true
	goo.celebrate()
	_cinematic = 0.0
	Engine.time_scale = 0.22
	_win_sound.play()
	_bite_particles(goo.global_position, goo.tint.lightened(0.3), 1.0)
	print("LEVEL_COMPLETE ", _level, " volume=", _volume)

func _process(delta: float) -> void:
	if not is_instance_valid(world):
		return
	if _record_performance and not get_tree().paused:
		var now := Time.get_ticks_usec()
		if _last_frame_usec > 0:
			_frame_times.append((now - _last_frame_usec) / 1000000.0)
		_last_frame_usec = now
	if _cinematic >= 0.0:
		_cinematic += delta / Engine.time_scale
		Engine.time_scale = lerpf(0.22, 1.0, smoothstep(0.2, 0.85, _cinematic))
		if _cinematic >= 0.85:
			Engine.time_scale = 1.0
			_cinematic = -1.0
			hud.show_completion()
	var target := world.nearest_edible(goo.global_position, goo.radius)
	var target_position := Vector3.ZERO
	var target_name := ""
	if is_instance_valid(target):
		target_position = target.center()
		target_name = target.title
	else:
		for pool in world.pools:
			if pool.remaining_volume > 0.00001:
				target_position = pool.closest_point(goo.global_position)
				target_name = "Spacetime fabric" if _level == 3 else "Water"
				break
	hud.update_game(pow(_volume, 1.0 / 3.0), world.config.initial_radius,
		world.config.goal_radius, rig.camera, goo.global_position, target_position, target_name)

func _bite_particles(point: Vector3, color: Color, strength: float) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 8 + int(strength * 12.0)
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.4 + strength * 0.3
	particles.direction = Vector3.UP
	particles.spread = 80.0
	particles.gravity = Vector3(0, -5, 0)
	particles.initial_velocity_min = 0.7 + strength
	particles.initial_velocity_max = 1.8 + strength * 2.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	particles.color = color
	var droplet := SphereMesh.new()
	droplet.radius = goo.radius * 0.055
	droplet.height = droplet.radius * 2.0
	droplet.radial_segments = 8
	droplet.rings = 4
	particles.mesh = droplet
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.4
	particles.material_override = material
	world.add_child(particles)
	particles.global_position = point
	particles.finished.connect(particles.queue_free)
	particles.emitting = true

func _set_paused(paused: bool) -> void:
	_last_frame_usec = 0
	get_tree().paused = paused

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()

func _write_performance() -> void:
	if _frame_times.is_empty():
		return
	var ordered := _frame_times.duplicate()
	ordered.sort()
	var total := 0.0
	for duration in ordered:
		total += duration
	var report := {
		"frames": ordered.size(), "seconds": total,
		"average_fps": ordered.size() / total,
		"p95_frame_ms": ordered[int(ordered.size() * 0.95)] * 1000.0,
		"viewport": str(get_viewport().get_visible_rect().size),
		"renderer": RenderingServer.get_current_rendering_method(),
	}
	var file := FileAccess.open("user://performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("PERFORMANCE ", JSON.stringify(report))

func _exit_tree() -> void:
	if is_instance_valid(_bite_sound):
		_bite_sound.stop()
		_bite_sound.stream = null
	if is_instance_valid(_win_sound):
		_win_sound.stop()
		_win_sound.stream = null
	Engine.time_scale = 1.0

func _shutdown() -> void:
	if _closing:
		return
	_closing = true
	if _record_performance:
		_write_performance()
	_bite_sound.stop()
	_win_sound.stop()
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().quit()
