class_name MemoryFieldCircle
extends Resource

@export var position: Vector2
@export var radius: float

static func make_centered(circle_radius: float) -> MemoryFieldCircle:
	var memory_field_circle = MemoryFieldCircle.new()
	memory_field_circle.position = Vector2(0.5, 0.5)
	memory_field_circle.radius = circle_radius
	return memory_field_circle
