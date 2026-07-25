@tool
class_name MemoryField
extends ColorRect

enum UniformType {
	BackgroundColor,
	OutlineColor,
	MemoryFieldSpritesheet,
	RectPositionArray,
	RectSizeArray,
	RectRotationRadArray,
	RectOutlineSizeArray,
	TextureSize,
	GlyphsPerAxis,
	DigitTileArray,
	GlyphScale
}

@export var background_color: Color:
	set(value): background_color = value; set_uniform(UniformType.BackgroundColor, value)
@export var outline_color: Color:
	set(value): outline_color = value; set_uniform(UniformType.OutlineColor, value)
@export var memory_field_spritesheet: Texture2D:
	set(value): memory_field_spritesheet = value; set_uniform(UniformType.MemoryFieldSpritesheet, value)
@export var glyphs_per_axis: float = 1:
	set(value): glyphs_per_axis = value; set_uniform(UniformType.GlyphsPerAxis, value)
@export var rect_array: Array[MemoryFieldRect]
@export var memory_digits_time_to_reset: float
@export var glyph_scale: float = 1:
	set(value): glyph_scale = value; set_uniform(UniformType.GlyphScale, value)

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value): material.set_shader_parameter(uniform_as_str(parameter), value)

func _process(_delta):
	set_uniform(UniformType.TextureSize, size)
	handle_memory_digits_timer()
	if Engine.is_editor_hint(): update_rect_array()

func update_rect_array():
	var rect_position_array = []; var rect_size_array = []; var rect_rotation_rad_array = []; var rect_outline_size_array = []
	for memory_field_rect: MemoryFieldRect in rect_array:
		rect_position_array.append(memory_field_rect.rect.position)
		rect_size_array.append(memory_field_rect.rect.size)
		rect_rotation_rad_array.append(memory_field_rect.rotation_radians)
		rect_outline_size_array.append(memory_field_rect.outline_thickness)
	
	set_uniform(UniformType.RectPositionArray, rect_position_array)
	set_uniform(UniformType.RectSizeArray, rect_size_array)
	set_uniform(UniformType.RectRotationRadArray, rect_rotation_rad_array)
	set_uniform(UniformType.RectOutlineSizeArray, rect_outline_size_array)

var previous_time_section : float = -1

func handle_memory_digits_timer():
	var sec_since_start = Time.get_ticks_msec() / 1000.0
	var current_time_section = floor(sec_since_start / memory_digits_time_to_reset)
	var is_section_new = current_time_section != previous_time_section
	if not is_section_new: return
	
	previous_time_section = current_time_section
	handle_memory_digits_reset()

const digit_array_count = 256
const hex_numeral_count = 16

func handle_memory_digits_reset():
	var digit_tile_array = []
	for i in range(digit_array_count):
		var tile_numeral = randi_range(0, hex_numeral_count - 1)
		digit_tile_array.append(tile_numeral)
	set_uniform(UniformType.DigitTileArray, digit_tile_array)
