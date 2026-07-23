class_name UIProjectile
extends Area2D

@onready var ui_sprite = $Sprite
@onready var ui_shadow = $Shadow
@onready var missing_texture = $"Missing Texture"
@onready var projectile_root = get_parent()

const amount_of_ui_textures = 8
var chosen_x_texture = -1
const projectile_modulate_tween_duration = 0.15
var alpha_mod: float = 0

var projectile_scale: float = 1

func on_projectile_init():
	missing_texture.material = UID.SHD_PROJECTILE_GLITCHING.duplicate()
	scale *= projectile_scale
	alpha_mod = 0
	update_modulate()
	Help.tween(self, "alpha_mod", 1, projectile_modulate_tween_duration)
	change_projectile_texture()

func _process(delta: float):
	update_modulate()
	projectile_speed *= 1 + projectile_speed_increase * delta
	move_projectile(delta)

func update_modulate():
	modulate.a = alpha_mod
	missing_texture.alpha_modulate = alpha_mod

var movement_angle: float
var angle_center_diff: float

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
const projectile_speed_increase: float = 0.85

func move_projectile(delta: float):
	var monitor_size = DisplayServer.screen_get_size()
	var lesser_dimen_size = min(monitor_size.x, monitor_size.y)
	var movement_dir = Vector2.from_angle(movement_angle)
	#movement_angle += angle_center_diff * delta
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
