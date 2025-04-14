extends Control

signal start
signal stop
signal step
signal update_polygon
signal reset
signal draw_line
signal finalise_points

var margin := 10


# UI elements
@export var iterations_label: Label
@export var menu_button: Button
@export var start_button: Button
@export var step_button: Button
@export var reset_button: Button
@onready var save_image_button: Button = $MenuButtonMarginContainer/HBoxContainer/SaveImageButton

@export var sub_viewport: SubViewport
@onready var finalised_points_sprite_2d: Sprite2D = $"../../FinalisedPointsSprite2D"

@export var settings_panel_margin_container: MarginContainer
@export var scroll_container: ScrollContainer

@export var unlimited_max_points_check_button: CheckButton
@export var max_points_spin_box: SpinBox
@export var unlimited_steps_per_second_check_button: CheckButton
@export var steps_per_second_spin_box: SpinBox
@export var points_per_step_spin_box: SpinBox
@export var random_type_option_button: OptionButton
@export var polygon_vertices_spin_box: SpinBox
@export var show_polygon_vertices_check_button: CheckButton
@export var show_polygon_lines_check_button: CheckButton
@export var use_midpoint_check_button: CheckButton
@export var polygon_vertex_size_spin_box: SpinBox
@export var point_size_spin_box: SpinBox
@export var use_point_colour_check_button: CheckButton
@export var use_point_opacity_check_button: CheckButton
@export var opacity_slider: HSlider
@export var show_starting_point_check_button: CheckButton
@export var show_lines_between_points_check_button: CheckButton
@export var background_color_picker_button: ColorPickerButton
@export var multimesh_instance_batch_size_spin_box: SpinBox
@export var show_iterations_check_button: CheckButton

@export var save_load_panel_margin_container: MarginContainer
@export var save_load_panel_button: Button
@export var save_name_line_edit: LineEdit
@export var save_file_VBox_Container: VBoxContainer
@export var thumbnail_texture_rect: TextureRect

@export var confirmation_margin_container: MarginContainer
@export var warning_rich_text_label: RichTextLabel
@export var overwrite_button: Button

@export var context_menu_popup_panel: PopupPanel

var file_button_menu_texture = preload("res://assets/icons/dot_menu_vertical_icon_white.png")
var save_image: Image
var save_path: String

func _ready() -> void:
	save_path = "user://saves/"
	if not DirAccess.open(save_path):
		DirAccess.make_dir_absolute(save_path)
	save_settings("default", true)
	
	var pictures_path = "user://pictures/"
	if not DirAccess.open(pictures_path):
		DirAccess.make_dir_absolute(pictures_path)
	
	save_load_panel_margin_container.hide()
	confirmation_margin_container.hide()
	context_menu_popup_panel.hide()
	settings_panel_margin_container.hide()
	
	var background_color_picker_popup_panel = background_color_picker_button.get_popup()
	background_color_picker_popup_panel.connect("about_to_popup", Callable(self, "_on_background_color_picker_popup_panel_about_to_popup"))
	
	set_ui_values_to_global()

func _process(_delta: float) -> void:
	iterations_label.text = "Iterations: " + str(Global.point_count)

func _on_menu_button_toggled(toggled_on: bool) -> void:
	if !toggled_on:
		settings_panel_margin_container.hide()
	else:
		settings_panel_margin_container.show()
	
func _on_save_image_button_pressed() -> void:
	finalise_points.emit(false)
	await RenderingServer.frame_post_draw
	
	load_save_load_panel_margin_container("user://pictures/")
	save_load_panel_button.text = "Save"
	save_load_panel_button.set_meta("origin", 2)
	save_name_line_edit.placeholder_text = "Enter Picture Name"
	
	if Global.point_count < 0:
		var image = finalised_points_sprite_2d.texture.get_image()
		image.convert(Image.FORMAT_RGBA8)
		
		save_image = Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
		save_image.fill(Color.from_string(Global.background_colour, Color.BLACK))
		save_image.blend_rect(image, Rect2(Vector2.ZERO, image.get_size()), Vector2.ZERO)
		
		thumbnail_texture_rect.texture = ImageTexture.create_from_image(save_image)

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
	if Global.started:
		reset.emit()
		start_button.button_pressed = false

func save_settings(save_name: String, confirmation: bool):
	var file_path: String
	if save_path == "user://saves/":
		file_path = save_path + save_name + ".json"
	else:
		file_path = save_path + save_name + ".png"
	
	if FileAccess.file_exists(file_path) and !confirmation:
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nA file with the name '" + save_name +"' already exists.\nDo you wish to overwrite this file?"
		overwrite_button.text = "Overwrite"
		overwrite_button.set_meta("confirmation_type", 0)
	elif save_name == "":
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nThis file does not have a name.\nA name is required to proceed."
		overwrite_button.text = "Continue"
		overwrite_button.add_theme_stylebox_override("hover", preload("res://themes/style boxes/saveload_hover_style_box_flat.tres"))
		overwrite_button.add_theme_stylebox_override("pressed", preload("res://themes/style boxes/saveload_pressed_style_box_flat.tres"))
		overwrite_button.add_theme_stylebox_override("normal", preload("res://themes/style boxes/saveload_normal_style_box_flat.tres"))
		
		overwrite_button.set_meta("confirmation_type", 1)
	else:
		if save_path == "user://saves/":
			var save_file = FileAccess.open(file_path, FileAccess.WRITE)
			
			var save_dict = {
				"unlimited_max_points" : Global.unlimited_max_points,
				"max_points" : Global.max_points,
				"unlimited_steps_per_second" : Global.unlimited_steps_per_second,
				"steps_per_second" : Global.steps_per_second,
				"points_per_step" : Global.points_per_step,
				"random_type" : Global.random_type,
				"polygon_vertices" : Global.polygon_vertices,
				"show_polygon_vertices" : Global.show_polygon_vertices,
				"show_polygon_lines" : Global.show_polygon_lines,
				"use_midpoint" : Global.use_midpoint,
				"polygon_vertex_size" : Global.polygon_vertex_size,
				"point_size" : Global.point_size,
				"use_point_colour" : Global.use_point_colour,
				"use_point_opacity" : Global.use_point_opacity,
				"point_opacity" : Global.point_opacity,
				"show_starting_point" : Global.show_starting_point,
				"show_line_between_points" : Global.show_line_between_points,
				"background_colour" : Global.background_colour,
				"multimesh_instance_batch_size" : Global.multimesh_instance_batch_size,
				"show_iterations" : Global.show_iterations
			}
			if save_file:
				save_file.store_line(JSON.stringify(save_dict, "\t"))
				save_file.close()
		else:
			save_image.save_png(file_path)
		load_save_load_panel_margin_container(save_path)

func load_settings(save_name: String):
	var file_path = "user://saves/" + save_name + ".json"
	if FileAccess.file_exists(file_path) and !Global.started:
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
	else:
		confirmation_margin_container.show()
		warning_rich_text_label.text = "Warning\nCannot load settings when program has started generating points.\nReset before you can load settings."
		overwrite_button.text = "Continue"
		overwrite_button.add_theme_stylebox_override("hover", preload("res://themes/style boxes/saveload_hover_style_box_flat.tres"))
		overwrite_button.add_theme_stylebox_override("pressed", preload("res://themes/style boxes/saveload_pressed_style_box_flat.tres"))
		overwrite_button.add_theme_stylebox_override("normal", preload("res://themes/style boxes/saveload_normal_style_box_flat.tres"))
		
		overwrite_button.set_meta("confirmation_type", 3)

func load_save_load_panel_margin_container(path: String) -> void:
	save_path = path
	save_name_line_edit.text = ""
	
	for child in save_file_VBox_Container.get_children():
		child.queue_free()
	
	var dir = DirAccess.open(path)
	
	dir.list_dir_begin()
	var save_name = dir.get_next()
	
	while save_name != "":
		if not dir.current_is_dir():
			create_button(save_name)
		save_name = dir.get_next()
	save_load_panel_margin_container.show()
	if save_path != "user://pictures/":
		thumbnail_texture_rect.get_parent().hide()
	else:
		thumbnail_texture_rect.get_parent().show()

func create_button(text: String) -> void:
	var button = Button.new()
	var file_menu_button = Button.new()
	
	if save_path == "user://saves/":
		button.text = text.replace(".json", "")
	else:
		button.text = text.replace(".png", "")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.toggle_mode = true
	button.connect("toggled", Callable(self, "_on_file_button_toggled").bind(button))
	
	file_menu_button.icon = file_button_menu_texture
	file_menu_button.expand_icon = true
	file_menu_button.flat = true
	file_menu_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	file_menu_button.z_index = 1
	file_menu_button.connect("pressed", Callable(self, "_on_file_menu_button_toggled"))
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
					if save_path == "user://pictures/":
						var file_path = save_path + save_name_line_edit.text + ".png"
						var image = Image.load_from_file(file_path)
						await RenderingServer.frame_post_draw
						thumbnail_texture_rect.texture = ImageTexture.create_from_image(image)
				else:
					child.button_pressed = false
					child.get_child(0).hide()
			else:
				save_name_line_edit.text = button.text
				continue
	else:
		button.get_child(0).hide()
		save_name_line_edit.text = ""
		if save_image:
			thumbnail_texture_rect.texture = ImageTexture.create_from_image(save_image)

func _on_file_menu_button_toggled() -> void:
	context_menu_popup_panel.popup()
	context_menu_popup_panel.position = get_global_mouse_position()

func _on_overwrite_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	if overwrite_button.get_meta("confirmation_type") == 1 or overwrite_button.get_meta("confirmation_type") == 3:
		if overwrite_button.get_meta("confirmation_type") == 1:
			save_settings(save_name, false)
		overwrite_button.remove_theme_stylebox_override("hover")
		overwrite_button.remove_theme_stylebox_override("pressed")
		overwrite_button.remove_theme_stylebox_override("normal")
	elif overwrite_button.get_meta("confirmation_type") == 2:
		if save_path == "user://saves/":
			DirAccess.remove_absolute(save_path + save_name + ".json")
		else:DirAccess.remove_absolute(save_path + save_name + ".png")
			
		load_save_load_panel_margin_container(save_path)
	else:
		save_settings(save_name, true)
	confirmation_margin_container.hide()

func _on_cancel_button_pressed() -> void:
	confirmation_margin_container.hide()

func _on_save_button_pressed() -> void:
	load_save_load_panel_margin_container("user://saves/")
	save_load_panel_button.text = "Save"
	save_load_panel_button.set_meta("origin", 0)
	save_name_line_edit.placeholder_text = "Enter Save Name"

func _on_load_button_pressed() -> void:
	load_save_load_panel_margin_container("user://saves/")
	save_load_panel_button.text = "Load"
	save_load_panel_button.set_meta("origin", 1)
	save_name_line_edit.placeholder_text = "Enter Load Name"

func _on_cancel_panel_button_pressed() -> void:
	save_load_panel_margin_container.hide()
	if start_button.button_pressed:
		start.emit()

func _on_save_load_panel_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	if save_load_panel_button.get_meta("origin") == 1:
		load_settings(save_name)
	elif save_load_panel_button.get_meta("origin") == 2:
		save_settings(save_name, false)
	else:
		save_settings(save_name, false)

func _on_open_file_button_pressed() -> void:
	var save_name = save_name_line_edit.text
	if save_path == "user://saves/":
		var file_path = save_path + save_name + ".json"
		var absolute_file_path = ProjectSettings.globalize_path(file_path)
		OS.execute("notepad.exe", [absolute_file_path])
	else:
		var file_path = save_path + save_name + ".png"
		var absolute_file_path = ProjectSettings.globalize_path(file_path)
		OS.shell_open(absolute_file_path)
	context_menu_popup_panel.hide()

func _on_delete_file_button_pressed() -> void:
	confirmation_margin_container.show()
	context_menu_popup_panel.hide()
	var save_name = save_name_line_edit.text
	warning_rich_text_label.text = "Warning\nDeleting file '" + save_name +"' cannot be undone.\nAre you sure you wish to continue?"
	overwrite_button.text = "Continue"
	overwrite_button.set_meta("confirmation_type", 2)

func _on_simulation_header_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		unlimited_max_points_check_button.get_parent().show()
	else:
		unlimited_max_points_check_button.get_parent().hide()

func _on_polygon_header_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		polygon_vertex_size_spin_box.get_parent().show()
	else:
		polygon_vertex_size_spin_box.get_parent().hide()

func _on_points_header_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		point_size_spin_box.get_parent().show()
	else:
		point_size_spin_box.get_parent().hide()

func _on_misc_header_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		show_starting_point_check_button.get_parent().show()
	else:
		show_starting_point_check_button.get_parent().hide()

func _on_advanced_settings_header_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		multimesh_instance_batch_size_spin_box.get_parent().show()
	else:
		multimesh_instance_batch_size_spin_box.get_parent().hide()

func _on_unlimited_max_points_check_button_toggled(toggled_on: bool) -> void:
	Global.unlimited_max_points = toggled_on
	if toggled_on:
		max_points_spin_box.hide()
	else:
		max_points_spin_box.show()

func _on_max_points_spin_box_value_changed(value: float) -> void:
	Global.max_points = int(value)

func _on_unlimited_steps_per_second_check_button_toggled(toggled_on: bool) -> void:
	Global.unlimited_steps_per_second = toggled_on
	if toggled_on:
		steps_per_second_spin_box.hide()
	else:
		steps_per_second_spin_box.show()

func _on_steps_per_second_spin_box_value_changed(value: float) -> void:
	Global.steps_per_second = value

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

func _on_use_midpoint_check_button_toggled(toggled_on: bool) -> void:
	Global.use_midpoint = toggled_on
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
	if toggled_on:
		opacity_slider.get_parent().show()
	else:
		opacity_slider.get_parent().hide()

func _on_opacity_slider_value_changed(value: float) -> void:
	Global.point_opacity = value

func _on_show_starting_point_check_button_toggled(toggled_on: bool) -> void:
	Global.show_starting_point = toggled_on
	update_polygon.emit()

func _on_show_lines_between_points_check_button_toggled(toggled_on: bool) -> void:
	Global.show_line_between_points = toggled_on
	draw_line.emit(toggled_on)

func _on_background_color_picker_button_color_changed(color: Color) -> void:
	Global.background_colour = color.to_html(true)
	RenderingServer.set_default_clear_color(color)

func _on_multimesh_instance_batch_size_spin_box_value_changed(value: float) -> void:
	Global.multimesh_instance_batch_size = int(value)
	points_per_step_spin_box.max_value = Global.multimesh_instance_batch_size

func _on_show_advanced_settings_check_button_toggled(toggled_on: bool) -> void:
	Global.show_advanced_settings = toggled_on
	if toggled_on:
		multimesh_instance_batch_size_spin_box.get_parent().show()
	else:
		multimesh_instance_batch_size_spin_box.get_parent().hide()

func _on_show_iterations_check_button_toggled(toggled_on: bool) -> void:
	Global.show_iterations = toggled_on
	if toggled_on:
		iterations_label.get_parent().show()
	else:
		iterations_label.get_parent().hide()

func disable_settings(disable: bool) -> void:
	max_points_spin_box.editable = !disable
	random_type_option_button.disabled = disable
	polygon_vertices_spin_box.editable = !disable
	use_midpoint_check_button.disabled = disable
	point_size_spin_box.editable = !disable
	use_point_colour_check_button.disabled = disable
	use_point_opacity_check_button.disabled = disable
	opacity_slider.editable = !disable
	multimesh_instance_batch_size_spin_box.editable = !disable

func set_ui_values_to_global() -> void:
	max_points_spin_box.max_value = 999999999
	max_points_spin_box.set_value_no_signal(Global.max_points)

	unlimited_steps_per_second_check_button.set_pressed_no_signal(Global.unlimited_steps_per_second)
	if Global.unlimited_steps_per_second:
		steps_per_second_spin_box.hide()
	steps_per_second_spin_box.max_value = 1000
	steps_per_second_spin_box.set_value_no_signal(Global.steps_per_second)
	
	points_per_step_spin_box.max_value = Global.multimesh_instance_batch_size
	points_per_step_spin_box.set_value_no_signal(Global.points_per_step)
	points_per_step_spin_box.min_value = 1
	
	random_type_option_button.selected = Global.random_type

	polygon_vertices_spin_box.max_value = 100
	polygon_vertices_spin_box.set_value_no_signal(Global.polygon_vertices)
	
	show_polygon_vertices_check_button.set_pressed_no_signal(Global.show_polygon_vertices)
	show_polygon_lines_check_button.set_pressed_no_signal(Global.show_polygon_lines)
	use_midpoint_check_button.set_pressed_no_signal(Global.use_midpoint)
	
	polygon_vertex_size_spin_box.max_value = 100
	polygon_vertex_size_spin_box.set_value_no_signal(Global.polygon_vertex_size)
	
	point_size_spin_box.max_value = 100
	point_size_spin_box.set_value_no_signal(Global.point_size)
	point_size_spin_box.min_value = 1
	
	use_point_colour_check_button.set_pressed_no_signal(Global.use_point_colour)
	use_point_opacity_check_button.set_pressed_no_signal(Global.use_point_opacity)
	
	opacity_slider.set_value_no_signal(Global.point_opacity)
	opacity_slider.min_value = 1.0
	if !Global.use_point_opacity:
		opacity_slider.get_parent().hide()
	show_starting_point_check_button.set_pressed_no_signal(Global.show_starting_point)
	
	show_lines_between_points_check_button.set_pressed_no_signal(Global.show_line_between_points)
	
	background_color_picker_button.color = Color.from_string(Global.background_colour, Color.BLACK)
	RenderingServer.set_default_clear_color(background_color_picker_button.color)
	
	multimesh_instance_batch_size_spin_box.max_value = 10000000
	multimesh_instance_batch_size_spin_box.set_value_no_signal(Global.multimesh_instance_batch_size)
	multimesh_instance_batch_size_spin_box.min_value = 10000
	
	show_iterations_check_button.set_pressed_no_signal(Global.show_iterations)
	if !Global.show_iterations:
		iterations_label.get_parent().hide()
