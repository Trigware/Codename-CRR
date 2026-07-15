extends ProjectileEmitter

@onready var skip_enabled: bool
@onready var leaf_root: LeafBossRoot = get_parent()

func _ready():
	await Help.wait_frame()
	projectile_transform_node = leaf_root
	mouse_cursor = leaf_root.mouse_cursor
	boss_projectiles = leaf_root.get_parent().get_node("Boss Projectiles")

func start_boss():
	await show_ring()
	fire_projectile_ring()
	var monitor_size = DisplayServer.screen_get_size()
	Help.tween(leaf_root, "position:y", monitor_size.y / 2, 4)

const ring_show_tween_duration = 1.15
const final_ring_size = 1.15
const base_ring_radius = 40

func show_ring():
	var used_ring_show_duration = 0.0 if skip_enabled else ring_show_tween_duration
	Help.tween(leaf_root, "ring_alpha_modulate", 1, used_ring_show_duration)
	await Help.tween(leaf_root, "ring_size", final_ring_size, used_ring_show_duration)
