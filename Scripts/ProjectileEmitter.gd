class_name ProjectileEmitter
extends Node

var projectile_transform_node: Node
var boss_projectiles: Node
var mouse_cursor: Node

func fire_ui_projectile() -> UIProjectile:
	var ui_projectile = UID.SCN_UI_PROJECTILE.instantiate()
	ui_projectile.global_transform = projectile_transform_node.global_transform
	boss_projectiles.add_child(ui_projectile)
	return ui_projectile

const spawned_projectile_count: float = 5
const projectile_range = PI / 2

func fire_projectile_ring():
	var mouse_delta = mouse_cursor.global_position - projectile_transform_node.global_position
	var mouse_angle = atan2(mouse_delta.y, mouse_delta.x)
	
	for i in range(spawned_projectile_count):
		var current_projectile = fire_ui_projectile()
		var centered_index = i - (spawned_projectile_count - 1) / 2
		var chosen_rad = mouse_angle + centered_index * projectile_range / 2
		current_projectile.movement_dir = Vector2.from_angle(chosen_rad)
		current_projectile.on_projectile_init()
