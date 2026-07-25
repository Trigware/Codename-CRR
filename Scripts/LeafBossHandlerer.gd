class_name LeafBossHandleler
extends ProjectileEmitter

@onready var skip_enabled: bool
@onready var leaf_root: LeafBossRoot = get_parent()

func _ready():
	await Help.wait_frame()
	projectile_transform_node = leaf_root
	mouse_cursor = leaf_root.mouse_cursor
	boss_projectiles = leaf_root.get_parent().get_node("Boss Projectiles")

const leaf_start_fire_projectile = 0.175

func start_boss():
	await show_ring()
	projectile_speed = leaf_start_fire_projectile
	fire_projectile_ring()
	var monitor_size = DisplayServer.screen_get_size()
	Help.tween(leaf_root, "position:y", monitor_size.y / 2, 4)
	await Help.wait(1.5)
	spawn_emitter_factory()

const ring_show_tween_duration = 1.1
const final_ring_size = 1.15
const base_ring_radius = 40
const init_moving_ring_speed = 0.4
const init_particle_emission_timer_multiplier: float = 1

var current_moving_ring_speed = init_moving_ring_speed
var current_particle_emission_timer_multiplier = init_particle_emission_timer_multiplier

func show_ring():
	var used_ring_show_duration = 0.0 if skip_enabled else ring_show_tween_duration
	Help.tween(leaf_root, "ring_alpha_modulate", 1, used_ring_show_duration)
	await Help.tween(leaf_root, "ring_size", final_ring_size, used_ring_show_duration)

const emitter_origin_offset = 40

func spawn_emitter_factory():
	var spawned_particle_emitter = UID.SCN_SPAWNED_EMITTER.instantiate()
	var emitter_origin = Node2D.new()
	emitter_origin.position = Vector2.ONE * emitter_origin_offset
	spawned_particle_emitter.add_child(emitter_origin)
	
	spawned_particle_emitter.setup(
		emitter_origin, leaf_root.alpha_window.boss_projectiles, leaf_root.mouse_cursor
	)
	
	spawned_particle_emitter.is_factory = true
	spawned_particle_emitter.leaf_boss_handlerer = self
	boss_projectiles.add_child(spawned_particle_emitter)
