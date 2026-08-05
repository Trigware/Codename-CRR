class_name ProjectileWarning
extends Node2D

const projectile_warning_size: float = 32
var relative_position: Vector2 = Vector2(0, 0.5)
var relative_scale: float = 0.1
const init_projectile_scale_multiplier = 0.6
const max_projectile_scale_multiplier = 0.685
var projectile_scale_multiplier: float = init_projectile_scale_multiplier
var is_used_dimension_x = true
const warning_show_duration = 0.65

@export var projectile_warning_color_begin: Color
@export var projectile_warning_color_end: Color
var animation_progress: float

@onready var screen = $Screen
@onready var warning_sprite = $Warning
@onready var avoid_title = $"Avoid Title"

var alpha_modulate: float = 0
var alpha_window = null

signal ended_warning_animation

func _ready():
	Help.tween(self, "alpha_modulate", 1, warning_show_duration)

var affect_transform: bool = true

func _process(delta: float):
	modulate.a = alpha_modulate
	screen.alpha_modulate = alpha_modulate
	
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var screen_dimen_size = screen_size.x if is_used_dimension_x else screen_size.y
	projectile_scale_multiplier = lerp(init_projectile_scale_multiplier, max_projectile_scale_multiplier, animation_progress)
	if affect_transform: scale = Vector2.ONE * screen_dimen_size * relative_scale * projectile_scale_multiplier / projectile_warning_size
	var scaled_size = projectile_warning_size * scale
	if affect_transform: position = screen_size * relative_position - scaled_size * relative_position
	
	var projectile_warning_modulate = projectile_warning_color_begin.lerp(projectile_warning_color_end, animation_progress)
	warning_sprite.modulate = projectile_warning_modulate
	avoid_title.modulate = projectile_warning_modulate
	handle_warning_animation(delta)

var time_since_warning_created: float = 0
var warning_animation_duration: float = 4.25
const animation_wave_count: int = 3
const warning_hide_duration: float = 0.375
var use_skip_duration = true
var reached_animation_duration_end = false
const skipped_warning_duration = 0.5

# Based on formula:
# cos(tau/d*t * (1+t/d)^log2(n)) / 2 + 0.5
# Where d is animation duration, t is time since creation and n amount of waves.
# Returns tween value in interval [0; 1]
func handle_warning_animation(delta: float):
	time_since_warning_created += delta
	var used_animation_duration = skipped_warning_duration if alpha_window.skip_enabled else warning_animation_duration
	if not use_skip_duration: used_animation_duration = warning_animation_duration
	var animation_duration_progress = clamp(time_since_warning_created / used_animation_duration, 0, 1)
	var stretched_wave_cos_arg = animation_duration_progress * TAU
	var wave_stretch_multiplier = (1 + animation_duration_progress) * Help.lg(2, animation_wave_count)
	animation_progress = cos(stretched_wave_cos_arg * wave_stretch_multiplier) / 2.0 + 0.5
	var time_until_animation_end = used_animation_duration - time_since_warning_created
	alpha_modulate = clamp(time_until_animation_end / warning_hide_duration, 0, 1)
	
	if animation_duration_progress >= 1:
		if not reached_animation_duration_end: ended_warning_animation.emit()
		reached_animation_duration_end = true
