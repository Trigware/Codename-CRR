@tool
class_name TiledDiagonals
extends ColorRect

enum UniformType {
	PixelCount,
	TextureSize,
	TextureScale,
	DiagonalLines,
	GapSize,
	PatternRepeated,
	LineColor,
	GapColor,
	RotationRepeated,
	BaseTexture,
	TextureProgress,
	AlphaModulate,
	TileSize,
	EmptyTiles,
	CircleFilterEnabled,
	OuterCircleRadius,
	InnerCircleRadius,
	HighlightCircleRadiusOffset,
	HighlightedCircleModulate,
	IsShadow
}

@export var diagonal_lines: float:
	set(value): diagonal_lines = value; set_uniform(UniformType.DiagonalLines, value)
@export_range(0, 1) var gap_size: float:
	set(value): gap_size = value; set_uniform(UniformType.GapSize, value)
var pattern_repeated: float = 0:
	set(value): pattern_repeated = value; set_uniform(UniformType.PatternRepeated, value)
@export var line_color: Color
@export var pixel_count: Vector2i:
	set(value): pixel_count = value; set_uniform(UniformType.PixelCount, value)
@export var texture_scale: Vector2
@export var rotation_repeated: float:
	set(value): rotation_repeated = value; set_uniform(UniformType.RotationRepeated, value)
@export var value_offset: float
@export var pattern_speed: float
@export var position_offset: Vector2
@export var base_texture: Texture:
	set(value): base_texture = value; set_uniform(UniformType.BaseTexture, value)
@export var texture_progress: float:
	set(value): texture_progress = value; set_uniform(UniformType.TextureProgress, value)
@export var alpha_modulate: float = 1:
	set(value): alpha_modulate = value; set_uniform(UniformType.AlphaModulate, value)
@export var tile_size: float:
	set(value): tile_size = value; set_uniform(UniformType.TileSize, value)
@export var empty_tiles_change_duration: float:
	set(value): empty_tiles_change_duration = value; last_switched_tiles_session = -1
@export_range(0, 1) var empty_tiles_rate: float
@export var scale_affects_position: bool = true
@export var circle_filter_enabled: bool = false:
	set(value): circle_filter_enabled = value; set_uniform(UniformType.CircleFilterEnabled, value)
@export var outer_circle_radius: float:
	set(value): outer_circle_radius = value; set_uniform(UniformType.OuterCircleRadius, value)
@export var inner_circle_radius: float:
	set(value): inner_circle_radius = value; set_uniform(UniformType.InnerCircleRadius, value)
@export var highlight_circle_radius_offset: float:
	set(value): highlight_circle_radius_offset = value; set_uniform(UniformType.HighlightCircleRadiusOffset, value)
@export var highlighted_circle_modulate := Color.WHITE:
	set(value): highlighted_circle_modulate = value; set_uniform(UniformType.HighlightedCircleModulate, value)
@export var is_shadow: bool:
	set(value): is_shadow = value; set_uniform(UniformType.IsShadow, value)

func uniform_as_str(uniform: UniformType) -> String: return UniformType.keys()[uniform].to_snake_case()
func set_uniform(parameter: UniformType, value): material.set_shader_parameter(uniform_as_str(parameter), value)

const default_texture_size = Vector2(40, 40)
const tile_array_count = 256

func _ready():
	init_gap_size = gap_size

func _process(delta: float):
	set_uniform(UniformType.TextureSize, size / default_texture_size)
	set_uniform(UniformType.TextureScale, texture_scale / scale)
	set_colors()
	var used_scale = scale if scale_affects_position else Vector2.ONE
	position = -size * used_scale / 2.0 + size / 2.0 + position_offset
	pattern_repeated += delta * pattern_speed
	handle_empty_tiles()

func set_colors():
	set_uniform(UniformType.LineColor, line_color)
	var gap_color = line_color
	gap_color.v -= value_offset;
	set_uniform(UniformType.GapColor, gap_color)

const color_change_half_step_duration = 0.85
const half_step_gap_size = 1.0
var init_gap_size: float

func change_color(new_color: Color):
	var half_step_color = line_color
	half_step_color.s = 0
	create_tween().tween_property(self, "line_color", half_step_color, color_change_half_step_duration)
	await create_tween().tween_property(self, "gap_size", half_step_gap_size, color_change_half_step_duration).set_ease(Tween.EASE_IN_OUT).finished
	create_tween().tween_property(self, "line_color", new_color, color_change_half_step_duration)
	create_tween().tween_property(self, "gap_size", init_gap_size, color_change_half_step_duration).set_ease(Tween.EASE_IN_OUT)

const miliseconds_in_seconds: float = 1000

var last_switched_tiles_session = -1

func handle_empty_tiles():
	var elapsed_time = Time.get_ticks_msec() / miliseconds_in_seconds
	var amount_of_elapsed_sessions = floori(elapsed_time / empty_tiles_change_duration)
	var is_session_new = amount_of_elapsed_sessions != last_switched_tiles_session
	last_switched_tiles_session = amount_of_elapsed_sessions
	if empty_tiles_change_duration == 0: is_session_new = true
	if not is_session_new: return
	
	randomize_empty_tile_array()

func reset_circle_values():
	outer_circle_radius = 0
	inner_circle_radius = 0
	highlight_circle_radius_offset = 0

func randomize_empty_tile_array():
	var empty_tile_array = []
	for i in range(tile_array_count):
		var random_value = randf()
		var is_tile_empty = random_value <= empty_tiles_rate
		empty_tile_array.append(is_tile_empty)
	set_uniform(UniformType.EmptyTiles, empty_tile_array)
