class_name SpawnedEmitter
extends ProjectileEmitter

var relative_position := Vector2(0, 0)
const ring_size = 80
const relative_scale = 0.2

@onready var ring_texture = $Ring
@onready var ring_shadow = $RingShadow
var leaf_boss_handlerer: LeafBossHandleler

const circle_appear_duration = 0.75

func _ready():
	show_ring(ring_texture)
	show_ring(ring_shadow)
	handle_segment_ending()
	if is_factory: hide()
	handle_particle_emissions()

const final_inner_circle_radius = 0.385
const outer_circle_tween_duration = 0.5
const wait_for_inner_circle_tween = 0.25
const final_circle_highlight_offset = 0.04

func show_ring(ring: TiledDiagonals):
	ring.reset_circle_values()
	Help.tween(ring, "outer_circle_radius", outer_circle_tween_duration, circle_appear_duration)
	await Help.wait(wait_for_inner_circle_tween)
	var finishing_tweens_duration = circle_appear_duration - wait_for_inner_circle_tween
	Help.tween(ring, "inner_circle_radius", final_inner_circle_radius, finishing_tweens_duration)
	Help.tween(ring, "highlight_circle_radius_offset", final_circle_highlight_offset, finishing_tweens_duration)

func _process(delta: float):
	var monitor_size = Vector2(DisplayServer.screen_get_size())
	var lesser_dimen_size = min(monitor_size.x, monitor_size.y)
	var scale_multiplier = lesser_dimen_size / ring_size * relative_scale
	scale = Vector2.ONE * scale_multiplier
	
	var bottom_right_edge = monitor_size - scale * ring_size
	position = bottom_right_edge * relative_position
	move_projectile_emitter(delta)

var direction_index: int = 3
var is_factory: bool = false
var emitters_spawned = 0
const move_directions_arr = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

const minimum_movement_multiplier: float = 0.06
const maximum_movement_multiplier: float = 3.5

func move_projectile_emitter(delta: float):
	var move_delta = leaf_boss_handlerer.current_moving_ring_speed * delta
	var move_direction = move_directions_arr[direction_index]
	var monitor_size = Vector2(DisplayServer.screen_get_size())
	var aspect_ratio = monitor_size.x / monitor_size.y
	var going_horizontally = move_direction in [Vector2.LEFT, Vector2.RIGHT]
	if going_horizontally: move_delta /= aspect_ratio
	
	var going_backwards = move_direction in [Vector2.LEFT, Vector2.UP]
	var segment_progress = relative_position.x if going_horizontally else relative_position.y
	if going_backwards: segment_progress = 1 - segment_progress
	var progress_to_middle = 1 - 2 * abs(segment_progress - 0.5)
	var movement_multiplier = lerp(minimum_movement_multiplier, maximum_movement_multiplier, progress_to_middle)
	move_delta *= movement_multiplier
	
	var has_reached_segment_end = segment_progress >= 1
	if has_reached_segment_end: handle_segment_ending()
	relative_position += move_direction * move_delta

const maximum_emitter_count = 4

func handle_segment_ending():
	direction_index = (direction_index + 1) % move_directions_arr.size()
	if not is_factory or emitters_spawned >= maximum_emitter_count: return
	
	emitters_spawned += 1
	var spawned_emitter = UID.SCN_SPAWNED_EMITTER.instantiate()
	spawned_emitter.setup(projectile_transform_node, boss_projectiles, mouse_cursor)
	spawned_emitter.leaf_boss_handlerer = leaf_boss_handlerer
	boss_projectiles.add_child(spawned_emitter)
	spawned_emitter.ring_texture.material = ring_texture.material.duplicate()
	spawned_emitter.ring_shadow.material = ring_shadow.material.duplicate()

const minimum_particle_emission_wait_time = 1.5
const maximum_particle_emission_wait_time = 2.85

const inner_circle_radius_charge_final = 0.15
const outer_circle_radius_charge_final = 0.35
const ring_charge_duration = 0.25
const ring_after_charge_wait = 0.1

signal ring_charged

func charge_ring(ring: TiledDiagonals):
	Help.tween(ring, "inner_circle_radius", inner_circle_radius_charge_final, ring_charge_duration)
	await Help.tween(ring, "outer_circle_radius", outer_circle_radius_charge_final, ring_charge_duration)
	ring_charged.emit()
	await Help.wait(ring_after_charge_wait)
	Help.tween(ring, "inner_circle_radius", final_inner_circle_radius, ring_charge_duration)
	Help.tween(ring, "outer_circle_radius", outer_circle_tween_duration, ring_charge_duration)

func handle_particle_emissions():
	if is_factory: return
	var used_particle_emission_wait_time = randf_range(minimum_particle_emission_wait_time, maximum_particle_emission_wait_time) * leaf_boss_handlerer.current_particle_emission_timer_multiplier
	await Help.wait(used_particle_emission_wait_time)
	
	charge_ring(ring_texture)
	charge_ring(ring_shadow)
	await ring_charged
	fire_projectile_ring()
	handle_particle_emissions()
