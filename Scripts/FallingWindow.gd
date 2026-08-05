class_name WindowPopup
extends Area2D

const window_height = 260
const spawned_position_multiplier = 1.5
const falling_window_warning_duration = 1.5

@onready var projectile_warning: ProjectileWarning = $"Window/Projectile Warning"
@onready var alpha_window: AlphaWindowHandleler = get_parent().get_parent()
@onready var glitching_window = $"Glitching Window"
@onready var actual_window = $Window
@onready var safe_text = $"Safe Text"

const warning_height = 92
const warning_pos_y = warning_height * 0.6
const init_glitching_window_color = Color("7a4040")
const final_glitching_window_color = Color("407a41")

func _ready():
	Audio.play_pitch(UID.SFX_WARNING_APPEAR)
	safe_text.modulate.a = 0
	projectile_warning.alpha_window = alpha_window
	projectile_warning.affect_transform = false
	projectile_warning.use_skip_duration = false
	projectile_warning.warning_animation_duration = falling_window_warning_duration
	position.y = -window_height * spawned_position_multiplier
	projectile_warning.ended_warning_animation.connect(func():
		is_window_falling = true
	)

var is_window_falling = false
const init_falling_speed = 0
var falling_speed: float = init_falling_speed
const falling_acceleration_speed = 15
const alpha_modulate_multiplier = 1.5
var first_time_hitting_ground = true

func _process(delta: float):
	projectile_warning.global_position.y = warning_pos_y
	if not is_window_falling: return
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var used_window_y_pos = position.y + window_height
	var fall_progress = used_window_y_pos / screen_size.y
	var used_alpha_modulate = fall_progress * alpha_modulate_multiplier
	if used_alpha_modulate > 1: used_alpha_modulate = 1
	
	var has_reached_ground = used_window_y_pos >= screen_size.y
	if has_reached_ground:
		on_reaching_ground(delta)
		return
	glitching_window.alpha_modulate = used_alpha_modulate
	falling_speed += falling_acceleration_speed * delta
	position.y += falling_speed

const time_until_full_empty_tiles: float = 1.25
const time_to_transition_to_safe: float = time_until_full_empty_tiles * 0.25
var time_since_hitting_ground: float = 0
var is_window_safe: bool = false
signal window_freed

func on_reaching_ground(delta: float):
	time_since_hitting_ground += delta
	var empty_tile_rate = time_since_hitting_ground / time_until_full_empty_tiles
	var safe_visible_progress = min(time_since_hitting_ground / time_to_transition_to_safe, 1)
	glitching_window.line_color = init_glitching_window_color.lerp(final_glitching_window_color, safe_visible_progress)
	is_window_safe = true
	safe_text.modulate.a = safe_visible_progress
	
	var is_fully_hidden = empty_tile_rate >= 1
	glitching_window.empty_tiles_rate = empty_tile_rate
	if is_fully_hidden:
		queue_free()
		window_freed.emit()
	actual_window.hide()
	if first_time_hitting_ground: Audio.play(UID.SFX_WINDOW_FALL)
	first_time_hitting_ground = false
