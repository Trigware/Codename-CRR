class_name ProjectileEmitter
extends Node2D

var projectile_transform_node: Node
var boss_projectiles: Node
var mouse_cursor: Node

static var projectile_fire_count = 0

func fire_ui_projectile() -> UIProjectile:
	var ui_projectile = UID.SCN_DIRECTED_PROJECTILE.instantiate()
	ui_projectile.global_transform = projectile_transform_node.global_transform
	boss_projectiles.add_child(ui_projectile)
	return ui_projectile

const spawned_projectile_count: float = 5
const projectile_range = PI / 4

func setup(origin_node, projectile_root, cursor):
	projectile_transform_node = origin_node
	boss_projectiles = projectile_root
	mouse_cursor = cursor

const maximum_speed_multiplier_diff: float = 0.3
const possible_projectile_diff: float = 4.5
const maximum_projectile_diff_prob = 0.225
const time_until_max_angle_diff_probability: float = 15
var angle_diff_duration_multiplier: float = 1
var time_since_emitter_spawned: float = 0
var projectile_speed: float = 0.25
const diff_angle_deterministic_fire_on_count = 5
const diff_angle_restriction_stop_count = 8

func fire_projectile_ring():
	var mouse_delta = mouse_cursor.global_position - projectile_transform_node.global_position
	var mouse_angle = atan2(mouse_delta.y, mouse_delta.x)
	var projectile_diff_probability = time_since_emitter_spawned / (time_until_max_angle_diff_probability * angle_diff_duration_multiplier)
	projectile_diff_probability = min(projectile_diff_probability, maximum_projectile_diff_prob)
	var diff_angle_restricted = projectile_fire_count < diff_angle_restriction_stop_count 
	
	var random_value = randf()
	var will_change_angle = random_value < projectile_diff_probability
	if diff_angle_restricted: will_change_angle = false
	if projectile_fire_count == diff_angle_deterministic_fire_on_count: will_change_angle = true
	var projectile_diff = possible_projectile_diff if will_change_angle else 0.0
	Audio.play(UID.SFX_DIRECTED_PROJECTILE)
	
	for i in range(spawned_projectile_count):
		var current_projectile = fire_ui_projectile()
		var half_projectile_count = (spawned_projectile_count - 1) / 2
		var centered_index = i - half_projectile_count
		var chosen_rad = mouse_angle + centered_index * projectile_range / 2
		
		current_projectile.movement_angle = chosen_rad
		var center_index_progress = 1 - abs(centered_index) / half_projectile_count
		current_projectile.speed_multiplier = center_index_progress * maximum_speed_multiplier_diff + 1
		current_projectile.projectile_angle_diff = projectile_diff
		current_projectile.projectile_speed = projectile_speed
		
		var angle_dir = 1 - center_index_progress
		if centered_index < 0: angle_dir = -angle_dir
		current_projectile.angle_dir = angle_dir
		current_projectile.is_corrupted = projectile_diff != 0
		current_projectile.on_projectile_init()
	projectile_fire_count += 1
