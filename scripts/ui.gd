extends Control

signal start
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
	
	# set UI defaults
	max_points_spin_box.max_value = 999999999
	max_points_spin_box.value = 10000000
	
	steps_per_second_spin_box.max_value = 1000
	steps_per_second_spin_box.value = 1
	
	points_per_step_spin_box.max_value = 1000000
	points_per_step_spin_box.min_value = 1
	points_per_step_spin_box.value = 1
	
	unlimited_steps_per_second_check_button.button_pressed = false
	
	random_type_option_button.selected = 0
	
	polygon_vertices_spin_box.max_value = 100
	polygon_vertices_spin_box.value = 3
	
	show_polygon_vertices_check_button.button_pressed = true
	
	show_polygon_lines_check_button.button_pressed = true
	
	polygon_vertex_size_spin_box.max_value = 100
	polygon_vertex_size_spin_box.value = 4
	
	point_size_spin_box.max_value = 100
	point_size_spin_box.value = 1
	
	use_point_colour_check_button.button_pressed = false
	
	use_point_opacity_check_button.button_pressed = false

func _process(_delta: float) -> void:
	iterations_label.text = "Iterations: " + str(Global.point_count)

func _on_button_button_up() -> void:
	start.emit()

func _on_menu_button_pressed() -> void:
	if !menu_button.button_pressed:
		popup_container.hide()
	else:
		popup_container.show()
		popup_container.position =  menu_button.global_position + Vector2(0, menu_button.size.y + margin)
