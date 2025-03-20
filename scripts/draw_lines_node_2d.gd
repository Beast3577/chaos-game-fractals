extends Node2D

# global of the necessary points
var previous_point
var chosen_vertex

# called when CanvasItem has been requested to redraw (after queue_redraw() is called, either manually or by the engine)
func _draw() -> void:
	if chosen_vertex: # if a vertex exists
		draw_line(previous_point, chosen_vertex, Color.DIM_GRAY) # draws the line between given points

func draw_line_between_points(point, vertex) -> void: # sets the two global variables and queue_redraw() calls _draw()
	previous_point = point
	chosen_vertex = vertex
	queue_redraw()
