extends Control

signal start
var margin := 10
@export var iterations_label: Label
@onready var menu_button: Button = $MarginContainer2/MenuButton
@onready var popup_panel: PopupPanel = $MarginContainer2/PopupPanel


func _ready() -> void:
	popup_panel.hide()

func _process(delta: float) -> void:
	iterations_label.text = "Iterations: " + str(Global.point_count)

func _on_button_button_up() -> void:
	start.emit()

func _on_menu_button_pressed() -> void:
	popup_panel.visible = !popup_panel.visible
	if popup_panel.visible:
		popup_panel.position = menu_button.global_position + Vector2(0, menu_button.size.y + margin)
