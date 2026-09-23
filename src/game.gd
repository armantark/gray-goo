extends Node3D

const MUSIC_TRACKS := [
	"res://assets/audio/particle_shuffle.ogg",
	"res://assets/audio/tidepool_bossa.ogg",
	"res://assets/audio/skatepark_samba.ogg",
	"res://assets/audio/cosmic_drift.ogg",
]

const BODY_LENGTHS_PER_SECOND := 4.0
# Meal feedback and the arrow read a reward as its share of the goo's volume on a log scale,
# from a speck worth SMALL_MEAL of the goo to a feast worth BIG_MEAL or more.
const SMALL_MEAL := 0.002
const BIG_MEAL := 0.25
var world: GameWorld
var goo: GooBody
var rig: GooCamera
var hud: GameHUD
var _volume := 0.0
var _level := 0
var _won := false
var _tier := 0
var _cinematic := -1.0
var _bite_sound: AudioStreamPlayer
var _win_sound: AudioStreamPlayer
var _music: AudioStreamPlayer
var _last_sound := 0
var _last_sound_reward := 0.0
var _frame_times := PackedFloat64Array()
var _record_performance := false
var _last_frame_usec := 0
var _closing := false
var _highlighted_target: Food

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_install_controls()
	hud = GameHUD.new()
	add_child(hud)
	hud.scene_requested.connect(start_level)
	hud.pause_requested.connect(_set_paused)
	hud.body_requested.connect(_switch_body)
	_bite_sound = AudioStreamPlayer.new()
	_bite_sound.stream = load("res://assets/audio/bite.wav")
	_bite_sound.volume_db = -13.0
	_bite_sound.max_polyphony = 5
	add_child(_bite_sound)
	_win_sound = AudioStreamPlayer.new()
	_win_sound.stream = load("res://assets/audio/complete.wav")
	_win_sound.volume_db = -10.0
	add_child(_win_sound)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -17.0
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	hud.music_changed.connect(func(enabled: bool): _music.stream_paused = not enabled)
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
	_music.stop()
	if is_instance_valid(rig):
		rig.free()
	if is_instance_valid(goo):
		goo.free()
	if is_instance_valid(world):
		world.free()
	_level = index
	_won = false
	_tier = 0
	world = GameWorld.new()
	add_child(world)
	world.build(index)
	goo = GooProcedural.new() if hud.body_kind == "procedural" else GooBody.new()
	add_child(goo)
	goo.configure(world.config.start_position, world.config.initial_radius,
		world.get_ground_height, world.get_obstacles, world.field)
	_volume = pow(world.config.initial_radius, 3.0)
	world.player_radius = goo.radius
	rig = GooCamera.new()
	add_child(rig)
	rig.configure(world.field, world.config.jumps[0].view_size, goo, world.get_ground_height)
	hud.configure(index, world.config)
	_music.stream = load(MUSIC_TRACKS[index])
	_music.stream.loop = true
	_music.play()
	_music.stream_paused = not hud.music_enabled
	print("LEVEL_READY ", index, " ", world.config.title)

func _switch_body(kind: String) -> void:
	var old := goo
	var at := old.global_position
	var size := old.radius
	var pigment := old.tint
	goo = GooProcedural.new() if kind == "procedural" else GooBody.new()
	add_child(goo)
	goo.configure(at, size, world.get_ground_height, world.get_obstacles, world.field)
	var shift := at - goo.global_position
	goo.global_position = at
	# The shell stores pigment and geometry in world-space samples. Preserve the
	# shared state without changing its solver or adding another shell interface.
	for i in goo._points.size():
		goo._points[i] += shift
		goo._previous[i] += shift
	goo._colors = old._colors.duplicate()
	goo._facing = old._facing
	goo.tint = pigment
	goo.grow_to(maxf(old._target_radius, pow(_volume, 1.0 / 3.0)))
	goo.gaze_screen_position = old.gaze_screen_position
	goo._celebration = old._celebration
	goo._update_surface()
	rig.subject = goo
	for food in world.foods:
		if food._meal_target == old:
			food._meal_target = goo
	hud.body_kind = kind
	old.free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(world):
		return
	world.player_radius = goo.radius
	_signal_newly_edible()
	# Speed is a constant number of body lengths per second, so a speck and a giant feel the same.
	goo.set_drive(rig.movement_direction(), BODY_LENGTHS_PER_SECOND * goo.radius * 2.0 * hud.movement_speed)
	_consume_foods()
	_consume_pools(delta)
	_update_scale()
	if not _won and _volume >= pow(world.config.goal_radius, 3.0):
		_complete()

func _consume_foods() -> void:
	# Judge every contact before any meal, because a meal can move or hide the rest of its composite.
	var meals: Array[Food] = []
	for food in world.nearby(goo.global_position, goo.radius * 3.0):
		if not food.active or not goo.touches(food.center(), food.radius):
			continue
		food.touched.emit()
		if world.is_edible(food, goo.radius):
			meals.append(food)
	for food in meals:
		if food.active:
			_eat(food)

func _signal_newly_edible() -> void:
	var grown := world.newly_edible(goo.radius)
	if grown.is_empty():
		return
	var flash := StandardMaterial3D.new()
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flash.albedo_color = Color(1.0, 0.93, 0.62, 0.85)
	create_tween().tween_property(flash, "albedo_color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	for food in grown:
		food.signal_edible(flash)

func _reward(portion: float) -> float:
	return clampf(log(portion / (_volume * SMALL_MEAL)) / log(BIG_MEAL / SMALL_MEAL), 0.0, 1.0)

func _consume_pools(delta: float) -> void:
	for pool in world.pools:
		if not pool.is_edible(_tier, goo.radius):
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
			hud.show_meal("Spacetime fabric" if _level == 3 else "Water", "", pool.pigment)

func _update_scale() -> void:
	while _tier + 1 < world.config.jumps.size() and goo.radius >= float(world.config.jumps[_tier + 1].radius):
		_tier += 1
		world.advance_scale(_tier)
		rig.reveal(float(world.config.jumps[_tier].view_size))
		print("LEVEL_TIER ", _level, " ", _tier, " ", world.config.tiers[_tier])
	var jump: Dictionary = world.config.jumps[_tier]
	var growth_view: float = float(jump.view_size) * goo.radius / float(jump.radius)
	if _tier + 1 < world.config.jumps.size():
		growth_view = minf(growth_view, float(world.config.jumps[_tier + 1].view_size) * 0.82)
	rig.reveal(growth_view)

func _eat(food: Food) -> void:
	var portion := food.remaining_volume()
	var reward := _reward(portion)
	var color := food.meal_color()
	var point := food.center()
	hud.show_meal(food.title, food.model_name, color)
	food.consume(goo, lerpf(0.3, 0.55, reward))
	_add_growth(portion, color, point)
	goo.pulse(reward)
	_bite_particles(point, color, reward)
	# Rapid small bites share one sound; a bigger bite always gets its own.
	var now := Time.get_ticks_msec()
	if now - _last_sound > 65 or reward > _last_sound_reward + 0.2:
		_bite_sound.volume_db = lerpf(-19.0, -5.0, reward)
		_bite_sound.pitch_scale = lerpf(1.35, 0.6, reward) + randf_range(-0.06, 0.06)
		_bite_sound.play()
		_last_sound = now
		_last_sound_reward = reward

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
	if target != _highlighted_target:
		if is_instance_valid(_highlighted_target):
			_highlighted_target.set_highlighted(false)
		_highlighted_target = target
		if is_instance_valid(_highlighted_target):
			_highlighted_target.set_highlighted(true)
	var target_position := Vector3.ZERO
	var target_name := ""
	var target_reward := 0.0
	if is_instance_valid(target):
		target_position = target.center()
		target_name = target.title
		target_reward = _reward(target.remaining_volume())
	else:
		for pool in world.pools:
			if pool.is_edible(_tier, goo.radius):
				target_position = pool.closest_point(goo.global_position)
				target_name = "Spacetime fabric" if _level == 3 else "Water"
				target_reward = _reward(pool.remaining_volume)
				break
	if rig.mouse_steering:
		goo.gaze_screen_position = get_viewport().get_mouse_position()
	else:
		goo.gaze_screen_position = rig.camera.unproject_position(target_position if not target_name.is_empty() else goo.global_position)
	hud.update_game(pow(_volume, 1.0 / 3.0), world.config.initial_radius,
		world.config.goal_radius, world.current_tier, rig.camera, goo.global_position, target_position, target_name, target_reward)

func _bite_particles(point: Vector3, color: Color, strength: float) -> void:
	var particles := CPUParticles3D.new()
	# Speeds and gravity follow the goo's size, so a burst reads the same in every view.
	particles.amount = 6 + int(strength * 30.0)
	particles.one_shot = true
	# A one-shot CPUParticles3D with explosiveness exactly 1.0 emits nothing in Godot 4.7.2.
	particles.explosiveness = 0.95
	particles.lifetime = 0.35 + strength * 0.45
	# Droplets spray out of the bite and upward, which reads from the top-down camera.
	var outward := point - goo.global_position
	outward.y = 0.0
	particles.direction = (outward.normalized() + Vector3.UP).normalized()
	particles.spread = 55.0
	particles.gravity = Vector3(0, -6.0, 0) * goo.radius
	particles.initial_velocity_min = goo.radius * (0.8 + strength * 1.6)
	particles.initial_velocity_max = goo.radius * (1.8 + strength * 3.2)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	particles.color = color
	var droplet := SphereMesh.new()
	droplet.radius = goo.radius * lerpf(0.05, 0.12, strength)
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
	_music.stop()
	await get_tree().create_timer(0.1, true, false, true).timeout
	get_tree().quit()
