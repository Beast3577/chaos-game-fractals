extends Node2D

@onready var points: MultiMeshInstance2D = $Points

var vertex_num: int = 5
var polygon_vertices: Array

var margin: int = 50
var window_size: Vector2

var started: bool = false
var start_time

func _ready() -> void:
	$CanvasLayer/UI.connect("start", _on_ui_start)
	get_viewport().connect("size_changed", _on_viewport_size_changed)
	
	window_size = get_viewport().get_visible_rect().size
	
	update_polygon()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("play"):
		started = true
		start_time = Time.get_ticks_msec()
		points.start_generate_points(polygon_vertices)
  
func _on_viewport_size_changed() -> void:
	if !started:
		window_size = get_viewport().get_visible_rect().size
		update_polygon()

func _draw() -> void:
	for vertex in polygon_vertices:
		draw_circle(vertex, 2, Color.BLACK)

func generate_polygon_vertices(n: int, radius: float, center: Vector2) -> Array:
	var vertices: Array
	for i in n:
		var angle = i * TAU / n # TAU = 2 * PI
		var x = center.x + sin(angle) * radius
		var y = center.y - cos(angle) * radius
		
		vertices.append(Vector2(x, y))
	return vertices

func update_polygon() -> void:
	polygon_vertices = generate_polygon_vertices(vertex_num, min(window_size.x, window_size.y)/2 - margin, Vector2(window_size.x/2, window_size.y/2))
	queue_redraw()

func _on_ui_start() -> void:
	started = true
	start_time = Time.get_ticks_msec()
	points.start_generate_points(polygon_vertices)

func _on_points_finished() -> void:
	var final_time: float = Time.get_ticks_msec() - start_time
	print("time elasped: " + str(final_time/1000) + " seconds")
