extends Control

signal start
signal update_polygon
var margin := 10

# UI elements
@export var iterations_label: Label
@export var menu_button: Button
@export var popup_container: PanelContainer

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


func _ready() -> void:
	popup_container.hide()
	
	# Setup UI Values
	max_points_spin_box.max_value = 999999999
	max_points_spin_box.value = Global.max_points
	
	steps_per_second_spin_box.max_value = 1000
	steps_per_second_spin_box.value = Global.steps_per_second
	
	unlimited_steps_per_second_check_button.button_pressed = Global.unlimited_steps_per_second
	
	points_per_step_spin_box.max_value = 1000000
	points_per_step_spin_box.min_value = 1
	points_per_step_spin_box.value = Global.points_per_step
	
	random_type_option_button.selected = Global.random_type
	
	polygon_vertices_spin_box.max_value = 100
	polygon_vertices_spin_box.value = Global.polygon_vertices
	
	show_polygon_vertices_check_button.button_pressed = Global.show_polygon_vertices
	
	show_polygon_lines_check_button.button_pressed = Global.show_polygon_lines
	
	polygon_vertex_size_spin_box.max_value = 100
	polygon_vertex_size_spin_box.value = Global.polygon_vertex_size
	
	point_size_spin_box.max_value = 100
	point_size_spin_box.value = Global.point_size
	
	use_point_colour_check_button.button_pressed = Global.use_point_colour
	
	use_point_opacity_check_button.button_pressed = Global.use_point_opacity

func _process(_delta: float) -> void:
	iterations_label.text = "Iterations: " + str(Global.point_count)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("play"):
		start.emit()

func _on_menu_button_pressed() -> void:
	if !menu_button.button_pressed:
		popup_container.hide()
	else:
		popup_container.show()
		popup_container.position =  menu_button.global_position + Vector2(0, menu_button.size.y + margin)

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
