extends Node

func wait(duration: float):
	await get_tree().create_timer(duration).timeout

func tween_alpha(object, final: float, duration: float):
	await tween_linear(object, "modulate:a", final, duration)

func tween_hide(object, duration: float): await tween_alpha(object, duration, 0)
func tween_show(object, duration: float): await tween_alpha(object, duration, 1)

func tween(object, property: NodePath, final, duration: float, ease_type = Tween.EASE_IN_OUT, trans_type = Tween.TRANS_QUAD):
	await create_tween().tween_property(object, property, final, duration).\
		set_ease(ease_type).set_trans(trans_type).finished

func tween_linear(object, property: NodePath, final, duration: float):
	await tween(object, property, final, duration, Tween.EASE_IN, Tween.TRANS_LINEAR)

func tween_pos(object, property: String, final, duration: float, ease_type = Tween.EASE_IN_OUT, trans_type = Tween.TRANS_QUAD):
	var full_property = "position"
	if property != "": full_property += ':' + property
	await tween(object, full_property, final, duration, ease_type, trans_type)

func wait_frame(frame_count: int = 1):
	for i in range(frame_count):
		await get_tree().process_frame

const full_scene_shake_magnitude = 35
const screen_shake_duration = 0.215
const min_shake_duration_multiplier = 0.7

func shake(object, property: NodePath, magnitude: float, duration: float = screen_shake_duration, used_veci = false):
	var screen_shake_initial = Vector2(object.get(str(property)))
	var screen_shake_final = screen_shake_initial + Vector2.ONE * magnitude
	if used_veci:
		screen_shake_initial = Vector2i(screen_shake_initial)
		screen_shake_final = Vector2i(screen_shake_final)
	
	await create_tween().tween_property(object, property, screen_shake_final, duration / 2).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).finished
	await create_tween().tween_property(object, property, screen_shake_initial, duration / 2).finished

func shake_multiple(object, property: NodePath, count: int, duration: float = screen_shake_duration, magnitude: float = full_scene_shake_magnitude, used_veci = false):
	for i in range(count):
		var iteration_multiplier = float(count - i) / count
		var shake_duration = duration * max(iteration_multiplier, min_shake_duration_multiplier)
		await shake(object, property, magnitude * iteration_multiplier, shake_duration, used_veci)

const glitching_pos_generation_count = 1000

func get_glitching_tween_pos(minimum_movement_change, maximum_movement_change, object, position_property: StringName, validation_function = null, position_origin = null):
	var final_tween_pos := Vector2.ZERO
	var used_position_origin = object[position_property]
	if position_origin != null: used_position_origin = position_origin
	
	for i in range(glitching_pos_generation_count):
		var movement_change = randf_range(minimum_movement_change, maximum_movement_change)
		var selected_rad = randf_range(0, TAU)
		var movement_vector = Vector2.from_angle(selected_rad) * movement_change
		final_tween_pos = used_position_origin + movement_vector
		
		var selected_pos_is_valid = true
		if validation_function is Callable: validation_function.call(final_tween_pos)
		if selected_pos_is_valid: break
	
	return final_tween_pos

func get_glitching_tween_duration(index, amount_of_cursor_movements, miminum_movement_tween_duration, maximum_movement_tween_duration, minimum_duration_multiplier):
	var duration_multiplier = max((amount_of_cursor_movements - index) / amount_of_cursor_movements, minimum_duration_multiplier)
	var tween_duration = randf_range(miminum_movement_tween_duration, maximum_movement_tween_duration) * duration_multiplier
	return tween_duration

func pyth(x: float, y: float): return sqrt(x ** 2 + y ** 2)
