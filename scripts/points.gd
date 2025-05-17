extends MultiMeshInstance2D

# script variables
@export var draw_lines: Node2D
# node variables
@export var point_timer: Timer # timer which handles steps per second
@export var sub_viewport: SubViewport # sub viewport containing finalised points to be turned into a texture
@export var finalised_points: MultiMeshInstance2D # holds the most recent batch of generated points
@export var finalised_points_sprite_2d: Sprite2D # holds texture containing old 

var polygon_vertices: Array # global save of the polygon_vertices variable from main.gd, could maybe moved to global
var polygon_previous_vertices: Array = [Vector2(0, 0), Vector2(0, 0), Vector2(1, 1)] # saving the three previous chosen vertices for constraints, default values ensure no douleups so nothing gets influenced
var vertex_colours: Dictionary # dictionary containing the generated colour for each vertex, key is Vector2 position
var previous_points: Array = [Vector2(0, 0), Vector2(0, 0)] # previous point saved for calculating midpoint
var chosen_vertex: Vector2 # global var containing which vertex has currently been chosen

var running: bool = false # are points currently being generated
var stepping: bool = false # are the points being generated for a single step
var batch_point_count: int = 0 # how many points in the current batch have been generated

# called during the processing step of the main loop which happens at every frame and as fast as possible
func _process(_delta: float) -> void:
	if Global.unlimited_max_points or Global.point_count < Global.max_points: # stops generating points at max_points limit
		if running and batch_point_count <= (Global.multimesh_instance_batch_size - Global.points_per_step): # generates all the points in the current batch
			if Global.unlimited_steps_per_second: # generates with no limit if true
				for point in Global.points_per_step: # for each point in a single step, chooses random vertex, finds the midpoint and then addes the point
					chosen_vertex = random_polygon_vertex()
					previous_points.pop_front()
					previous_points.append(find_midpoint(previous_points[0], chosen_vertex))
					add_point(previous_points[1], vertex_colours[chosen_vertex])
			elif point_timer.is_stopped(): # if the generation is limited with the timer and the timer has finished, it will restart
				point_timer.wait_time = 1 / Global.steps_per_second
				point_timer.start()
		elif stepping and batch_point_count <= (Global.multimesh_instance_batch_size - Global.points_per_step): # if it is only generating for a single step, runs the same code as before and sets stepping = false to indicate the step has finished
			for point in Global.points_per_step:
				chosen_vertex = random_polygon_vertex()
				previous_points.pop_front()
				previous_points.append(find_midpoint(previous_points[0], chosen_vertex))
				add_point(previous_points[1], vertex_colours[chosen_vertex])
			stepping = false
		elif Global.started and batch_point_count >= (Global.multimesh_instance_batch_size - Global.points_per_step): # multimesh points are saved in duplicate multimesh and then active multimesh is reset
			# bool argument is var running as _on_ui_finalise_points() calls setup_multimesh() which requires that argument
			if running: 
				_on_ui_finalise_points(true)
			elif stepping:
				_on_ui_finalise_points(false)
		else: # the program shouldn't be considered running, which is basically just when stop has been pressed
			running = false

# create and set up the MultiMesh, the powerhouse of my code
func setup_multimesh(count: int, start_running: bool) -> void:
	# setup basic multimesh settings
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.instance_count = count
	multimesh.visible_instance_count = 0
	
	var quad_mesh = QuadMesh.new() # a simple quad mesh to represent each point
	quad_mesh.size = Vector2(Global.point_size, Global.point_size) # setting the point size
	
	# setting up shader so point colour works
	var point_colour_shader_material = ShaderMaterial.new()
	point_colour_shader_material.shader = preload("res://assets/shaders/point_colour.gdshader")
	quad_mesh.material = point_colour_shader_material
	
	multimesh.mesh = quad_mesh # apply mesh
	texture = preload("res://assets/point textures/full_circle.png") # apply texture
	
	multimesh.instance_count = count
	
	finalised_points.texture = preload("res://assets/point textures/full_circle.png")
	
	batch_point_count = 0 # resets batch count for new batch
	running = start_running # if after the multimesh is setup should the program start iterating, will be false if stepping, otherwise true
	
# called by main.gd to parse the locked in polygon vertices to points.gd as well as dynamically assigning them colour
func generate_point_colours(vertices: Array) -> void:
	polygon_vertices = vertices # sets points.gd polygon_vertices = main.gd polygon_vertices
	var opacity: float = 1.0 # sets up opacity var with 1.0 being the default value
	
	# sets the necessary point opacity
	if Global.use_point_opacity:
		opacity = Global.point_opacity / 100
	
	# for each polygon vertex sets its colour using the hsv colour space and some ChatGPT magic
	for vertex in polygon_vertices:
		if Global.use_point_colour:
			vertex_colours[vertex] = Color.from_hsv(float(polygon_vertices.find(vertex)) / len(polygon_vertices), 1.0, 1.0, opacity)
		else: # if colour isn't being used then they are just white
			vertex_colours[vertex] = Color.from_hsv(1.0, 0.0, 1.0, opacity)

# main function for choosing the random vertex based on contraints, returns the Vector2 position of chosen vertex 
func random_polygon_vertex() -> Vector2:
	# removes the oldest chosen point and addes the new one (polygon_previous_vertices[2])
	polygon_previous_vertices.pop_front()
	polygon_previous_vertices.append(polygon_vertices[randi_range(0, len(polygon_vertices) - 1)])
	
	if Global.random_type == 1: # no double ups
		while polygon_previous_vertices[1] == polygon_previous_vertices[2]: # while the two newest points are the same, it'll keep regenerating
			polygon_previous_vertices[2] = polygon_vertices[randi_range(0, len(polygon_vertices) - 1)]
		return polygon_previous_vertices[2] # return chosen vertex
	
	elif Global.random_type == 2: # if it doubles up, next choice can't be a neighbour of the double up
		if polygon_previous_vertices[0] == polygon_previous_vertices[1]: # checks for double up
			while true: # loops until it is broken
				var index_difference: int = polygon_vertices.find(polygon_previous_vertices[1]) - polygon_vertices.find(polygon_previous_vertices[2]) # index difference, 1 or -1 means they are next to eachother in the Array
				if index_difference == 1 or index_difference == -1: # if the vertices are neighbours, it'll choose a new point
					polygon_previous_vertices[2] = polygon_vertices[randi_range(0, len(polygon_vertices) - 1)]
				elif index_difference == len(polygon_vertices) - 1 or index_difference == -(len(polygon_vertices) - 1): # if the vertices are neighbours, but considering if the first and last vertex in the array are being compared
					polygon_previous_vertices[2] = polygon_vertices[randi_range(0, len(polygon_vertices) - 1)]
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
func add_point(pos: Vector2, colour: Color) -> void:
	multimesh.set_instance_transform_2d(batch_point_count, Transform2D(0, pos))
	multimesh.set_instance_color(batch_point_count, colour)
	# adds to batch and total point count
	Global.point_count += 1
	batch_point_count += 1
	
	multimesh.visible_instance_count = batch_point_count # hacky solution that only shows the points that have been generated so no ghost points
	
	# draws line between points if dictated by user
	if Global.show_line_between_points:
		_on_ui_draw_line(true)

# if the timer that controls the steps per second times out
func _on_point_timer_timeout() -> void:
	if running: # won't still generate if program has been paused
		for i in Global.points_per_step: # repeat of the code from before, should probably fix but oh welll
			chosen_vertex = random_polygon_vertex()
			previous_points.pop_front()
			previous_points.append(find_midpoint(previous_points[0], chosen_vertex))
			add_point(previous_points[1], vertex_colours[chosen_vertex])

# called on signal "draw_line" from ui, draws a line between necessary points
func _on_ui_draw_line(toggled) -> void:
	if Global.started and toggled:
		draw_lines.draw_line_between_points(previous_points[0], chosen_vertex)
	else:
		draw_lines.draw_line_between_points(null, null) # hides the line if toggled off

# called on signal "finalise_points" from ui, multimesh points are saved in duplicate multimesh and then active multimesh is reset
func _on_ui_finalise_points(start_running: bool) -> void:
	if Global.started:
		finalised_points.multimesh = multimesh.duplicate()
		await RenderingServer.frame_post_draw # waiting to make sure everything is done rendering
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE # updates the viewport once so points are shown, clear_mode is set to never when running so old points arent removed unless full reset
		await RenderingServer.frame_post_draw # more waiting

		finalised_points_sprite_2d.texture = ImageTexture.create_from_image(sub_viewport.get_texture().get_image())
		setup_multimesh(Global.multimesh_instance_batch_size, start_running)
