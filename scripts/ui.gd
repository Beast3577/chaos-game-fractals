extends Control

signal start
signal stop
signal step
signal update_polygon
var margin := 10

# UI elements
@export var iterations_label: Label
@export var menu_button: Button
@export var start_button: Button
@export var step_button: Button
@export var reset_button: Button

@export var settings_panel_margin_container: MarginContainer
@export var scroll_container: ScrollContainer

@export var max_points_spin_box: SpinBox
@export var steps_per_second_spin_box: SpinBox
@export var points_per_step_spin_box: SpinBox
@export var unlimited_steps_per_second_check_button: CheckButton
@export var random_type_option_button: OptionButton
@export var polygon_vertices_spin_box: SpinBox
@export var show_polygon_vertices_check_button: CheckButton
@export var show_polygon_lines_check_button: CheckButton
@export var polygon_vertex_size_spin_box: SpinBox
@export var point_size_spin_box: SpinBox
@export var use_point_colour_check_button: CheckButton
@export var use_point_opacity_check_button: CheckButton
@export var use_midpoint_check_button: CheckButton

@export var save_load_panel_margin_container: MarginContainer
@export var save_load_panel_button: Button
@export var save_name_line_edit: LineEdit
@export var save_file_VBox_Container: VBoxContainer

@export var confirmation_margin_container: MarginContainer
@export var warning_rich_text_label: RichTextLabel
@export var overwrite_button: Button

@export var context_menu_popup_panel: PopupPanel

var file_button_menu_texture = preload("res://assets/icons/dot_menu_vertical_icon_white.png")


func _ready() -> void:
	save_load_panel_margin_container.hide()
	confirmation_margin_container.hide()

	if Global.menu_button_pressed:
		settings_panel_margin_container.show()
		scroll_container.scroll_horizontal = Global.scroll_horizontal
		scroll_container.scroll_vertical = Global.scroll_vertical
		menu_button.set_pressed_no_signal(true)
	else:
		settings_panel_margin_container.hide()
		menu_button.set_pressed_no_signal(false)
	
	set_ui_values_to_global()

func _process(_delta: float) -> void:
	iterations_label.text = "Iterations: " + str(Global.point_count)

func _on_menu_button_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		settings_panel_margin_container.hide()
	else:
		settings_panel_margin_container.show()

func _on_start_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		start.emit()
		start_button.text = "Stop"
	else:
		stop.emit()
		start_button.text = "Start"

func _on_step_button_pressed() -> void:
	step.emit()

func _on_reset_button_pressed() -> void:
	Global.menu_button_pressed = menu_button.button_pressed
	Global.scroll_horizontal = scroll_container.scroll_horizontal
	Global.scroll_vertical = scroll_container.scroll_vertical
	get_tree().reload_current_scene()
	Global.point_count = 0

func save_settings(save_name: String, confirmation: bool):
	var saves_path = "user://saves/"
	if not DirAccess.open(saves_path):
		DirAccess.make_dir_absolute(saves_path)
	
	var file_path = saves_path + save_name + ".json"
	if FileAccess.file_exists(file_path) and !confirmation:
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nA file with the name '" + save_name +"' already exists.\nDo you wish to overwrite this file?"
		overwrite_button.text = "Overwrite"
		overwrite_button.set_meta("confirmation_type", 0)
	elif save_name == "":
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nThis file does not have a name.\nA name is required to proceed."
		overwrite_button.text = "Continue"
		overwrite_button.set_meta("confirmation_type", 1)
	else:
		var save_file = FileAccess.open(file_path, FileAccess.WRITE)
		
		var save_dict = {
			"max_points" : Global.max_points,
			"steps_per_second" : Global.steps_per_second,
			"unlimited_steps_per_second" : Global.unlimited_steps_per_second,
			"points_per_step" : Global.points_per_step,
			"random_type" : Global.random_type,
			"polygon_vertices" : Global.polygon_vertices,
			"show_polygon_vertices" : Global.show_polygon_vertices,
			"show_polygon_lines" : Global.show_polygon_lines,
			"polygon_vertex_size" : Global.polygon_vertex_size,
			"point_size" : Global.point_size,
			"use_point_colour" : Global.use_point_colour,
			"use_point_opacity" : Global.use_point_opacity,
			"point_opacity" : Global.point_opacity,
			"use_midpoint" : Global.use_midpoint
		}
		if save_file:
			save_file.store_line(JSON.stringify(save_dict, "\t"))
			save_file.close()
		load_save_load_panel_margin_container()

func load_settings(save_name: String):
	var file_path = "user://saves/" + save_name + ".json"
	if FileAccess.file_exists(file_path):
		var save_file = FileAccess.open(file_path, FileAccess.READ)
		if save_file:
			var json_string = save_file.get_as_text()
			save_file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			if parse_result == OK:
				var data = json.get_data()
				for key in data:
					Global.set(key, data[key])
			
			set_ui_values_to_global()
			update_polygon.emit()
			save_load_panel_margin_container.hide()

func load_save_load_panel_margin_container() -> void:
	save_name_line_edit.text = ""
	
	for child in save_file_VBox_Container.get_children():
		child.queue_free()
	
	var saves_path = "user://saves/"
	var dir = DirAccess.open(saves_path)
	
	dir.list_dir_begin()
	var save_name = dir.get_next()
	
	while save_name != "":
		if not dir.current_is_dir():
			create_button(save_name)
		save_name = dir.get_next()
	save_load_panel_margin_container.show()

func create_button(text: String) -> void:
	var button = Button.new()
	var file_menu_button = Button.new()
	
	button.text = text.replace(".json", "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.connect("toggled", Callable(self, "_on_file_button_toggled").bind(button))
	
	file_menu_button.icon = file_button_menu_texture
	file_menu_button.expand_icon = true
	file_menu_button.flat = true
	file_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	file_menu_button.z_index = 1
	file_menu_button.connect("pressed", Callable(self, "_on_file_menu_button_toggled").bind(button))
	button.add_child(file_menu_button)
	save_file_VBox_Container.add_child(button)
	
	var file_menu_button_size = button.size.y
	file_menu_button.set_size(Vector2(file_menu_button_size, file_menu_button_size))
	file_menu_button.position.x = button.size.x - file_menu_button_size
	file_menu_button.hide()
	create_h_seperator(true, 0)

func create_h_seperator(empty_style_box: bool, separation: int) -> void:
	var h_seperator = HSeparator.new()
	h_seperator.add_theme_constant_override("separation", separation)
	if empty_style_box:
		h_seperator.add_theme_stylebox_override("separator", StyleBoxEmpty.new())
	save_file_VBox_Container.add_child(h_seperator)

func _on_file_button_toggled(button_pressed: bool, button: Button) -> void:
	if button_pressed:
		button.get_child(0).show()
		save_name_line_edit.text = button.text
		for child in save_file_VBox_Container.get_children():
			if child.get_class() == "Button":
				if child == button:
					continue
				else:
					child.button_pressed = false
					child.get_child(0).hide()
			else:
				continue
	else:
		button.get_child(0).hide()
		save_name_line_edit.text = ""

func _on_file_menu_button_toggled(button) -> void:
	context_menu_popup_panel.popup()
	context_menu_popup_panel.position = get_global_mouse_position()

func _on_overwrite_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	if overwrite_button.get_meta("confirmation_type") == 1:
		save_settings(save_name, false)
	elif overwrite_button.get_meta("confirmation_type") == 2:
		DirAccess.remove_absolute("user://saves/" + save_name + ".json")
		load_save_load_panel_margin_container()
	else:
		save_settings(save_name, true)
	confirmation_margin_container.hide()

func _on_cancel_button_pressed() -> void:
	confirmation_margin_container.hide()

func _on_save_button_pressed() -> void:
	save_load_panel_margin_container.show()
	load_save_load_panel_margin_container()
	save_load_panel_button.text = "Save"
	save_name_line_edit.placeholder_text = "Enter Save Name"

func _on_load_button_pressed() -> void:
	load_save_load_panel_margin_container()
	save_load_panel_button.text = "Load"
	save_name_line_edit.placeholder_text = "Enter Load Name"

func _on_cancel_panel_button_pressed() -> void:
	save_load_panel_margin_container.hide()

func _on_save_load_panel_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	if save_load_panel_button.text == "Save":
		save_settings(save_name, false)
	else:
		load_settings(save_name)

func _on_open_file_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	var file_path = "user://saves/" + save_name + ".json"
	var absolute_file_path = ProjectSettings.globalize_path(file_path)
	OS.execute("notepad.exe", [absolute_file_path])
	context_menu_popup_panel.hide()

func _on_delete_file_button_pressed() -> void:
	confirmation_margin_container.show()
	context_menu_popup_panel.hide()
	var save_name = save_name_line_edit.text
	warning_rich_text_label.text = "Warning\nDeleting file '" + save_name +"' cannot be undone.\nAre you sure you wish to continue?"
	overwrite_button.text = "Continue"
	overwrite_button.set_meta("confirmation_type", 2)

func _on_max_points_spin_box_value_changed(value: float) -> void:
	Global.max_points = int(value)

func _on_steps_per_second_spin_box_value_changed(value: float) -> void:
	Global.steps_per_second = value

func _on_unlimited_steps_per_second_check_button_toggled(toggled_on: bool) -> void:
	Global.unlimited_steps_per_second = toggled_on

func _on_points_per_step_spin_box_value_changed(value: float) -> void:
	Global.points_per_step = value

func _on_random_type_option_button_item_selected(index: int) -> void:
	Global.random_type = index

func _on_polygon_vertices_spinbox_value_changed(value: float) -> void:
	Global.polygon_vertices = value
	update_polygon.emit()

func _on_show_polygon_vertices_check_button_toggled(toggled_on: bool) -> void:
	Global.show_polygon_vertices = toggled_on
	update_polygon.emit()

func _on_show_polygon_lines_check_button_toggled(toggled_on: bool) -> void:
	Global.show_polygon_lines = toggled_on
	update_polygon.emit()

func _on_polygon_vertex_size_spin_box_value_changed(value: float) -> void:
	Global.polygon_vertex_size = value
	update_polygon.emit()

func _on_point_size_spin_box_value_changed(value: float) -> void:
	Global.point_size = value

func _on_use_point_colour_check_button_toggled(toggled_on: bool) -> void:
	Global.use_point_colour = toggled_on

func _on_use_point_opacity_check_button_toggled(toggled_on: bool) -> void:
	Global.use_point_opacity = toggled_on

func _on_use_midpoint_check_button_toggled(toggled_on: bool) -> void:
	Global.use_midpoint = toggled_on
	update_polygon.emit()

func set_ui_values_to_global() -> void:
	max_points_spin_box.max_value = 999999999
	max_points_spin_box.set_value_no_signal(Global.max_points)
	
	steps_per_second_spin_box.max_value = 1000
	steps_per_second_spin_box.set_value_no_signal(Global.steps_per_second)
	unlimited_steps_per_second_check_button.set_pressed_no_signal(Global.unlimited_steps_per_second)
	
	points_per_step_spin_box.max_value = 100000
	points_per_step_spin_box.set_value_no_signal(Global.points_per_step)
	points_per_step_spin_box.min_value = 1
	
	random_type_option_button.selected = Global.random_type
	
	polygon_vertices_spin_box.max_value = 100
	polygon_vertices_spin_box.set_value_no_signal(Global.polygon_vertices)
	
	show_polygon_vertices_check_button.set_pressed_no_signal(Global.show_polygon_vertices)
	
	show_polygon_lines_check_button.set_pressed_no_signal(Global.show_polygon_lines)
	
	polygon_vertex_size_spin_box.max_value = 100
	polygon_vertex_size_spin_box.set_value_no_signal(Global.polygon_vertex_size)
	
	point_size_spin_box.max_value = 100
	point_size_spin_box.set_value_no_signal(Global.point_size)
	
	use_point_colour_check_button.set_pressed_no_signal(Global.use_point_colour)
	use_point_opacity_check_button.set_pressed_no_signal(Global.use_point_opacity)
	
	use_midpoint_check_button.set_pressed_no_signal(Global.use_midpoint)
