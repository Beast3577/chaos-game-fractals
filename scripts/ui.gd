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

func _on_overwrite_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	save_settings(save_name, true)
	confirmation_margin_container.hide()

func _on_cancel_button_pressed() -> void:
	confirmation_margin_container.hide()

func save_settings(save_name: String, confirmation: bool):
	var saves_path = "user://saves/"
	if not DirAccess.open(saves_path):
		DirAccess.make_dir_absolute(saves_path)
	
	var file_name = saves_path + save_name + ".json"
	if FileAccess.file_exists(file_name) and !confirmation:
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nA file with the name '" + save_name +"' already exists.\nDo you wish to overwrite this file?"
	else:
		var save_file = FileAccess.open(file_name, FileAccess.WRITE)
		
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
		save_load_panel_margin_container.hide()

func load_settings(save_name: String):
	var file_name = "user://saves/" + save_name + ".json"
	if FileAccess.file_exists(file_name):
		var save_file = FileAccess.open(file_name, FileAccess.READ)
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
			create_label(save_name)
		save_name = dir.get_next()

func create_label(text: String) -> void:
	var button = Button.new()
	button.text = text.replace(".json", "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.connect("toggled", Callable(self, "_on_file_button_toggled").bind(button))
	save_file_VBox_Container.add_child(button)
	create_h_seperator(true, 0)

func create_h_seperator(empty_style_box: bool, separation: int) -> void:
	var h_seperator = HSeparator.new()
	h_seperator.add_theme_constant_override("separation", separation)
	if empty_style_box:
		h_seperator.add_theme_stylebox_override("separator", StyleBoxEmpty.new())
	save_file_VBox_Container.add_child(h_seperator)

func _on_file_button_toggled(button_pressed: bool, button: Button) -> void:
	if button_pressed:
		save_name_line_edit.text = button.text
		for child in save_file_VBox_Container.get_children():
			if child.get_class() == "Button":
				if child == button:
					continue
				else:
					child.button_pressed = false
			else:
				continue

func _on_save_button_pressed() -> void:
	save_load_panel_margin_container.show()
	load_save_load_panel_margin_container()
	save_load_panel_button.text = "Save"
	save_name_line_edit.placeholder_text = "Enter Save Name"

func _on_load_button_pressed() -> void:
	save_load_panel_margin_container.show()
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
