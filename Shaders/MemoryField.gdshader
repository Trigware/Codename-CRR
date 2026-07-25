shader_type canvas_item; 

const int rect_max_count = 32;
const int chosen_digit_count = 256;

uniform vec4 background_color;
uniform vec4 outline_color;
uniform sampler2D memory_field_spritesheet: filter_nearest;
uniform vec2[rect_max_count] rect_position_array;
uniform vec2[rect_max_count] rect_size_array;
uniform float[rect_max_count] rect_rotation_rad_array;
uniform float[rect_max_count] rect_outline_size_array;
uniform int[chosen_digit_count] digit_tile_array;
uniform vec2 texture_size;
uniform float glyphs_per_axis;
uniform float glyph_scale;

bool is_inside_rect(vec2 uv, vec2 rect_pos, vec2 rect_size, float rect_rotation) {
	vec2 relative_point = uv - rect_pos;
	vec2 unrotated_rect_point = vec2(
		relative_point.x * cos(rect_rotation) - relative_point.y * sin(rect_rotation),
		relative_point.x * sin(rect_rotation) + relative_point.y * cos(rect_rotation)
	);
	
	vec2 half_size = rect_size / 2.0;
	bool inside_rect =
		unrotated_rect_point.x >= -half_size.x && unrotated_rect_point.x <= half_size.x &&
		unrotated_rect_point.y >= -half_size.y && unrotated_rect_point.y <= half_size.y;
	return inside_rect;
}

bool is_inside_any_rects(vec2 uv, bool is_outline) {
	for (int i = 0; i < rect_max_count; i++) {
		float outline_offset = is_outline ? rect_outline_size_array[i] : 0.0;
		vec2 actual_rect_size = rect_size_array[i];
		actual_rect_size = vec2(actual_rect_size.x + outline_offset, actual_rect_size.y + outline_offset);
		
		bool inside_rect = is_inside_rect(uv, rect_position_array[i], actual_rect_size, rect_rotation_rad_array[i]);
		if (inside_rect) return true;
	}
	return false;
}

const int hex_numeral_count = 16;

void fragment() {
	float aspect_ratio = texture_size.x / texture_size.y;
	bool is_glyph_size_based_on_x = aspect_ratio >= 1.0;
	vec2 uv_glyph_size = is_glyph_size_based_on_x ? vec2(1.0, aspect_ratio) : vec2(1.0 / aspect_ratio, 1.0);
	uv_glyph_size /= glyphs_per_axis;
	
	vec2 glyph_tile_coord = UV / uv_glyph_size;
	ivec2 glyph_tile_coord_exact = ivec2(floor(glyph_tile_coord));
	vec2 local_glyph_uv = fract(glyph_tile_coord);
	
	float first_glyph_bounds = (1.0 - glyph_scale) / 2.0, second_glyph_bounds = 1.0 - first_glyph_bounds;
	bool is_out_of_glyph = local_glyph_uv.x < first_glyph_bounds || local_glyph_uv.y < first_glyph_bounds ||
		local_glyph_uv.x > second_glyph_bounds || local_glyph_uv.y > second_glyph_bounds;
	vec2 scaled_local_uv = (local_glyph_uv - (1.0 - glyph_scale) / 2.0) / glyph_scale;
	int glyph_per_row = is_glyph_size_based_on_x ? int(ceil(glyphs_per_axis)) : int(ceil(glyphs_per_axis * aspect_ratio));
	int glyph_index = glyph_per_row * glyph_tile_coord_exact.y + glyph_tile_coord_exact.x;
	
	int normalized_glyph_index = glyph_index % chosen_digit_count;
	int used_hex_numeral = digit_tile_array[normalized_glyph_index];
	float left_numeral_side_uv = 1.0 / float(hex_numeral_count) * float(used_hex_numeral);
	vec2 numeral_spritesheet_uv = vec2(left_numeral_side_uv + scaled_local_uv.x / float(hex_numeral_count), scaled_local_uv.y);
	
	bool is_in_rect = is_inside_any_rects(UV, false), is_in_rect_outline = is_inside_any_rects(UV, true);
	vec4 used_color = texture(memory_field_spritesheet, numeral_spritesheet_uv);
	if (used_color.a == 0.0 || is_out_of_glyph) used_color = background_color;
	if (!is_in_rect) used_color.a = 0.0;
	if (is_in_rect_outline && !is_in_rect) used_color = outline_color;
	COLOR = used_color;
}