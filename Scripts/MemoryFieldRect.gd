class_name MemoryFieldRect
extends Resource

@export var rect: Rect2
@export var rotation_radians: float
@export var outline_thickness: float

static func make_centered() -> MemoryFieldRect:
	var memory_field_rect = MemoryFieldRect.new()
	memory_field_rect.rect = Rect2(0.5, 0.5, INF, 0)
	return memory_field_rect
