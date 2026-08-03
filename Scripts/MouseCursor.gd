extends Area2D

func _ready():
	area_entered.connect(on_area_entered)

const cursor_size = Vector2(18, 27)

func on_area_entered(area: Area2D):
	if not area.is_in_group("UIProjectile"): return
	print("Cursor hit!")
