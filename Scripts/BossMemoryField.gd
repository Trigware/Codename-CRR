@tool
class_name BossMemoryField
extends Control

@onready var memory_field: MemoryField = $MemoryField
@onready var warning_root = $"Warning Root"
@onready var alpha_window: AlphaWindowHandleler = get_parent()
@onready var boss_leaf: LeafBossRoot = alpha_window.get_node("Boss Leaf")
@onready var mouse_cursor = alpha_window.get_node("Cursor")

const size_multiplier = 1.01

func _process(delta: float):
	if not Engine.is_editor_hint(): memory_field.size = DisplayServer.screen_get_size()
	handle_field_objects()
	progress_memory_field_rotations(delta)
	handle_memory_field_rect_collisions()
	var screen_size = DisplayServer.screen_get_size()
	size = screen_size * size_multiplier

const projectile_warning_count: int = 10
const projectile_warning_padding: float = 0.06

signal created_memory_field

func create_projectile_warnings():
	for i in range(projectile_warning_count):
		var projectile_warning: ProjectileWarning = UID.SCN_PROJECTILE_WARNING.instantiate()
		projectile_warning.alpha_window = alpha_window
		if i == 0: projectile_warning.ended_warning_animation.connect(create_memory_field_rect)
		var regular_x_pos = float(i) / (projectile_warning_count - 1)
		var relative_x_pos = regular_x_pos * (1 - projectile_warning_padding) + projectile_warning_padding / 2
		projectile_warning.relative_position.x = relative_x_pos
		projectile_warning.relative_scale = 1.0 / projectile_warning_count * (1 - projectile_warning_padding)
		warning_root.add_child(projectile_warning)

func progress_memory_field_rotations(delta: float):
	if Engine.is_editor_hint(): return
	if memory_field.rect_array.size() == 0: return
	if is_stopping_rotation:
		slow_down_rotation_speed(delta)
		return
	current_rotation_speed += max_rotation_speed * delta / duration_to_max_rotation
	
	current_rotation_speed = min(current_rotation_speed, max_rotation_speed)
	for i in range(memory_field.rect_array.size()):
		var memory_field_rect: MemoryFieldRect = memory_field.rect_array[i]
		memory_field_rect.rotation_radians += current_rotation_speed * delta

const memory_rect_height_tween_duration: float = 0.85
const leaf_ring_size = 80
const max_memory_field_rect_height_portion = 0.075
var memory_field_circle = null

var current_rotation_speed: float = 0
const max_rotation_speed: float = PI * 0.25
const duration_to_max_rotation: float = 8
var has_created_memory_field_rect_before = false

func create_memory_field_rect():
	var screen_size = DisplayServer.screen_get_size()
	var aspect_ratio = screen_size.x / screen_size.y
	var memory_field_rect = MemoryFieldRect.make_centered()
	var used_rect_height = 1.0 / aspect_ratio * max_memory_field_rect_height_portion
	Help.tween(memory_field_rect, "rect:size:y", used_rect_height, memory_rect_height_tween_duration)
	memory_field.rect_array.append(memory_field_rect)
	Audio.play(UID.SFX_MEMORY_FIELD_OPEN)
	
	if not has_created_memory_field_rect_before:
		var leaf_ring_scaled = leaf_ring_size * boss_leaf.scale
		var height_circle_count = screen_size.y / leaf_ring_scaled.y
		var circle_radius = 1.0 / height_circle_count / 2.0
		memory_field_circle = MemoryFieldCircle.make_centered(circle_radius)
		memory_field.circle_array.append(memory_field_circle)
		created_memory_field.emit()
	has_created_memory_field_rect_before = true

var is_rect_pos_based_on_leaf = false

func handle_field_objects():
	var screen_size = Vector2(DisplayServer.screen_get_size())
	if boss_leaf == null: return
	var relative_leaf_position = boss_leaf.position / screen_size
	if memory_field_circle is MemoryFieldCircle: memory_field_circle.position = relative_leaf_position
	if not is_rect_pos_based_on_leaf: return
	for memory_field_rect: MemoryFieldRect in memory_field.rect_array:
		memory_field_rect.rect.position = relative_leaf_position

func handle_memory_field_rect_collisions():
	if Engine.is_editor_hint(): return
	var is_cursor_in_rect = is_cursor_in_memory_field_rect()
	#if is_cursor_in_rect: print("Hit Memory Rect")

func is_cursor_in_memory_field_rect():
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var aspect_ratio = screen_size.x / screen_size.y
	var mouse_pos = mouse_cursor.global_position
	for memory_field_rect: MemoryFieldRect in memory_field.rect_array:
		var origin_pos = screen_size * memory_field_rect.rect.position
		var modified_rect_size = Vector2(memory_field_rect.rect.size.x, memory_field_rect.rect.size.y * aspect_ratio)
		var actual_rect_size = screen_size * modified_rect_size
		var relative_point = mouse_pos - origin_pos
		var unrotated_point = Vector2(
			relative_point.x * cos(memory_field_rect.rotation_radians) - relative_point.y * sin(memory_field_rect.rotation_radians),
			relative_point.x * sin(memory_field_rect.rotation_radians) + relative_point.y * cos(memory_field_rect.rotation_radians)
		)
		
		var half_rect_size = actual_rect_size / 2.0
		var is_in_rect =\
			unrotated_point.x >= -half_rect_size.x and unrotated_point.x <= half_rect_size.x and\
			unrotated_point.y >= -half_rect_size.y and unrotated_point.y <= half_rect_size.y
		if is_in_rect: return not is_cursor_in_memory_field_circle()
		
	return false

func is_cursor_in_memory_field_circle():
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var mouse_pos: Vector2 = mouse_cursor.global_position
	for current_field_circle: MemoryFieldCircle in memory_field.circle_array:
		var origin_pos = screen_size * current_field_circle.position
		var actual_radius = current_field_circle.radius * screen_size.y
		var dist_to_origin = mouse_pos.distance_to(origin_pos)
		if dist_to_origin <= actual_radius: return true
	return false

const memory_rect_time_to_destroy = 0.85
var is_stopping_rotation = false
var initial_slowing_down_rotation: float

func destroy_memory_field_rect():
	var rect_to_be_destroyed: MemoryFieldRect = memory_field.rect_array[1]
	await Help.tween(rect_to_be_destroyed, "rect:size:y", 0, memory_rect_time_to_destroy)
	
	is_stopping_rotation = true
	var first_memory_rect = memory_field.rect_array[0]
	initial_slowing_down_rotation = first_memory_rect.rotation_radians
	memory_field.rect_array.pop_back()

const minimum_rotation_progress = 0.6
var has_stopped_to_slow_down = false

func slow_down_rotation_speed(delta: float):
	if has_stopped_to_slow_down: return
	var initial_distance = distance_to_angle(initial_slowing_down_rotation, final_rect_rotation)
	var slowed_rect = memory_field.rect_array[0]
	var current_rotation = slowed_rect.rotation_radians
	var current_distance = distance_to_angle(current_rotation, final_rect_rotation)
	var rotation_progress = current_distance / initial_distance
	rotation_progress = max(minimum_rotation_progress, rotation_progress)
	
	current_rotation_speed = max_rotation_speed * rotation_progress
	var updated_rotation = slowed_rect.rotation_radians + current_rotation_speed * delta
	slowed_rect.rotation_radians = updated_rotation
	var updated_distance = distance_to_angle(updated_rotation, final_rect_rotation)
	if updated_distance <= current_distance or has_stopped_to_slow_down: return
	
	has_stopped_to_slow_down = true
	make_rect_bigger(slowed_rect)

const final_rect_rotation = PI*3/2

func distance_to_angle(current_angle: float, destination_angle: float):
	var normalized_current = fmod(current_angle, TAU)
	var normalized_destination = fmod(destination_angle, TAU)
	if normalized_current == normalized_destination: return 0
	
	if normalized_current > normalized_destination: normalized_destination += TAU
	return normalized_destination - normalized_current

func make_rect_bigger(memory_rect: MemoryFieldRect):
	Engine.time_scale = 1
	memory_rect.rotation_radians = final_rect_rotation
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var mouse_pos = mouse_cursor.global_position
	var rect_x_to_mouse = screen_size.x / 2 - mouse_pos.x
	var rect_expand_dir = sign(rect_x_to_mouse)
	show_projectile_warnings(rect_expand_dir)
	
	await Help.wait(extend_rect_warning_duration)
	var warning_spawn_duration = projectile_warning_count * wait_between_warning_spawns / 2.0
	Help.tween(memory_rect, "rect:size:y", 0.5, warning_spawn_duration)
	is_rect_pos_based_on_leaf = false
	var final_rect_pos = relative_center + relative_center / 2.0 * rect_expand_dir
	await Help.tween(memory_rect, "rect:position:x", final_rect_pos, warning_spawn_duration)
	change_memory_field_visual_appearence()

const relative_center = 0.5
const wait_between_warning_spawns = 0.4
const warning_relative_x_pos_multiplier = 0.935
const extend_rect_warning_duration = 2.5

func show_projectile_warnings(rect_expand_dir: float):
	var warning_column_count = projectile_warning_count / 2.0
	
	for i in range(1, warning_column_count + 1):
		for j in range(0, projectile_warning_count / 2.0):
			var projectile_warning = UID.SCN_PROJECTILE_WARNING.instantiate()
			projectile_warning.hide()
			projectile_warning.warning_animation_duration = extend_rect_warning_duration
			var projectile_warning_distance = relative_center / warning_column_count
			var relative_x = relative_center + projectile_warning_distance * i * rect_expand_dir * warning_relative_x_pos_multiplier
			var relative_y = projectile_warning_distance * j * 2
			
			projectile_warning.relative_position = Vector2(relative_x, relative_y)
			projectile_warning.relative_scale = 1.0 / projectile_warning_count * (1 - projectile_warning_padding)
			projectile_warning.alpha_window = alpha_window
			warning_root.add_child(projectile_warning)
		await Help.wait(wait_between_warning_spawns)

const glyph_make_small_tween_duration = 0.85
const full_visual_change_duration = 1.5

func change_memory_field_visual_appearence():
	await Help.wait(0.5)
	Help.tween(memory_field, "glyph_scale", 0, full_visual_change_duration)
	Help.tween(memory_field, "glyph_modulate:s", 0, full_visual_change_duration)
	Help.tween(memory_field, "line_color:s", 0, full_visual_change_duration)
	Help.tween(memory_field, "circle_alpha_modulate", 0, full_visual_change_duration)
