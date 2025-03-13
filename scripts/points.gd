extends MultiMeshInstance2D

@onready var point_timer: Timer = $"../PointTimer"

var polygon_vertices: Array
var polygon_previous_vertices: Array = [Vector2(0, 0), Vector2(0, 0), Vector2(1, 1)]
var vertex_colours: Dictionary
var opacity: float
var previous_point := Vector2(0, 0)

var window_size: Vector2
var started := false


func _ready():
	window_size = get_viewport().get_visible_rect().size

func _process(_delta: float) -> void:
	if started and Global.point_count < Global.max_points:
		if Global.unlimited_steps_per_second:
			for i in Global.points_per_step:
				var vertex := random_polygon_vertex(polygon_vertices)
				previous_point = find_midpoint(previous_point, vertex)
				add_point(previous_point, vertex_colours[vertex])
		elif point_timer.is_stopped():
			point_timer.wait_time = 1 / Global.steps_per_second
			point_timer.start()
	else:
		started = false

func setup_multimesh(count: int):
	# Create and set up the MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = PointMesh.new() # A simple point mesh to represent each point
	multimesh.instance_count = count # Set the instance count for the MultiMesh
	started = true

func start_generate_points(vertices) -> void:
	polygon_vertices = vertices
	if Global.use_point_opacity:
		opacity = Global.point_opacity
	else:
		opacity = 1.0
	
	for i in polygon_vertices:
		if Global.use_point_colour:
			vertex_colours[i] = Color.from_hsv(float(polygon_vertices.find(i)) / len(polygon_vertices), 1.0, 1.0, opacity)
		else:
			vertex_colours[i] = Color.from_hsv(1.0, 0.0, 1.0, opacity)

func random_polygon_vertex(vertices: Array) -> Vector2:
	polygon_previous_vertices.pop_front()
	polygon_previous_vertices.append(vertices[randi_range(0, len(vertices) - 1)])
	
	if Global.random_type == 1:
		while polygon_previous_vertices[1] == polygon_previous_vertices[2]:
			polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
		return polygon_previous_vertices[2]
	
	elif Global.random_type == 2:
		if polygon_previous_vertices[0] == polygon_previous_vertices[1]:
			while true:
				var index_difference = vertices.find(polygon_previous_vertices[1]) - vertices.find(polygon_previous_vertices[2])
				if index_difference == 1 or index_difference == -1:
					polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
				elif index_difference == len(vertices) - 1 or index_difference == -(len(vertices) - 1):
					polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
				else:
					break
			return polygon_previous_vertices[2]
		else:
			return polygon_previous_vertices[2]
	else:
		return polygon_previous_vertices[2]

func find_midpoint(a: Vector2, b: Vector2) -> Vector2:
	var midpoint := (a + b)/2
	return midpoint

func add_point(pos: Vector2, colour):
	multimesh.set_instance_transform_2d(Global.point_count, Transform2D(0, pos))
	multimesh.set_instance_color(Global.point_count, colour)
	Global.point_count += 1

func _on_point_timer_timeout() -> void:
	for i in Global.points_per_step:
		var vertex := random_polygon_vertex(polygon_vertices)
		previous_point = find_midpoint(previous_point, vertex)
		add_point(previous_point, vertex_colours[vertex])
