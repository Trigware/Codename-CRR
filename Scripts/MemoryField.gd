@tool
class_name MemoryField
extends TiledDiagonals

enum MemoryFieldUniform {
	OutlineColor,
	GlyphModulate,
	MemoryFieldSpritesheet,
	RectPositionArray,
	RectSizeArray,
	RectRotationRadArray,
	RectOutlineSizeArray,
	CirclePositionArray,
	CircleRadiusArray,
	CircleAlphaModulate,
	TextureSize,
	GlyphsPerAxis,
	DigitTileArray,
	GlyphScale,
	GlyphOffset
}

@export var outline_color: Color
@export var glyph_modulate: Color
@export var memory_field_spritesheet: Texture2D
@export var glyphs_per_axis: float = 1
@export var rect_array: Array[MemoryFieldRect]
@export var circle_array: Array[MemoryFieldCircle]
@export var memory_digits_time_to_reset: float
@export var glyph_scale: float = 1
@export var glyph_offset: Vector2
@export var circle_alpha_modulate: float = 1

func mem_uniform_as_str(uniform: MemoryFieldUniform) -> String: return MemoryFieldUniform.keys()[uniform].to_snake_case()
func mem_set_uniform(parameter: MemoryFieldUniform, value): material.set_shader_parameter(mem_uniform_as_str(parameter), value)

func _ready():
	update_visibility_changing_array()

func _process(delta: float):
	update_field_values()
	handle_memory_digits_timer()
	update_visibility_changing_array()
	super(delta)

func update_field_values():
	mem_set_uniform(MemoryFieldUniform.TextureSize, size)
	mem_set_uniform(MemoryFieldUniform.OutlineColor, outline_color)
	mem_set_uniform(MemoryFieldUniform.GlyphModulate, glyph_modulate)
	mem_set_uniform(MemoryFieldUniform.MemoryFieldSpritesheet, memory_field_spritesheet)
	mem_set_uniform(MemoryFieldUniform.GlyphsPerAxis, glyphs_per_axis)
	mem_set_uniform(MemoryFieldUniform.GlyphScale, glyph_scale)
	mem_set_uniform(MemoryFieldUniform.GlyphOffset, glyph_offset)

func update_visibility_changing_array():
	var rect_position_array = []; var rect_size_array = []; var rect_rotation_rad_array = []; var rect_outline_size_array = []
	var circle_position_array = []; var circle_radius_array = []
	
	for memory_field_rect in rect_array:
		if not memory_field_rect is MemoryFieldRect: continue
		rect_position_array.append(memory_field_rect.rect.position)
		rect_size_array.append(memory_field_rect.rect.size)
		rect_rotation_rad_array.append(memory_field_rect.rotation_radians)
		rect_outline_size_array.append(memory_field_rect.outline_thickness)
	
	for memory_field_circle in circle_array:
		if not memory_field_circle is MemoryFieldCircle: continue
		circle_position_array.append(memory_field_circle.position)
		circle_radius_array.append(memory_field_circle.radius)
	
	mem_set_uniform(MemoryFieldUniform.RectPositionArray, rect_position_array)
	mem_set_uniform(MemoryFieldUniform.RectSizeArray, rect_size_array)
	mem_set_uniform(MemoryFieldUniform.RectRotationRadArray, rect_rotation_rad_array)
	mem_set_uniform(MemoryFieldUniform.RectOutlineSizeArray, rect_outline_size_array)
	
	mem_set_uniform(MemoryFieldUniform.CirclePositionArray, circle_position_array)
	mem_set_uniform(MemoryFieldUniform.CircleRadiusArray, circle_radius_array)
	mem_set_uniform(MemoryFieldUniform.CircleAlphaModulate, circle_alpha_modulate)

var previous_time_section : float = -1

func handle_memory_digits_timer():
	var sec_since_start = Time.get_ticks_msec() / 1000.0
	var current_time_section = floor(sec_since_start / memory_digits_time_to_reset)
	var is_section_new = current_time_section != previous_time_section
	if not is_section_new: return
	
	previous_time_section = current_time_section
	handle_memory_digits_reset()

const digit_array_count = 256
const hex_numeral_count = 2

func handle_memory_digits_reset():
	var digit_tile_array = []
	for i in range(digit_array_count):
		var tile_numeral = randi_range(0, hex_numeral_count - 1)
		digit_tile_array.append(tile_numeral)
	mem_set_uniform(MemoryFieldUniform.DigitTileArray, digit_tile_array)
