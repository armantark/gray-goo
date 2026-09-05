class_name GameHUD
extends CanvasLayer

signal scene_requested(index: int)
signal pause_requested(paused: bool)

const INK := Color("122326")
const PAPER := Color("f3f8f5")
const TEAL := Color("277a68")
var title_label: Label
var size_label: Label
var target_label: Label
var goal_bar: ProgressBar
var completion: PanelContainer
var menu: PanelContainer
var next_button: Button
var hint_label: Label
var pointer: FoodPointer
var _root: Control
var _scene_index := 0
var _hint_time := 0.0
var _meters_per_unit: float
var movement_speed := 1.0
var _settings := ConfigFile.new()
var _last_meal: PanelContainer
var _meal_label: Label
var _meal_view: SubViewport
var _meal_camera: Camera3D
var _meal_model: Node3D
var _meal_kind := ""

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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.add_theme_color_override("font_color", PAPER)
	_root.add_theme_font_size_override("font_size", 22)
	var stats := _panel(_root)
	stats.position = Vector2(28, 26)
	stats.custom_minimum_size = Vector2(360, 0)
	var content := _column(stats)
	title_label = _label(content, "", 26)
	size_label = _label(content, "", 22)
	goal_bar = ProgressBar.new()
	goal_bar.custom_minimum_size = Vector2(320, 9)
	goal_bar.show_percentage = false
	goal_bar.add_theme_stylebox_override("background", _style(Color("38504c"), 4))
	goal_bar.add_theme_stylebox_override("fill", _style(Color("7fdfad"), 4))
	content.add_child(goal_bar)
	target_label = _label(content, "", 17)
	target_label.modulate = Color("c9ddd5")
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
	hint_label = _label(_root, "WASD / arrows  ·  Hold left mouse to steer  ·  Right-drag to rotate  ·  Scroll to zoom", 19)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint_label.offset_top = -53
	hint_label.offset_bottom = -22
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	hint_label.add_theme_constant_override("shadow_offset_x", 1)
	hint_label.add_theme_constant_override("shadow_offset_y", 2)
	_build_completion()
	_build_menu()
	_build_last_meal()

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
	_label(text, "Last eaten", 17).modulate = Color("c9ddd5")
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
	panel.add_theme_stylebox_override("panel", _style(Color(INK, 0.94), 12))
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
	label.add_theme_color_override("font_color", PAPER)
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
	button.add_theme_stylebox_override("normal", _style(TEAL, 8))
	button.add_theme_stylebox_override("hover", _style(TEAL.lightened(0.14), 8))
	button.add_theme_stylebox_override("pressed", _style(TEAL.darkened(0.15), 8))
	var focus := _style(Color(0, 0, 0, 0), 8)
	focus.set_border_width_all(2)
	focus.border_color = Color("f4d277")
	button.add_theme_stylebox_override("focus", focus)
	parent.add_child(button)
	return button

func _build_completion() -> void:
	completion = _panel(_root)
	completion.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	completion.offset_left = -200
	completion.offset_right = 200
	completion.offset_top = -180
	completion.offset_bottom = -75
	var column := _column(completion)
	var label := _label(column, "Goal reached", 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_button = _button(column, "Next level")
	next_button.pressed.connect(func(): scene_requested.emit((_scene_index + 1) % 4))
	completion.hide()

func _build_menu() -> void:
	var error := _settings.load("user://settings.cfg")
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("Could not load movement settings: %s" % error_string(error))
	movement_speed = clampf(float(_settings.get_value("controls", "movement_speed", 1.0)), 0.1, 2.0)
	menu = _panel(_root)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -260
	menu.offset_right = 260
	menu.offset_top = -280
	menu.offset_bottom = 280
	var column := _column(menu)
	_label(column, "Gray Goo", 34)
	var titles := ["Quark Dust Ladder", "Coral Colony Tide Pool", "Skatepark Bowl", "Tablecloth of Everything"]
	for index in titles.size():
		var button := _button(column, titles[index])
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
	var resume := _button(column, "Resume")
	resume.pressed.connect(toggle_menu)
	menu.hide()

func configure(index: int, config: Dictionary) -> void:
	_scene_index = index
	_meters_per_unit = float(config.meters_per_unit)
	size_label.tooltip_text = "Goo body diameter and the diameter needed to finish this scene."
	title_label.text = config.title
	_last_meal.hide()
	completion.hide()
	menu.hide()
	hint_label.modulate.a = 1.0
	_hint_time = 0.0

func update_game(radius: float, initial: float, goal: float, camera: Camera3D,
		goo_position: Vector3, target_position: Vector3, target_name: String) -> void:
	size_label.text = "%s   /   %s goal" % [format_size(radius * 2.0 * _meters_per_unit), format_size(goal * 2.0 * _meters_per_unit)]
	goal_bar.value = clampf((radius - initial) / (goal - initial) * 100.0, 0.0, 100.0)
	target_label.text = target_name
	pointer.target_visible = not target_name.is_empty() and not menu.visible
	if pointer.target_visible:
		var center := camera.unproject_position(goo_position)
		var destination := camera.unproject_position(target_position)
		pointer.direction = (destination - center).normalized()
		var screen_radius := radius / camera.size * get_viewport().get_visible_rect().size.y
		pointer.position_on_screen = center + pointer.direction * (screen_radius + 33.0)
	pointer.queue_redraw()

static func format_size(meters: float) -> String:
	for unit in [[1e24, "Ym"], [1e21, "Zm"], [1e18, "Em"], [1e15, "Pm"],
			[1e12, "Tm"], [1e9, "Gm"], [1e6, "Mm"], [1e3, "km"], [1.0, "m"],
			[1e-2, "cm"], [1e-3, "mm"], [1e-6, "µm"], [1e-9, "nm"],
			[1e-12, "pm"], [1e-15, "fm"]]:
		if meters >= unit[0]:
			var size: float = meters / float(unit[0])
			var precision := 2 if size < 10.0 else (1 if size < 100.0 else 0)
			return ("%.*f %s" % [precision, size, unit[1]])
	return "%.2f fm" % (meters / 1e-15)

func show_completion() -> void:
	completion.show()
	next_button.text = "Back to particles" if _scene_index == 3 else "Next level"

func toggle_menu() -> void:
	menu.visible = not menu.visible
	pause_requested.emit(menu.visible)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not menu.visible:
		_hint_time += delta
		hint_label.modulate.a = 1.0 if _hint_time < 18.0 else 0.45
