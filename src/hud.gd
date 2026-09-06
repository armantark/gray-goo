class_name GameHUD
extends CanvasLayer

signal scene_requested(index: int)
signal pause_requested(paused: bool)
signal body_requested(kind: String)
signal music_changed(enabled: bool)

# The HUD reads as labels on a microscope slide: paper cards with ink text over the dark scene.
const INK := Color("1b2a2c")
const INK_SOFT := Color("5c6f70")
const PAPER := Color("f6f3e8")
const PAPER_EDGE := Color("cfc7ad")
const TEAL := Color("277a68")
const RULE := Color("8a9a92")
const TITLES := ["Sugar Water", "Coral Colony Tide Pool", "Skatepark Bowl", "Cosmic Web"]
const LIGHT_YEAR := 9.4607e15
var title_label: Label
var tier_label: Label
var target_label: Label
var gauge: SizeGauge
var ladder: HBoxContainer
var completion: PanelContainer
var menu: PanelContainer
var next_button: Button
var hint_label: Label
var pointer: FoodPointer
var movement_speed := 1.0
var body_kind := "shell"
var music_enabled := true
var _root: Control
var _scene_index := 0
var _hint_time := 0.0
var _config: Dictionary
var _meters_per_unit := 1.0
var _tier := -1
var _rungs: Array[Label] = []
var _settings := ConfigFile.new()
var _last_meal: PanelContainer
var _meal_label: Label
var _meal_view: SubViewport
var _meal_camera: Camera3D
var _meal_model: Node3D
var _meal_kind := ""
var _mono := SystemFont.new()

class FoodPointer extends Control:
	var position_on_screen := Vector2.ZERO
	var direction := Vector2.RIGHT
	var target_visible := false
	func _draw() -> void:
		if not target_visible:
			return
		var points := PackedVector2Array()
		for point in [Vector2(17, 0), Vector2(-10, -9), Vector2(-5, 0), Vector2(-10, 9)]:
			points.append(position_on_screen + point.rotated(direction.angle()))
		draw_colored_polygon(points, Color("fff2a6"))
		points.append(points[0])
		draw_polyline(points, Color("172729"), 2.5, true)

# A round dial on a log scale from the starting diameter to the goal diameter.
# The dial flashes a ring when a size jump changes the unit calibration.
class SizeGauge extends Control:
	const SWEEP := TAU * 0.75
	const START := PI * 0.75
	var fraction := 0.0
	var reading := ""
	var goal := ""
	var flash := 0.0
	var font: Font
	func _draw() -> void:
		var center := size * 0.5
		var outer := minf(center.x, center.y) - 4.0
		draw_arc(center, outer, START, START + SWEEP, 72, PAPER_EDGE, 7.0, true)
		if fraction > 0.0:
			draw_arc(center, outer, START, START + SWEEP * fraction, 72, TEAL, 7.0, true)
		for tick in 5:
			var angle := START + SWEEP * float(tick) / 4.0
			draw_line(center + Vector2.from_angle(angle) * (outer - 12.0), center + Vector2.from_angle(angle) * (outer - 5.0), INK_SOFT, 2.0, true)
		if flash > 0.0:
			draw_arc(center, outer + 6.0 + (1.0 - flash) * 18.0, 0.0, TAU, 96, Color(TEAL, flash), 3.0, true)
		draw_string(font, Vector2(0, center.y + 8.0), reading, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, INK)
		draw_string(font, Vector2(0, center.y + 30.0), goal, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, INK_SOFT)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mono.font_names = PackedStringArray(["JetBrains Mono", "Menlo", "Monaco"])
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.add_theme_color_override("font_color", INK)
	_root.add_theme_font_size_override("font_size", 22)
	_build_slide_label()
	var scene_button := _button(_root, "Scenes · Esc")
	scene_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	scene_button.offset_left = -220
	scene_button.offset_top = 26
	scene_button.offset_right = -28
	scene_button.offset_bottom = 76
	scene_button.pressed.connect(toggle_menu)
	pointer = FoodPointer.new()
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(pointer)
	var hint := PanelContainer.new()
	hint.add_theme_stylebox_override("panel", _style(Color(INK, 0.72), 20))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_left = -430
	hint.offset_right = 430
	hint.offset_top = -66
	hint.offset_bottom = -22
	_root.add_child(hint)
	hint_label = _label(hint, "WASD / arrows  ·  Hold left mouse to steer  ·  Right-drag to rotate  ·  Scroll to zoom", 19)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_color", PAPER)
	_build_completion()
	_build_menu()
	_build_last_meal()

func _build_slide_label() -> void:
	var card := _panel(_root)
	card.position = Vector2(28, 26)
	card.custom_minimum_size = Vector2(470, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	gauge = SizeGauge.new()
	gauge.font = _mono
	gauge.custom_minimum_size = Vector2(170, 170)
	gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge.tooltip_text = "Goo body diameter on a log scale from the starting size to the goal."
	row.add_child(gauge)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	row.add_child(column)
	_caption(column, "SPECIMEN SLIDE")
	title_label = _label(column, "", 28)
	tier_label = _label(column, "", 16)
	tier_label.add_theme_color_override("font_color", INK_SOFT)
	ladder = HBoxContainer.new()
	ladder.add_theme_constant_override("separation", 4)
	column.add_child(ladder)
	_caption(column, "NEAREST FOOD")
	target_label = _label(column, "", 19)

func _caption(parent: Node, text: String) -> Label:
	var label := _label(parent, text, 12)
	label.add_theme_color_override("font_color", INK_SOFT)
	label.add_theme_font_override("font", _mono)
	return label

func _build_ladder(tiers: Array) -> void:
	for rung in _rungs:
		rung.free()
	_rungs.clear()
	for index in tiers.size():
		var rung := _label(ladder, str(index + 1), 13)
		rung.add_theme_font_override("font", _mono)
		rung.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rung.custom_minimum_size = Vector2(44, 24)
		rung.tooltip_text = tiers[index]
		rung.mouse_filter = Control.MOUSE_FILTER_STOP
		_rungs.append(rung)

func _paint_ladder() -> void:
	for index in _rungs.size():
		var rung := _rungs[index]
		var lit := index <= _tier
		var style := _style(TEAL if lit else Color(PAPER_EDGE, 0.5), 4)
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		if index == _tier:
			style.set_border_width_all(2)
			style.border_color = INK
		rung.add_theme_stylebox_override("normal", style)
		rung.add_theme_color_override("font_color", PAPER if lit else INK_SOFT)

func _build_last_meal() -> void:
	_last_meal = _panel(_root)
	_last_meal.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_last_meal.offset_left = 28
	_last_meal.offset_right = 420
	_last_meal.offset_top = -208
	_last_meal.offset_bottom = -82
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_last_meal.add_child(row)
	_meal_view = SubViewport.new()
	_meal_view.size = Vector2i(192, 192)
	_meal_view.own_world_3d = true
	_meal_view.transparent_bg = true
	_meal_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_meal_view)
	var portrait := TextureRect.new()
	portrait.texture = _meal_view.get_texture()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(portrait)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text)
	_caption(text, "SPECIMEN · LAST EATEN")
	_meal_label = _label(text, "", 22)
	_meal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_meal_camera = Camera3D.new()
	_meal_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_meal_view.add_child(_meal_camera)
	_meal_camera.position = Vector3(0, 1.5, 3)
	_meal_camera.look_at(Vector3.ZERO)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	_meal_view.add_child(light)
	_last_meal.hide()

func show_meal(title: String, kind: String, color: Color) -> void:
	if _last_meal.visible and _meal_label.text == title and _meal_kind == kind:
		return
	_meal_label.text = title
	_meal_kind = kind
	if is_instance_valid(_meal_model):
		_meal_model.free()
	var height := 0.3
	if kind.is_empty():
		var liquid := SphereMesh.new()
		liquid.radius = 0.8
		liquid.height = height
		_meal_model = Art.mesh_node(liquid, color, 0.25)
	else:
		_meal_model = Art.model(kind, 0.8)
		height = Art.model_height(kind, 0.8)
	_meal_view.add_child(_meal_model)
	_meal_model.position.y = -height * 0.5
	_meal_model.rotation.y = 0.35
	_meal_camera.size = maxf(2.6, height * 1.2)
	_meal_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	_last_meal.show()

func _panel(parent: Node) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(Color(PAPER, 0.96), 6)
	style.set_border_width_all(2)
	style.border_color = PAPER_EDGE
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _column(parent: Node) -> VBoxContainer:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	parent.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	return column

func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _button(parent: Node, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 50
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", PAPER)
	button.add_theme_color_override("font_pressed_color", PAPER)
	button.add_theme_color_override("font_focus_color", PAPER)
	button.add_theme_stylebox_override("normal", _style(TEAL, 6))
	button.add_theme_stylebox_override("hover", _style(TEAL.lightened(0.14), 6))
	button.add_theme_stylebox_override("pressed", _style(TEAL.darkened(0.15), 6))
	var focus := _style(Color(0, 0, 0, 0), 6)
	focus.set_border_width_all(2)
	focus.border_color = INK
	button.add_theme_stylebox_override("focus", focus)
	parent.add_child(button)
	return button

func _build_completion() -> void:
	completion = _panel(_root)
	completion.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	completion.offset_left = -200
	completion.offset_right = 200
	completion.offset_top = -215
	completion.offset_bottom = -105
	var column := _column(completion)
	var label := _label(column, "Goal reached", 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_button = _button(column, "Next level")
	next_button.pressed.connect(func(): scene_requested.emit((_scene_index + 1) % TITLES.size()))
	completion.hide()

func _build_menu() -> void:
	var error := _settings.load("user://settings.cfg")
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("Could not load movement settings: %s" % error_string(error))
	movement_speed = clampf(float(_settings.get_value("controls", "movement_speed", 2.0 if OS.has_feature("web") else 1.0)), 0.1, 2.0)
	body_kind = str(_settings.get_value("controls", "body", "shell"))
	music_enabled = bool(_settings.get_value("audio", "music", true))
	menu = _panel(_root)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -260
	menu.offset_right = 260
	menu.offset_top = -328
	menu.offset_bottom = 328
	var column := _column(menu)
	_caption(column, "SLIDE TRAY")
	_label(column, "Gray Goo", 34)
	for index in TITLES.size():
		var button := _button(column, "%02d · %s" % [index + 1, TITLES[index]])
		button.pressed.connect(func():
			menu.hide()
			pause_requested.emit(false)
			scene_requested.emit(index))
	var speed_label := _label(column, "Movement speed · %d%%" % roundi(movement_speed * 100.0), 22)
	var speed_slider := HSlider.new()
	speed_slider.min_value = 10.0
	speed_slider.max_value = 200.0
	speed_slider.step = 5.0
	speed_slider.value = movement_speed * 100.0
	speed_slider.custom_minimum_size.y = 30
	speed_slider.tooltip_text = "Adjust movement speed for both keyboard and mouse steering."
	column.add_child(speed_slider)
	speed_slider.value_changed.connect(func(value: float):
		movement_speed = value / 100.0
		speed_label.text = "Movement speed · %d%%" % roundi(value)
		_settings.set_value("controls", "movement_speed", movement_speed)
		var save_error := _settings.save("user://settings.cfg")
		if save_error != OK:
			push_error("Could not save movement settings: %s" % error_string(save_error)))
	var body_row := HBoxContainer.new()
	body_row.add_theme_constant_override("separation", 16)
	column.add_child(body_row)
	var body_label := _label(body_row, "Body", 22)
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bodies := OptionButton.new()
	bodies.add_item("Shell")
	bodies.add_item("Procedural")
	bodies.select(1 if body_kind == "procedural" else 0)
	bodies.custom_minimum_size = Vector2(230, 50)
	bodies.add_theme_font_size_override("font_size", 22)
	bodies.add_theme_color_override("font_color", PAPER)
	bodies.add_theme_color_override("font_hover_color", PAPER)
	bodies.add_theme_color_override("font_pressed_color", PAPER)
	bodies.add_theme_stylebox_override("normal", _style(TEAL, 6))
	bodies.add_theme_stylebox_override("hover", _style(TEAL.lightened(0.14), 6))
	bodies.add_theme_stylebox_override("pressed", _style(TEAL.darkened(0.15), 6))
	body_row.add_child(bodies)
	bodies.item_selected.connect(func(index: int):
		body_kind = "procedural" if index == 1 else "shell"
		_settings.set_value("controls", "body", body_kind)
		var save_error := _settings.save("user://settings.cfg")
		if save_error != OK:
			push_error("Could not save body setting: %s" % error_string(save_error))
		body_requested.emit(body_kind))
	_build_music_control(column)
	var resume := _button(column, "Resume")
	resume.pressed.connect(toggle_menu)
	menu.hide()

func _build_music_control(column: VBoxContainer) -> void:
	var music := _button(column, "Music · On" if music_enabled else "Music · Off")
	music.toggle_mode = true
	music.button_pressed = music_enabled
	music.toggled.connect(func(enabled: bool):
		music_enabled = enabled
		music.text = "Music · On" if enabled else "Music · Off"
		_settings.set_value("audio", "music", enabled)
		var error := _settings.save("user://settings.cfg")
		if error != OK:
			push_error("Could not save music setting: %s" % error_string(error))
		music_changed.emit(enabled))

func configure(index: int, config: Dictionary) -> void:
	_scene_index = index
	_config = config
	_meters_per_unit = float(config.meters_per_unit)
	_tier = -1
	title_label.text = config.title
	_build_ladder(config.tiers)
	gauge.flash = 0.0
	_last_meal.hide()
	completion.hide()
	menu.hide()
	hint_label.get_parent().modulate.a = 1.0
	_hint_time = 0.0

func update_game(radius: float, initial: float, goal: float, tier: int, camera: Camera3D,
		goo_position: Vector3, target_position: Vector3, target_name: String) -> void:
	var meters_per_unit := float(_config.meters_per_unit)
	if meters_per_unit != _meters_per_unit:
		_meters_per_unit = meters_per_unit
		gauge.flash = 1.0
	if tier != _tier:
		_tier = tier
		tier_label.text = "Tier %d of %d · %s" % [tier + 1, _rungs.size(), _config.tiers[tier]]
		_paint_ladder()
	gauge.fraction = clampf(log(radius / initial) / log(goal / initial), 0.0, 1.0)
	gauge.reading = format_size(radius * 2.0 * meters_per_unit)
	gauge.goal = "goal " + format_size(goal * 2.0 * meters_per_unit)
	gauge.queue_redraw()
	target_label.text = target_name if not target_name.is_empty() else "—"
	pointer.target_visible = not target_name.is_empty() and not menu.visible
	if pointer.target_visible:
		var center := camera.unproject_position(goo_position)
		var destination := camera.unproject_position(target_position)
		pointer.direction = (destination - center).normalized()
		var screen_radius := radius / camera.size * get_viewport().get_visible_rect().size.y
		pointer.position_on_screen = center + pointer.direction * (screen_radius + 33.0)
	pointer.queue_redraw()

# Sizes from a tenth of a light year upward read in light years, as astronomy does.
static func format_size(meters: float) -> String:
	for unit in [[LIGHT_YEAR * 1e9, "Gly"], [LIGHT_YEAR * 1e6, "Mly"], [LIGHT_YEAR * 1e3, "kly"], [LIGHT_YEAR * 0.1, "ly"],
			[1e12, "Tm"], [1e9, "Gm"], [1e6, "Mm"], [1e3, "km"], [1.0, "m"],
			[1e-2, "cm"], [1e-3, "mm"], [1e-6, "µm"], [1e-9, "nm"],
			[1e-12, "pm"], [1e-15, "fm"]]:
		if meters >= unit[0]:
			var divisor: float = LIGHT_YEAR if unit[1] == "ly" else float(unit[0])
			var size: float = meters / divisor
			var precision := 2 if size < 10.0 else (1 if size < 100.0 else 0)
			return ("%.*f %s" % [precision, size, unit[1]])
	return "%.2f fm" % (meters / 1e-15)

func show_completion() -> void:
	completion.show()
	next_button.text = "Back to the first slide" if _scene_index == TITLES.size() - 1 else "Next level"

func toggle_menu() -> void:
	menu.visible = not menu.visible
	pause_requested.emit(menu.visible)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if gauge.flash > 0.0:
		gauge.flash = maxf(gauge.flash - delta * 1.2, 0.0)
		gauge.queue_redraw()
	if not menu.visible:
		_hint_time += delta
		hint_label.get_parent().modulate.a = 1.0 if _hint_time < 18.0 else 0.45
