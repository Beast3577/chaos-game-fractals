extends Node

var point_count := 0

# Default Settings
var max_points: int = 1000000
var steps_per_second: float = 1
var unlimited_steps_per_second: bool = false
var points_per_step: float = 1

var random_type: int = 0

var polygon_vertices: float = 3
var show_polygon_vertices: bool = true
var show_polygon_lines: bool = true
var polygon_vertex_size: float = 3

var point_size: float = 1
var use_point_colour: bool = false
var use_point_opacity: bool = false
var point_opacity: float = 0.1

"""
TODO
- make check buttons hide relavant settings
- add opacity slider
- add colour pick options
- add simulation buttons
- add picking start spot
"""
