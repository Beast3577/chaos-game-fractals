extends Node

# values used for reset consistency
var point_count: int = 0 # resets to zero
var started: bool = false

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
var show_line_between_points: bool = false

var show_advanced_settings: bool = false
var multimesh_instance_batch_size: int = 100000
var show_iterations: bool = true

"""
TODO
- add line between chosen points
- add unlimited max points setting
- midpoint breaks things

- add image save
- add colour pick options
- add jiggle to settings
- make multimesh only recreate if necessary (avoid unnecessary memory allocation changes)

- add different point sprites
"""
