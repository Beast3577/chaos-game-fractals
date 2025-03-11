extends MultiMeshInstance2D

var points_per_frame := 100000
var max_points := 10000000 # Initial capacity

var polygon_vertices: Array
var vertex_colours: Dictionary
var previous_point := Vector2(0, 0)

var window_size: Vector2
var started := false

signal finished

func _ready():
	window_size = get_viewport().get_visible_rect().size
	setup_multimesh(max_points)

func _process(_delta: float) -> void:
	if started:
		if Global.point_count < max_points:
			for i in points_per_frame:
				var vertex := random_polygon_vertex(polygon_vertices)
				previous_point = find_midpoint(previous_point, vertex)
				add_point(previous_point, vertex_colours[vertex])
		else:
			started = false
			finished.emit()

func setup_multimesh(count: int):
	# Create and set up the MultiMesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = PointMesh.new() # A simple point mesh to represent each point
	multimesh.instance_count = count # Set the instance count for the MultiMesh

func start_generate_points(vertices) -> void:
	polygon_vertices = vertices
	for i in polygon_vertices:
		vertex_colours[i] = Color.from_hsv(i.x, 1.0, 1.0, 0.1)
	started = true


func random_polygon_vertex(vertices: Array) -> Vector2:
	var point: Vector2 = vertices[randi_range(0, len(vertices) - 1)]
	return point

func find_midpoint(a: Vector2, b: Vector2) -> Vector2:
	var midpoint := (a + b)/2
	return midpoint

func add_point(pos: Vector2, colour):
	multimesh.set_instance_transform_2d(Global.point_count, Transform2D(0, pos))
	multimesh.set_instance_color(Global.point_count, colour)
	Global.point_count += 1
