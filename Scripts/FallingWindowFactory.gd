class_name FallingWindowFactory
extends Node2D

@onready var alpha_window: AlphaWindowHandleler = get_parent().get_parent().get_parent()
var boss_handleler: LeafBossHandleler
var boss_projectiles: Node2D

const window_width = 490
const max_wait_between_window_spawns: float = 1.25
var wait_between_window_spawns: float
const init_spawn_delay = 1.5

func start_spawning_windows():
	is_sequence_active = true
	fire_directed_projectiles()
	await Help.wait(init_spawn_delay)
	while true:
		if not is_sequence_active: break
		if time_between_projectiles < minimum_time_between_projectiles: break
		await spawn_window()
		await Help.wait(wait_between_window_spawns)
	finished_window_sequence.emit()

signal finished_window_sequence

const sequence_duration_to_hardest_projectiles_multiplier = 0.55

func _process(delta: float):
	if not is_sequence_active: return
	time_since_started_throwing_windows += delta
	var window_fall_sequence_duration = skipped_window_fall_sequence_duration if alpha_window.skip_enabled else normal_window_fall_sequence_duration
	var time_until_hardest_projectiles: float = window_fall_sequence_duration * sequence_duration_to_hardest_projectiles_multiplier
	
	var sequence_progress = time_since_started_throwing_windows / window_fall_sequence_duration
	var projectile_hardest_progress = time_since_started_throwing_windows / time_until_hardest_projectiles
	time_between_projectiles = lerp(maximum_time_between_projectiles, minimum_time_between_projectiles, projectile_hardest_progress)
	wait_between_window_spawns = max_wait_between_window_spawns * (1 - projectile_hardest_progress)
	if sequence_progress > 1: is_sequence_active = false

var is_sequence_active = false
var time_between_projectiles: float

const init_spawn_pos_deviation = 0.2
const max_generation_limit = 100
const boundary_spawn_limit = 0.085

func spawn_window():
	var screen_size = DisplayServer.screen_get_size()
	var falling_window = UID.SCN_FALLING_WINDOW.instantiate()
	var mouse_pos_x = alpha_window.mouse_cursor.global_position.x
	var chosen_x_pos: float
	var used_deviation = init_spawn_pos_deviation
	
	for i in range(max_generation_limit):
		var absolute_spawn_deviation = screen_size.x * used_deviation
		chosen_x_pos = mouse_pos_x
		chosen_x_pos += randf_range(-absolute_spawn_deviation, absolute_spawn_deviation)
		var absolute_boundary_limit = screen_size.x * boundary_spawn_limit
		var right_window_bounds = screen_size.x - window_width - absolute_boundary_limit
		var is_spawn_invalid = chosen_x_pos < absolute_boundary_limit or chosen_x_pos > right_window_bounds
		if not is_spawn_invalid: break
		used_deviation = lerp(init_spawn_pos_deviation, 1.0, float(i) / max_generation_limit)
	
	boss_projectiles = alpha_window.boss_projectiles
	falling_window.position.x = chosen_x_pos
	boss_projectiles.add_child(falling_window)
	await falling_window.window_freed

var time_since_started_throwing_windows: float = 0
const skipped_window_fall_sequence_duration: float = 4
const normal_window_fall_sequence_duration: float = 18
const maximum_time_between_projectiles: float = 5
const minimum_time_between_projectiles: float = 1.75
const minimum_possible_time = 0.075

func fire_directed_projectiles():
	while true:
		var used_time_between_projectiles = max(time_between_projectiles, minimum_possible_time)
		await Help.wait(used_time_between_projectiles)
		if not is_sequence_active: return
		boss_handleler.fire_projectile_ring()
