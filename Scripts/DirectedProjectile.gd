class_name DirectedProjectile
extends UIProjectile

const angle_multiplier_tween_duration = 0.15
const angle_tween_wait_duration = 0.8
const init_projectile_speed = 0.225

func _ready():
	is_corrupted = projectile_angle_diff != 0
	projectile_speed = init_projectile_speed
	tween_angle_multiplier()

func tween_angle_multiplier():
	var next_angle_multiplier = 1.0 if angle_multiplier == -1.0 else -1.0
	await Help.tween(self, "angle_multiplier", next_angle_multiplier, angle_multiplier_tween_duration)
	await Help.wait(angle_tween_wait_duration)
	tween_angle_multiplier()

func _process(delta: float):
	update_modulate()
	projectile_speed *= 1 + projectile_speed_increase * delta
	move_projectile(delta)
