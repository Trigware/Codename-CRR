@tool
class_name BossMemoryField
extends Control

@onready var memory_field: MemoryField = $MemoryField
@onready var warning_root = $"Warning Root"
@onready var alpha_window: AlphaWindowHandleler = get_parent()
@onready var boss_leaf: LeafBossRoot = alpha_window.get_node("Boss Leaf")

func _process(delta: float):
	if not Engine.is_editor_hint(): memory_field.size = DisplayServer.screen_get_size()
	handle_field_objects()
	progress_memory_field_rotations(delta)

const projectile_warning_count: int = 10
const projectile_warning_padding: float = 0.06

signal created_memory_field

func create_projectile_warnings():
	for i in range(projectile_warning_count):
		var projectile_warning: ProjectileWarning = UID.SCN_PROJECTILE_WARNING.instantiate()
		projectile_warning.alpha_window = alpha_window
		if i == 0: projectile_warning.ended_warning_animation.connect(create_memory_field_rect)
		var regular_x_pos = float(i) / (projectile_warning_count - 1)
		var relative_x_pos = regular_x_pos * (1 - projectile_warning_padding) + projectile_warning_padding / 2
		projectile_warning.relative_position.x = relative_x_pos
		projectile_warning.relative_scale = 1.0 / projectile_warning_count * (1 - projectile_warning_padding)
		warning_root.add_child(projectile_warning)

func progress_memory_field_rotations(delta: float):
	if memory_field.rect_array.size() == 0: return
	current_rotation_speed += max_rotation_speed * delta / duration_to_max_rotation
	current_rotation_speed = min(current_rotation_speed, max_rotation_speed)
	for i in range(memory_field.rect_array.size()):
		var memory_field_rect: MemoryFieldRect = memory_field.rect_array[i]
		memory_field_rect.rotation_radians += current_rotation_speed * delta

const memory_rect_height_tween_duration: float = 0.85
const leaf_ring_size = 80
const max_memory_field_rect_height_portion = 0.075
var memory_field_circle = null

var current_rotation_speed: float = 0
const max_rotation_speed: float = PI * 0.35
const duration_to_max_rotation: float = 20
var has_created_memory_field_rect_before = false

func create_memory_field_rect():
	var screen_size = DisplayServer.screen_get_size()
	var aspect_ratio = screen_size.x / screen_size.y
	var memory_field_rect = MemoryFieldRect.make_centered()
	var used_rect_height = 1.0 / aspect_ratio * max_memory_field_rect_height_portion
	Help.tween(memory_field_rect, "rect:size:y", used_rect_height, memory_rect_height_tween_duration)
	memory_field.rect_array.append(memory_field_rect)
	
	if not has_created_memory_field_rect_before:
		var leaf_ring_scaled = leaf_ring_size * boss_leaf.scale
		var height_circle_count = screen_size.y / leaf_ring_scaled.y
		var circle_radius = 1.0 / height_circle_count / 2.0
		memory_field_circle = MemoryFieldCircle.make_centered(circle_radius)
		memory_field.circle_array.append(memory_field_circle)
		created_memory_field.emit()
	has_created_memory_field_rect_before = true

func handle_field_objects():
	var screen_size = Vector2(DisplayServer.screen_get_size())
	if boss_leaf == null: return
	var relative_leaf_position = boss_leaf.position / screen_size
	if memory_field_circle is MemoryFieldCircle: memory_field_circle.position = relative_leaf_position
	for memory_field_rect: MemoryFieldRect in memory_field.rect_array:
		memory_field_rect.rect.position = relative_leaf_position
