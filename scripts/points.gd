extends MultiMeshInstance2D

@onready var point_timer: Timer = $"../PointTimer" # timer which handles steps per second

var polygon_vertices: Array # global save of the polygon_vertices variable from main.gd, could maybe moved to global
var polygon_previous_vertices: Array = [Vector2(0, 0), Vector2(0, 0), Vector2(1, 1)] # saving the three previous chosen vertices for constraints, default values ensure no douleups so nothing gets influenced
var vertex_colours: Dictionary # dictionary containing the generated colour for each vertex, key is Vector2 position
var opacity: float # opacity of placed points
var previous_point := Vector2(0, 0) # previous point saved for calculating midpoint

var running: bool = false # are points currently being generated
var stepping: bool = false # are the points being generated for a single step


# called during the processing step of the main loop which happens at every frame and as fast as possible
func _process(_delta: float) -> void:
	if running and Global.point_count < Global.max_points: # stops generating points at max_points limit
		if Global.unlimited_steps_per_second: # generates with no limit if true
			for point in Global.points_per_step: # for each point in a single step, chooses random vertex, finds the midpoint and then addes the point
				var vertex: Vector2 = random_polygon_vertex(polygon_vertices)
				previous_point = find_midpoint(previous_point, vertex)
				add_point(previous_point, vertex_colours[vertex])
		elif point_timer.is_stopped(): # if the generation is limited with the timer and the timer has finished, it will restart
			point_timer.wait_time = 1 / Global.steps_per_second
			point_timer.start()
	elif stepping: # if it is only generating for a single step, runs the same code as before and sets stepping = false to indicate the step has finished
		for point in Global.points_per_step:
			var vertex: Vector2 = random_polygon_vertex(polygon_vertices)
			previous_point = find_midpoint(previous_point, vertex)
			add_point(previous_point, vertex_colours[vertex])
		stepping = false
	else: # if none of the above are valid, then the program shouldn't be considered running, basically just when its hit the max_point limit
		running = false

# create and set up the MultiMesh, the powerhouse of my code
func setup_multimesh(count: int, start_running: bool) -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = PointMesh.new() # A simple point mesh to represent each point
	multimesh.instance_count = count # Set the instance count for the MultiMesh
	
	if start_running: # if after the multimesh is setup should the program start iterating, will be false if stepping, otherwise true
		running = true

# called by main.gd to parse the locked in polygon vertices to points.gd as well as dynamically assigning them colour
func generate_point_colours(vertices) -> void:
	polygon_vertices = vertices # sets points.gd polygon_vertices = main.gd polygon_vertices
	
	# sets the necessary point opacity
	if Global.use_point_opacity:
		opacity = Global.point_opacity
	else:
		opacity = 1.0
	
	# for each polygon vertex sets its colour using the hsv colour space and some ChatGPT magic
	for vertex in polygon_vertices:
		if Global.use_point_colour:
			vertex_colours[vertex] = Color.from_hsv(float(polygon_vertices.find(vertex)) / len(polygon_vertices), 1.0, 1.0, opacity)
		else: # if colour isn't being used then they are just white
			vertex_colours[vertex] = Color.from_hsv(1.0, 0.0, 1.0, opacity)

# main function for choosing the random vertex based on contraints, returns the Vector2 position of chosen vertex 
func random_polygon_vertex(vertices: Array) -> Vector2:
	# removes the oldest chosen point and addes the new one (polygon_previous_vertices[2])
	polygon_previous_vertices.pop_front()
	polygon_previous_vertices.append(vertices[randi_range(0, len(vertices) - 1)])
	
	if Global.random_type == 1: # no double ups
		while polygon_previous_vertices[1] == polygon_previous_vertices[2]: # while the two newest points are the same, it'll keep regenerating
			polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
		return polygon_previous_vertices[2] # return chosen vertex
	
	elif Global.random_type == 2: # if it doubles up, next choice can't be a neighbour of the double up
		if polygon_previous_vertices[0] == polygon_previous_vertices[1]: # checks for double up
			while true: # loops until it is broken
				var index_difference: int = vertices.find(polygon_previous_vertices[1]) - vertices.find(polygon_previous_vertices[2]) # index difference, 1 or -1 means they are next to eachother in the Array
				if index_difference == 1 or index_difference == -1: # if the vertices are neighbours, it'll choose a new point
					polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
				elif index_difference == len(vertices) - 1 or index_difference == -(len(vertices) - 1): # if the vertices are neighbours, but considering if the first and last vertex in the array are being compared
					polygon_previous_vertices[2] = vertices[randi_range(0, len(vertices) - 1)]
				else: # if its neither the above, point is not a neighbour and loop is broken
					break
			return polygon_previous_vertices[2] # return chosen vertex
		else: # if no double up, it'll just return what it initially generated
			return polygon_previous_vertices[2] # return chosen vertex
	else: # true random, no constraints just whatever is generated is where it goes
		return polygon_previous_vertices[2] # return chosen vertex

# finds the midpoint between two vectors, returning the midpoint
func find_midpoint(a: Vector2, b: Vector2) -> Vector2:
	var midpoint: Vector2 = (a + b)/2
	return midpoint

# adds a calculated point to the multimeshinstance
func add_point(pos: Vector2, colour) -> void:
	multimesh.set_instance_transform_2d(Global.point_count, Transform2D(0, pos))
	multimesh.set_instance_color(Global.point_count, colour)
	Global.point_count += 1

# if the timer that controls the steps per second times out
func _on_point_timer_timeout() -> void:
	if running: # won't still generate if program has been paused
		for i in Global.points_per_step: # repeat of the code from before, should probably fix but oh welll
			var vertex: Vector2 = random_polygon_vertex(polygon_vertices)
			previous_point = find_midpoint(previous_point, vertex)
			add_point(previous_point, vertex_colours[vertex])
