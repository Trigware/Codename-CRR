class_name UIProjectile
extends Area2D

@onready var ui_sprite = $Sprite
@onready var ui_shadow = $Shadow
@onready var missing_texture = $"Missing Texture"
@onready var projectile_root = get_parent()
@onready var boss_handleler = projectile_root.get_parent().boss_leaf.boss_handlerer

const amount_of_ui_textures = 8
var chosen_x_texture = -1
const projectile_modulate_tween_duration = 0.15
const missing_texture_normal_rate = 0.8
var alpha_mod: float = 0

var projectile_scale: float = 1

func on_projectile_init():
	missing_texture.material = UID.SHD_PROJECTILE_GLITCHING.duplicate()
	scale *= projectile_scale
	alpha_mod = 0
	var is_changing_angle = projectile_angle_diff != 0
	missing_texture.empty_tiles_rate = 0.0 if is_changing_angle else missing_texture_normal_rate
	
	update_modulate()
	Help.tween(self, "alpha_mod", 1, projectile_modulate_tween_duration)
	change_projectile_texture()
	tween_angle_multiplier()

const angle_multiplier_tween_duration = 0.15
const angle_tween_wait_duration = 0.8

func tween_angle_multiplier():
	var next_angle_multiplier = 1.0 if angle_multiplier == -1.0 else -1.0
	await Help.tween(self, "angle_multiplier", next_angle_multiplier, angle_multiplier_tween_duration)
	await Help.wait(angle_tween_wait_duration)
	tween_angle_multiplier()

func _process(delta: float):
	update_modulate()
	projectile_speed *= 1 + projectile_speed_increase * delta
	move_projectile(delta)

func update_modulate():
	modulate.a = alpha_mod
	missing_texture.alpha_modulate = alpha_mod

var movement_angle: float

const texture_change_attempt_limit = 100
const texture_change_duration = 0.6

func change_projectile_texture():
	for i in range(texture_change_attempt_limit):
		var updated_x_texture = randi_range(0, amount_of_ui_textures - 1)
		if chosen_x_texture == updated_x_texture: continue
		chosen_x_texture = updated_x_texture
		break
	ui_sprite.frame_coords.x = chosen_x_texture
	ui_shadow.frame_coords.x = chosen_x_texture
	await Help.wait(texture_change_duration)
	change_projectile_texture()

var projectile_speed: float = 0.25
var speed_multiplier: float = 1
var angle_dir: float = 1
var angle_multiplier: float = 1
var projectile_angle_diff: float = 0

const projectile_speed_increase: float = 0.85
var angle_speed = 0.4

func move_projectile(delta: float):
	var monitor_size = DisplayServer.screen_get_size()
	var lesser_dimen_size = min(monitor_size.x, monitor_size.y)
	angle_multiplier -= projectile_angle_diff * delta
	movement_angle += angle_dir * angle_speed * angle_multiplier * delta
	
	var movement_dir = Vector2.from_angle(movement_angle)
	var pos_delta = movement_dir * lesser_dimen_size * projectile_speed * speed_multiplier * delta
	position += pos_delta
	handle_hitting_monitor_bounds()

const half_texture_size = 8
var has_hit_monitor_previously = false

func handle_hitting_monitor_bounds():
	if has_hit_monitor_previously: return
	var monitor_size = DisplayServer.screen_get_size()
	var collision_offset = half_texture_size * scale
	var has_hit = position.x - collision_offset.x <= 0 or position.x + collision_offset.x >= monitor_size.x or\
		position.y - collision_offset.y <= 0 or position.y + collision_offset.y >= monitor_size.y
	if not has_hit: return
	has_hit_monitor_previously = true
	
	var explosion_effect = UID.SCN_EXPLOSION.instantiate()
	explosion_effect.global_transform = global_transform
	explosion_effect.start()
	projectile_root.add_child(explosion_effect)
	queue_free()
