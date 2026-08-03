class_name CircleProjectile
extends UIProjectile

var original_distance_from_cursor: float

func _ready():
	can_explode = false
	alpha_mod = 0
	update_modulate()
	Help.tween(self, "alpha_mod", 1, projectile_modulate_tween_duration)

var has_reached_center = false

const projectile_disappear_duration = 0.185

signal reached_center

func _process(delta: float):
	move_projectile(delta)
	if not has_reached_center: update_modulate()
	if projectile_traveled_distance > original_distance_from_cursor: on_reaching_original_cursor_position()

const disappear_on_reaching_center = false

func on_reaching_original_cursor_position():
	reached_center.emit()
	if not has_reached_center and disappear_on_reaching_center:
		Help.tween_hide(self, projectile_disappear_duration)
		await Help.tween(missing_texture, "alpha_modulate", 0, projectile_disappear_duration)
		queue_free()
	has_reached_center = true
	if not disappear_on_reaching_center: can_explode = true
