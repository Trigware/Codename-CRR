class_name LeafBossHandleler
extends ProjectileEmitter

@onready var skip_enabled: bool
@onready var leaf_root: LeafBossRoot = get_parent()
@onready var alpha_window: AlphaWindowHandleler = leaf_root.get_parent()
@onready var boss_memory_field: BossMemoryField = alpha_window.get_node("Boss Memory Field")
var spawned_emitter_arr: Array[SpawnedEmitter]

func _ready():
	await Help.wait_frame()
	projectile_transform_node = leaf_root
	mouse_cursor = leaf_root.mouse_cursor
	boss_projectiles = leaf_root.get_parent().get_node("Boss Projectiles")
	boss_memory_field.created_memory_field.connect(handle_circle_projectile_firing)

const leaf_start_fire_projectile = 0.175
const leaf_move_to_center_duration: float = 4

func start_boss():
	await show_ring()
	projectile_speed = leaf_start_fire_projectile
	fire_projectile_ring()
	var monitor_size = DisplayServer.screen_get_size()
	var used_move_to_center_duration = 0 if alpha_window.skip_enabled else leaf_move_to_center_duration
	Help.tween(leaf_root, "position:y", monitor_size.y / 2, used_move_to_center_duration)
	spawn_emitter_factory()
	is_spawning_ui_projectiles = true

const leaf_move_for_memory_field_duration: float = 4
const leaf_ring_radius = 40
const leaf_destination_height_portion: float = 0.15

var time_since_projectile_started_spawning: float = 0
var is_spawning_ui_projectiles: bool = false
const minimum_emission_multiplier: float = 0.825
var emission_multiplier_progress: float = 0

func _process(delta: float):
	if is_firing_circle_projectiles: handle_circle_projectile_progression(delta)
	if not is_spawning_ui_projectiles: return
	
	var used_despawn_time = 0.0 if alpha_window.skip_enabled else time_until_projectiles_despawn
	time_since_projectile_started_spawning += delta
	if time_since_projectile_started_spawning > used_despawn_time:
		despawn_projectile_emitters()
		is_spawning_ui_projectiles = false
		leaf_root.boss_memory_field.create_projectile_warnings()
		return
		
	var projectile_summon_progression = time_since_projectile_started_spawning / used_despawn_time
	emission_multiplier_progress += delta / time_until_minimal_emission_multiplier
	current_particle_emission_timer_multiplier = lerp(1.0, minimum_emission_multiplier, emission_multiplier_progress)
	current_moving_ring_speed = lerp(init_moving_ring_speed, maximum_moving_ring_speed, projectile_summon_progression)

const time_until_projectiles_despawn: float = 18
var emitter_spawning_disabled = false

func despawn_projectile_emitters():
	for spawned_emitter: SpawnedEmitter in spawned_emitter_arr:
		spawned_emitter.to_be_despawned = true
	emitter_spawning_disabled = true

const ring_show_tween_duration = 1.1
const final_ring_size = 1.15
const base_ring_radius = 40
const init_moving_ring_speed = 0.4
const maximum_moving_ring_speed = 0.65
const time_until_minimal_emission_multiplier = 18

var current_moving_ring_speed = init_moving_ring_speed
var current_particle_emission_timer_multiplier = 1

func show_ring():
	var used_ring_show_duration = 0.0 if skip_enabled else ring_show_tween_duration
	Help.tween(leaf_root, "ring_alpha_modulate", 1, used_ring_show_duration)
	Audio.play(UID.SFX_CHARGE_RING)
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

const minimum_fire_wait_duration: float = 3.45
const maximum_fire_wait_duration: float = 4.85
const min_circle_projectile_fire_wait_duration_multiplier: float = 0.8
const time_for_hardest_circle_projectiles: float = 12
var time_since_circle_projectiles_started: float = 0
var hardest_circle_projectiles_progress: float = 0
var is_firing_circle_projectiles = false

func handle_circle_projectile_progression(delta: float):
	time_since_circle_projectiles_started += delta
	hardest_circle_projectiles_progress = min(time_since_circle_projectiles_started / time_for_hardest_circle_projectiles, 1)

const amount_of_fired_circle_projectiles = 5

func handle_circle_projectile_firing():
	return
	create_additional_memory_field_rect()
	move_leaf_in_lemniscate_pattern()
	is_firing_circle_projectiles = true
	for i in range(amount_of_fired_circle_projectiles):
		var circle_projectile_fire_wait_duration_multiplier = lerp(1.0, min_circle_projectile_fire_wait_duration_multiplier, hardest_circle_projectiles_progress)
		var fire_wait_duration = randf_range(minimum_fire_wait_duration, maximum_fire_wait_duration) * circle_projectile_fire_wait_duration_multiplier
		await Help.wait(fire_wait_duration)
		fire_circle_projectile_set()

var pattern_move_progress: float = 0
const time_to_complete_lemniscate_pattern: float = 30
const pattern_scale = 0.5
const wait_to_start_lumniscate_pattern: float = 20

const minimum_lemniscate_pattern_completion_multiplier: float = 0.4
const time_to_reach_minimum_lemniscate_completion_multiplier: float = 15
var time_since_started_lemniscate_pattern: float = 0

# Following the Lemniscate of Gerono
# P = (sin(tau*t), sin(tau*t) * cos(tau*t))
func move_leaf_in_lemniscate_pattern():
	await Help.wait(wait_to_start_lumniscate_pattern)
	leaf_root.apply_relative_position = true
	while true:
		var delta = get_process_delta_time()
		time_since_started_lemniscate_pattern += delta
		var lemniscate_completion_time_multiplier_progress = min(time_since_started_lemniscate_pattern / time_to_reach_minimum_lemniscate_completion_multiplier, 1)
		var lemnicate_pattern_completion_time_multiplier = lerp(1.0, minimum_lemniscate_pattern_completion_multiplier, lemniscate_completion_time_multiplier_progress)
		pattern_move_progress += delta / (time_to_complete_lemniscate_pattern * lemnicate_pattern_completion_time_multiplier)
		var cycles_completed_in_rad = TAU * pattern_move_progress
		var lemniscate_point = Vector2(sin(cycles_completed_in_rad) * pattern_scale, sin(cycles_completed_in_rad) * cos(cycles_completed_in_rad) * pattern_scale)
		var normalized_point = Vector2(lemniscate_point.x + 1, lemniscate_point.y + 1) / 2
		leaf_root.relative_position = normalized_point
		await Help.wait_frame()

func create_additional_memory_field_rect():
	const wait_time_for_additional_memory_rect_creation = 5.5
	await Help.wait(wait_time_for_additional_memory_rect_creation)
	boss_memory_field.create_projectile_warnings()

const min_circle_projectiles_in_set = 5
const max_circle_projectiles_in_set = 7
var circle_projectiles_in_set: int

const circle_projectile_spawn_distance_portion = 0.425
const min_circle_projectile_scale_multiplier = 0.4
const max_circle_projectile_scale_multiplier = 0.55
const skipped_projectile_count = 1

func generate_skipped_projectile_array() -> Array:
	if skipped_projectile_count > circle_projectiles_in_set: return []
	
	var skipped_projectile_array = []
	for i in range(skipped_projectile_count):
		var random_skipped_projectile = -1
		while true:
			random_skipped_projectile = randi_range(0, circle_projectiles_in_set - 1)
			if not random_skipped_projectile in skipped_projectile_array: break
		skipped_projectile_array.append(random_skipped_projectile)
	
	return skipped_projectile_array

signal circle_projectile_reached_center
const circle_projectile_warning_duration = 0.3

func fire_circle_projectile_set():
	circle_projectiles_in_set = int(lerp(min_circle_projectiles_in_set, max_circle_projectiles_in_set, hardest_circle_projectiles_progress))
	create_circle_projectile_warning()
	await Help.wait(circle_projectile_warning_duration)
	Audio.play(UID.SFX_DIRECTED_PROJECTILE)
	var one_projectile_angle_range = TAU / circle_projectiles_in_set
	var projectile_offset = randf_range(0, one_projectile_angle_range)
	var skipped_projectile_array = generate_skipped_projectile_array()
	
	var before_connected_signal = false
	for i in range(circle_projectiles_in_set):
		if i in skipped_projectile_array: continue
		var circle_projectile = UID.SCN_CIRCLE_PROJECTILE.instantiate()
		if not before_connected_signal:
			circle_projectile.reached_center.connect(func():
				circle_projectile_reached_center.emit()
			)
			before_connected_signal = true
		
		circle_projectile.global_transform = projectile_transform_node.global_transform
		var circle_projectile_scale_multiplier = lerp(min_circle_projectile_scale_multiplier, max_circle_projectile_scale_multiplier, hardest_circle_projectiles_progress)
		circle_projectile.scale *= circle_projectile_scale_multiplier
		circle_projectile.global_position = mouse_cursor.global_position
		
		var projectile_angle = one_projectile_angle_range * i
		projectile_angle += projectile_offset
		var screen_size = DisplayServer.screen_get_size()
		var circle_projectile_spawn_distance = min(screen_size.x, screen_size.y) * circle_projectile_spawn_distance_portion
		var circle_projectile_offset = Vector2.from_angle(projectile_angle) * circle_projectile_spawn_distance
		
		circle_projectile.position += circle_projectile_offset
		circle_projectile.movement_angle = projectile_angle + PI
		circle_projectile.original_distance_from_cursor = circle_projectile_spawn_distance
		circle_projectile.angle_dir = 0
		boss_projectiles.add_child(circle_projectile)

func create_circle_projectile_warning():
	var screen_size = Vector2(DisplayServer.screen_get_size())
	var projectile_warning = UID.SCN_PROJECTILE_WARNING.instantiate()
	projectile_warning.hide()
	projectile_warning.alpha_window = alpha_window
	projectile_warning.relative_position = mouse_cursor.global_position / screen_size
	projectile_warning.warning_animation_duration = circle_projectile_warning_duration * 2
	boss_projectiles.add_child(projectile_warning)
	await Help.wait_frame()
	projectile_warning.show()
