extends Node2D

@onready var points: MultiMeshInstance2D = $Points
@onready var ui: Control = $CanvasLayer/UI

var polygon_vertices: Array

var margin: int = 50
var window_size: Vector2

var started: bool = false
var start_time

func _ready() -> void:
	ui.connect("start", _on_ui_start)
	ui.connect("update_polygon", _on_ui_update_polygon)
	get_viewport().connect("size_changed", _on_viewport_size_changed)
	
	window_size = get_viewport().get_visible_rect().size
	
	update_polygon()
  
func _on_viewport_size_changed() -> void:
	if !started:
		window_size = get_viewport().get_visible_rect().size
		update_polygon()

func _draw() -> void:
	if Global.show_polygon_vertices:
		for vertex in polygon_vertices:
			draw_circle(vertex, Global.polygon_vertex_size, Color.WHITE)
	if Global.show_polygon_lines:
		for vertex in polygon_vertices:
			if vertex == polygon_vertices.back():
				draw_line(vertex, polygon_vertices.front(), Color.WHITE)
			else:
				draw_line(vertex, polygon_vertices[polygon_vertices.find(vertex) + 1], Color.WHITE)

func generate_polygon_vertices(n: float, radius: float, center: Vector2) -> Array:
	var vertices: Array
	for i in n:
		var angle = i * TAU / n # TAU = 2 * PI
		var x = center.x + sin(angle) * radius
		var y = center.y - cos(angle) * radius
		
		vertices.append(Vector2(x, y))
	return vertices

func update_polygon() -> void:
	polygon_vertices = generate_polygon_vertices(Global.polygon_vertices, min(window_size.x, window_size.y)/2 - margin, Vector2(window_size.x/2, window_size.y/2))
	queue_redraw()

func _on_ui_start() -> void:
	started = true
	points.setup_multimesh(Global.max_points)
	points.start_generate_points(polygon_vertices)

func _on_ui_update_polygon() -> void:
	update_polygon()
