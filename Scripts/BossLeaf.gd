class_name LeafBossRoot
extends Node2D

func _ready():
	hide()

const leaf_size = Vector2(20, 20)

@onready var leaf = $Leaf
@onready var glitched_window = get_parent().get_node("Glitched Window")
@onready var mouse_cursor = get_parent().get_node("Cursor")
@onready var alpha_window = get_parent()
@onready var ring_shadow = $RingShadow
@onready var ring_texture = $Ring
@onready var boss_handlerer = $"Boss Handlerer"
@onready var boss_memory_field: BossMemoryField = get_parent().get_node("Boss Memory Field")

var bounds_window: Window
var ring_alpha_modulate: float = 0
var ring_size: float = 0.85
var relative_position: Vector2
var apply_relative_position = false

func _process(delta: float):
	handle_ring(delta)
	handle_relative_position()

func adjust_leaf(window):
	show()
	bounds_window = window
	global_transform = bounds_window.animated_logo.leaf.global_transform
	position += Vector2(bounds_window.position)
	glitched_window.alpha_modulate = 0
	make_leaf_move()

func handle_relative_position():
	if not apply_relative_position: return
	var screen_size = Vector2(DisplayServer.screen_get_size())
	position = screen_size * relative_position

const base_ring_size = 40
const rotation_speed = 0.125

func handle_ring(delta: float):
	ring_shadow.alpha_modulate = ring_alpha_modulate
	ring_texture.alpha_modulate = ring_alpha_modulate
	ring_texture.scale = Vector2.ONE * ring_size
	ring_shadow.scale = Vector2.ONE * ring_size
	ring_texture.rotation += TAU * rotation_speed * delta
	ring_shadow.rotation = ring_texture.rotation
	handle_mouse_ring_collision()

func handle_mouse_ring_collision():
	var local_cursor = to_local(mouse_cursor.global_position)
	var ring_radius = base_ring_size * ring_size
	var dist_to_ring_origin = Help.pyth(local_cursor.x, local_cursor.y)
	var inside_ring = dist_to_ring_origin <= ring_radius
	if not inside_ring: return
	
	var cursor_to_ring_dir = local_cursor.normalized()
	var updated_cursor_local = cursor_to_ring_dir * ring_radius
	var updated_cursor_global = to_global(updated_cursor_local)
	mouse_cursor.global_position = updated_cursor_global

const amount_of_leaf_movements = 6
const leaf_texture_progress_tween_duration = 0.8
const minimum_leaf_move_dist = 70; const maximum_leaf_move_dist = 120
const leaf_going_up_duration = 3
const bounds_window_fall_duration: float = 2
const glitched_window_alpha_mod_tween_duration = 0.6
const glitched_window_corruption_tween_duration: float = 1.5
@onready var skip_enabled = alpha_window.skip_enabled
const after_leaf_shake_delay = 0.7

func make_leaf_move():
	var origin_position = position
	var used_leaf_movements = 0 if skip_enabled else amount_of_leaf_movements
	for i in range(used_leaf_movements):
		var final_tween_pos = Help.get_glitching_tween_pos(minimum_leaf_move_dist, maximum_leaf_move_dist, self, "position", null, origin_position)
		var is_last_iteration = i == amount_of_leaf_movements - 1
		if is_last_iteration: final_tween_pos = Vector2(origin_position.x, origin_position.y - maximum_leaf_move_dist)
		var tween_duration = Help.get_glitching_tween_duration(i, amount_of_leaf_movements, 0.125, 0.2, 0.7)
		Audio.play(UID.SFX_HURT)
		await Help.tween(self, "position", final_tween_pos, tween_duration)
	
	var used_after_leaf_shake_delay = 0.0 if skip_enabled else after_leaf_shake_delay
	await Help.wait(used_after_leaf_shake_delay)
	await handle_window_glitching()
	alpha_window.cursor_interactable = true

signal mouse_scaled
const header_size_multiplier = 1.1
const leaf_going_up_final_monitor_y_pos_multiplier = 0.1
const leaf_actual_size = Vector2(32, 32)
const final_cursor_scale_multiplier = 1.5
const glitched_window_show_delay = 1.5

func handle_window_glitching():
	var monitor_size = DisplayServer.screen_get_size()
	var leaf_going_up_final_y_pos = monitor_size.y * leaf_going_up_final_monitor_y_pos_multiplier + leaf_actual_size.y / 2 * scale.y
	var going_up_duration = 0.0 if skip_enabled else leaf_going_up_duration
	Help.tween(self, "position", Vector2(position.x, leaf_going_up_final_y_pos), going_up_duration)
	var actual_header_height = AlphaWindowHandleler.window_header_size * header_size_multiplier
	glitched_window.position_offset = Vector2(bounds_window.position) - actual_header_height
	glitched_window.size = Vector2(bounds_window.size) + actual_header_height
	
	var used_glitched_window_show_delay = 0.0 if skip_enabled else glitched_window_show_delay
	await Help.wait(used_glitched_window_show_delay)
	glitched_window.show()
	bounds_window.title = "<null>"
	var used_glitched_window_show_tween_duration = 0.0 if skip_enabled else glitched_window_alpha_mod_tween_duration
	
	await Help.tween(glitched_window, "alpha_modulate", 1, used_glitched_window_show_tween_duration)
	bounds_window.queue_free()
	var final_window_y_pos = monitor_size.y - glitched_window.size.y
	var used_window_fall_duration = 0.0 if skip_enabled else bounds_window_fall_duration
	await Help.tween(glitched_window, "position_offset:y", final_window_y_pos, used_window_fall_duration, Tween.EASE_IN, Tween.TRANS_QUINT)
	
	var used_corruption_duration = 0.0 if skip_enabled else glitched_window_corruption_tween_duration
	Audio.play(UID.SFX_WINDOW_FALL)
	Help.tween(glitched_window, "empty_tiles_rate", 1, used_corruption_duration)
	var mouse_final_pos = monitor_size / 2.0
	Help.tween(mouse_cursor, "position", mouse_final_pos, used_corruption_duration)
	DisplayServer.set_icon(UID.IMG_FRAGTEX_LOGO.get_image())
	var final_cursor_scale = alpha_window.used_cursor_scale * final_cursor_scale_multiplier
	await Help.tween(alpha_window, "used_cursor_scale", final_cursor_scale, used_corruption_duration)
	mouse_scaled.emit()

func start_boss():
	boss_handlerer.skip_enabled = skip_enabled
	boss_handlerer.start_boss()
