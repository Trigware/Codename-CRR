class_name AlphaWindowHandleler
extends Node2D

@onready var alpha_window = get_window()
@onready var bounds_window = $BoundsWindow
@onready var mouse_cursor = $Cursor
@onready var mouse_texture = mouse_cursor.get_node("Main")
@onready var boss_leaf = $"Boss Leaf"
@onready var boss_projectiles = $"Boss Projectiles"

const init_window_position = Vector2(0, 32)
var is_root_fullscreen = false

func _ready():
	bounds_window.leaf_resize_end.connect(on_leaf_resize_end)
	mouse_texture.texture_progress = 1
	bounds_window.animated_logo.skip_enabled = skip_enabled
	boss_leaf.mouse_scaled.connect(on_mouse_scaled)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var monitor_size = DisplayServer.screen_get_size()
	alpha_window.size = monitor_size
	var cursor_size_multiplier = monitor_size.y / base_monitor_height
	mouse_cursor.scale = Vector2.ONE * used_cursor_scale * cursor_size_multiplier

const mouse_cursor_height = 16
const taskbar_height = 46

func on_leaf_resize_end():
	is_root_fullscreen = true
	mouse_cursor.position = bounds_window.position + bounds_window.size / 2
	mouse_cursor.position.y -= mouse_cursor_height
	cursor_interactable = true

const base_monitor_height: float = 1200
var used_cursor_scale = 1.5

func _process(delta: float):
	var intended_window_mode = Window.MODE_FULLSCREEN if is_root_fullscreen else Window.MODE_MINIMIZED
	if alpha_window.mode != intended_window_mode: alpha_window.mode = intended_window_mode
	if Input.is_action_just_pressed("quit_game"): get_tree().quit()
	if Input.is_action_just_pressed("debug_progress") and skip_enabled: handle_out_of_box_mouse_event()
	handle_cursor_gravity(delta)

const cursor_gravity_multiplier: float = 80
const mouse_cursor_y_bounds_offset = -16
var previously_fallen_to_bottom = false

func handle_cursor_gravity(delta: float):
	if not is_cursor_affected_by_gravity: return
	var monitor_size = DisplayServer.screen_get_size()
	cursor_gravity += delta * cursor_gravity_multiplier
	var monitor_y_bounds = monitor_size.y - mouse_cursor_height - taskbar_height + mouse_cursor_y_bounds_offset
	var mouse_y_pos = min(mouse_cursor.position.y + cursor_gravity, monitor_y_bounds)
	mouse_cursor.position.y = mouse_y_pos
	
	var fallen_to_bottom = mouse_y_pos == monitor_y_bounds
	var stopped_falling_now = fallen_to_bottom and not previously_fallen_to_bottom
	previously_fallen_to_bottom = fallen_to_bottom
	if not stopped_falling_now: return
	Audio.play(UID.SFX_MOUSE_DROP)
	is_cursor_affected_by_gravity = false

var previously_hit_bounds = false
var cursor_interactable = false

func _input(event):
	if not event is InputEventMouseMotion: return
	var motion_event = event as InputEventMouseMotion
	var mouse_pos_change = motion_event.relative
	if not cursor_interactable: return
	mouse_cursor.position += mouse_pos_change
	
	var has_hit_now = has_hit_window_bounds_now()
	if not has_hit_now: return
	
	cursor_interactable = false
	handle_out_of_box_mouse_event()

var latest_out_of_box_event := MouseEvent.None

func has_hit_window_bounds_now():
	if bounds_window == null: return false
	var mouse_pos = mouse_cursor.position
	var right_bottom_bounds = bounds_window.position + bounds_window.size
	var hit_window_bounds = mouse_pos.x < bounds_window.position.x or mouse_pos.y < bounds_window.position.y or\
		mouse_pos.x > right_bottom_bounds.x or mouse_pos.y > right_bottom_bounds.y
	var has_hit_now = hit_window_bounds and not previously_hit_bounds
	previously_hit_bounds = hit_window_bounds
	return has_hit_now

enum MouseEvent {
	None,
	CursorGlitch,
	WindowGlitch
}

func handle_out_of_box_mouse_event():
	if latest_out_of_box_event >= MouseEvent.WindowGlitch: return
	latest_out_of_box_event = (latest_out_of_box_event as int + 1) as MouseEvent
	if skip_enabled:
		on_window_glitch_event()
		return
	
	match latest_out_of_box_event:
		MouseEvent.CursorGlitch: await on_cursor_glitch_event()
		MouseEvent.WindowGlitch: await on_window_glitch_event()

const glitch_mouse_tween_duration = 0.35
const amount_of_cursor_movements: float = 12
const minimum_movement_change = 100
const maximum_movement_change = 135
const miminum_cursor_movement_tween_duration = 0.1
const maximum_cursor_movement_tween_duration = 0.185
const minimum_duration_multiplier = 0.7
const glitch_screen_shake_magnitude = 45
const window_shake_multiplier = 1.5
const mouse_cursor_reset_pos_tween_duration = 0.35
const skip_enabled = true

func on_cursor_glitch_event():
	Help.tween(mouse_texture, "texture_progress", 0, glitch_mouse_tween_duration)
	bounds_window.title = "<null>"
	
	for i in range(amount_of_cursor_movements):
		var final_tween_pos = Help.get_glitching_tween_pos(minimum_movement_change, maximum_movement_change,
			mouse_cursor, "position", validate_glitch_mouse_pos)
		var tween_duration = Help.get_glitching_tween_duration(i, amount_of_cursor_movements,
			miminum_cursor_movement_tween_duration, maximum_cursor_movement_tween_duration, minimum_duration_multiplier)
		
		var window_shake_duration = tween_duration * window_shake_multiplier
		if i % 2 == 0:
			Help.shake(bounds_window, "position", glitch_screen_shake_magnitude, window_shake_duration, true)
		Audio.play(UID.SFX_HURT)
		await Help.tween(mouse_cursor, "position", final_tween_pos, tween_duration)
	
	var reset_cursor_pos = Vector2(bounds_window.position + bounds_window.size / 2)
	Help.tween(mouse_texture, "texture_progress", 1, glitch_mouse_tween_duration)
	await Help.tween(mouse_cursor, "position", reset_cursor_pos, mouse_cursor_reset_pos_tween_duration)
	bounds_window.title = "LeafCROSS"
	cursor_interactable = true

func validate_glitch_mouse_pos(mouse_position):
	var bottom_right_win_edge = bounds_window.position + bounds_window.size
	var monitor_size = DisplayServer.screen_get_size()
	var monitor_y_bounds = monitor_size.y - taskbar_height
	
	var final_in_window = mouse_position.x >= bounds_window.position.x and mouse_position.y >= bounds_window.position.y and\
		mouse_position.x <= bottom_right_win_edge.x and mouse_position.y <= bottom_right_win_edge.y
	var final_outside_monitor = mouse_position.x < 0 or mouse_position.y < 0 or\
		mouse_position.x > monitor_size.x or mouse_position.y > monitor_y_bounds
	var mouse_pos_valid = not final_in_window and not final_outside_monitor
	return mouse_pos_valid

const mouse_cursor_hide_duration = 0.35
const glitched_window_alpha_modulate_tween_duration = 0.6
const window_header_size = Vector2(0, 32)
const empty_tiles_rate_tween_duration: float = 5

var is_cursor_affected_by_gravity = false
var cursor_gravity = 0

func on_window_glitch_event():
	bounds_window.animated_logo.leaf.hide()
	boss_leaf.adjust_leaf(bounds_window)
	if not skip_enabled: is_cursor_affected_by_gravity = true

func on_mouse_scaled():
	await Help.wait(0.5)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_cursor.hide()
	await Help.wait_frame()
	if not skip_enabled:
		OS.alert("Initializing cursor capture protol!", "Fragmented Vertex Protocol")
	
	var mouse_position = get_local_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_cursor.show()
	mouse_cursor.position = mouse_position
	boss_leaf.start_boss()
