extends Node2D

var rock_destinations: Array[Vector2] = []
const initial_x_position_offset = 200
const rock_y_start_point = 75

func _ready():
	for child: Sprite2D in get_children():
		rock_destinations.append(child.position)
		child.position.x += randf_range(-initial_x_position_offset, initial_x_position_offset)
		child.position.y = rock_y_start_point

const throw_tween_minimal_duration = 0.65
const throw_tween_maximum_duration = 0.95
const rock_visibility_tween_duration = 0.4

func animate_rocks():
	await get_tree().create_timer(0.3).timeout
	create_tween().tween_property(self, "modulate:a", 1, rock_visibility_tween_duration)
	
	for i in range(get_child_count()):
		var rock_node = get_child(i)
		var rock_duration = randf_range(throw_tween_minimal_duration, throw_tween_maximum_duration)
		var rock_destination = rock_destinations[i]
		create_tween().tween_property(rock_node, "position", rock_destination, rock_duration).\
			set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		
	await get_tree().create_timer(0.15).timeout
	Audio.play(UID.SFX_ROCKS_FALL)
