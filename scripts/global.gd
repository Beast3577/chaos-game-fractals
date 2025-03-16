extends Node

# values used for reset consistency
var point_count: int = 0 # resets to zero
# reset specific persistant values
var menu_button_pressed := false
var scroll_horizontal: int = 0
var scroll_vertical: int = 0

# Default Settings
var max_points: int = 1000000
var unlimited_steps_per_second: bool = false
var steps_per_second: float = 1
var points_per_step: float = 1

var random_type: int = 0

var polygon_vertices: float = 3
var show_polygon_vertices: bool = true
var show_polygon_lines: bool = true
var use_midpoint: bool = false
var polygon_vertex_size: float = 3

var point_size: float = 1 #
var use_point_colour: bool = false
var use_point_opacity: bool = false
var point_opacity: float = 10

var show_starting_point: bool = true

"""
TODO
- add disabling to relevant settings
	max points
	random type
	vertices
	use midpoint
	
	maybe if i figure out redrawing multimeshinstance:
	point size
	opacity
	

- point size - may need to use a custom circle mesh
- slow down on higher max_points
- midpoint breaks things

- add colour pick options
- add jiggle to settings
- potential infinite points with stacking multimeshinstances
"""
