class_name MouseCursor
extends Area2D

func _ready():
	area_entered.connect(on_area_entered)

const cursor_size = Vector2(18, 27)

func on_area_entered(area: Area2D):
	if not is_in_any_group(area, "UIProjectile", "FallingWindow"): return
	if area.is_in_group("FallingWindow") and area.is_window_safe: return
	#print("Hit Cursor")

func is_in_any_group(area: Area2D, ...groups):
	for group_name: String in groups:
		if area.is_in_group(group_name): return true
	return false
