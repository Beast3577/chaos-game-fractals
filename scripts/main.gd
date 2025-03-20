extends Node2D

# onready node variables
@export var points: MultiMeshInstance2D
@export var ui: Control
@export var sub_viewport: SubViewport
@export var finalised_points: MultiMeshInstance2D
@export var draw_lines: Node2D

var polygon_vertices: Array # array of Vector2s containing the screen coordinates of each vertex

var margin: int = 50 # distance that vertices stay from the edge in pixels
var window_size: Vector2 # the window size
var starting_point := Vector2(0, 0) # default starting coordinates for first point


# called when the node is "ready", i.e. when both the node and its children have entered the scene tree
func _ready() -> void:
	# connect window size change signal and setup window_size variable
	get_viewport().connect("size_changed", _on_viewport_size_changed)
	window_size = get_viewport().get_visible_rect().size
	sub_viewport.size = window_size
	
	update_polygon() # initial generation and placement of the polygon vertices

# called when the window is resized, updates window_size variable and updates polygon to fit
func _on_viewport_size_changed() -> void:
	if !Global.started:
		window_size = get_viewport().get_visible_rect().size
		sub_viewport.size = window_size # ensures the sub viewport containing finalised points is the same size as everything else which is based off window_size
		update_polygon()
		queue_redraw()

# called when there is an input event
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_right") and !Global.started: # if left click is pressed 
		starting_point = get_global_mouse_position() # sets the starting point to mouse position if not started generating points
		queue_redraw() # redraws screen so point is displayed

# called when CanvasItem has been requested to redraw (after queue_redraw() is called, either manually or by the engine)
func _draw() -> void:
	# draws polygon vertices if show_polygon_vertices is true
	if Global.show_polygon_vertices:
		for vertex in polygon_vertices:
			draw_circle(vertex, Global.polygon_vertex_size, Color.WHITE)
	# draws polygon lines if show_polygon_lines is true
	if Global.show_polygon_lines:
		for vertex in polygon_vertices:
			# loops through each vertex to draw a line between it and the next vertex, if its the last vertex in the array it wraps around to the first vertex
			if vertex == polygon_vertices.back():
				draw_line(vertex, polygon_vertices.front(), Color.WHITE)
			else:
				draw_line(vertex, polygon_vertices[polygon_vertices.find(vertex) + 1], Color.WHITE)
	
	# draws the starting point if dictated by user
	if Global.show_starting_point:
		draw_circle(starting_point, Global.polygon_vertex_size, Color.WHITE)

# dynamically generates the polygon vertices depending on n, the number of vertices dictated by the user, returns an array of vertices
func generate_polygon_vertices(n: float, radius: float, center: Vector2) -> Array:
	var vertices: Array
	# magic maths shit that actually figues out where the vertices are placed
	for i in n:
		var angle: float = i * TAU / n # TAU = 2 * PI
		var x: float = center.x + sin(angle) * radius
		var y: float = center.y - cos(angle) * radius
		vertices.append(Vector2(x, y))
	# adds a center point if dictated by user
	if Global.use_midpoint:
		vertices.append(center)
	return vertices

# main function for handling the generation and drawing of the polygon everytime it needs to be redrawn for various reasons
func update_polygon() -> void:
	polygon_vertices = generate_polygon_vertices(Global.polygon_vertices, min(window_size.x, window_size.y)/2 - margin, Vector2(window_size.x/2, window_size.y/2))
	queue_redraw()

# called with signal "start" from ui, starts generating points
func _on_ui_start() -> void:
	if !Global.started: # if points havent started being generated it sets everything up
		points.generate_point_colours(polygon_vertices)
		points.setup_multimesh(Global.multimesh_instance_batch_size, true) # start_running = true, starts iterations
		points.previous_points[0] = starting_point # initialises the starting point
		start()
	else: # otherwise the point generation is just unpausing
		points.running = true

# called with signal "stop" from ui, stops generating points
func _on_ui_stop() -> void:
	points.running = false

# called with signal "step" from ui, runs the point generation for a single step
func _on_ui_step() -> void:
	if !Global.started: # makes sure everything is setup if it hasn't already
		points.setup_multimesh(Global.multimesh_instance_batch_size, false) # start_running = false, doesn't start iterations
		points.generate_point_colours(polygon_vertices)
		points.previous_points[0] = starting_point # initialises the starting point
		# making sure the program knows whats going on
		start()
	points.stepping = true

# called with signal "reset" from ui, resets various things for the program to reset correctly
func _on_ui_reset() -> void:
	# state of simulation variables
	points.running = false
	Global.started = false
	Global.point_count = 0
	
	points.multimesh.visible_instance_count = 0 # hides all instances so the ghost instances are hidden
	finalised_points.multimesh = points.multimesh.duplicate() # applies the same to finalised points
	# clears sub_viewport so the finalised points are properly hidden
	sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	ui.disable_settings(false) # re-enable disabled settings
	draw_lines.draw_line_between_points(null, null)
	
# does all the things that need to be done when the program starts generating points
func start() -> void:
	Global.started = true
	ui.disable_settings(true)

# called with signal "update_polygon" from ui, when the polygon needs to be updated from the ui.gd script
func _on_ui_update_polygon() -> void:
	update_polygon()
