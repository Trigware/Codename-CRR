class_name HintArrows
extends Node2D

var mouse_cursor: MouseCursor
@onready var left_arrow = $"Left Arrow"
@onready var right_arrow = $"Right Arrow"
@onready var bounds_window: BoundsWindow = get_parent()

const relative_size = Vector2(0.5, 0.8)
const hint_scale = 2
const hint_modulate_tween_duration = 1.5

var unshowable = false

func _ready():
	scale = Vector2.ONE * hint_scale
	modulate.a = 0
	await Help.wait_frame()
	await bounds_window.animated_logo.whiteout_ended
	await Help.wait(2)
	if unshowable: return
	Help.tween(self, "modulate:a", 1.0, hint_modulate_tween_duration)

const highest_edge_distance_modulate = Color("91e0ff")
const lowest_edge_distance_modulate = Color("d44e4e")
const init_offset = 16
const maximum_x_offset_multiplier: float = 0.2

func _process(_delta):
	var window_size = Vector2(get_window().size)
	var local_cursor_pos = mouse_cursor.position - Vector2(bounds_window.position)
	var dist_to_x_edge = min(local_cursor_pos.x, bounds_window.size.x - local_cursor_pos.x)
	var highest_edge_distance = window_size.x / 2
	
	var distance_to_edge_progress = 1 - dist_to_x_edge / highest_edge_distance
	var arrows_modulate = highest_edge_distance_modulate.lerp(lowest_edge_distance_modulate, distance_to_edge_progress)
	var x_pos_offset = init_offset + highest_edge_distance * distance_to_edge_progress * maximum_x_offset_multiplier
	
	left_arrow.modulate = arrows_modulate
	right_arrow.modulate = arrows_modulate
	left_arrow.position.x = -x_pos_offset
	right_arrow.position.x = x_pos_offset
	position = window_size * relative_size
