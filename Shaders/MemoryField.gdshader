shader_type canvas_item; 

const int filter_object_max_count = 32;
const int chosen_digit_count = 256;

#include "TilingDiagonals.gdshaderinc"

uniform vec4 outline_color;
uniform vec4 glyph_modulate;
uniform sampler2D memory_field_spritesheet: filter_nearest;
uniform vec2[filter_object_max_count] rect_position_array;
uniform vec2[filter_object_max_count] rect_size_array;
uniform float[filter_object_max_count] rect_rotation_rad_array;
uniform float[filter_object_max_count] rect_outline_size_array;
uniform vec2[filter_object_max_count] circle_position_array;
uniform float[filter_object_max_count] circle_radius_array;
uniform int[chosen_digit_count] digit_tile_array;
uniform float glyphs_per_axis;
uniform float glyph_scale;
uniform vec2 glyph_offset;

bool is_inside_rect(vec2 uv, vec2 rect_pos, vec2 rect_size, float rect_rotation) {
	float aspect_ratio = texture_size.x / texture_size.y;
	rect_size.y *= aspect_ratio;
	
	vec2 relative_point = uv - rect_pos;
	relative_point.x *= aspect_ratio;
	vec2 unrotated_rect_point = vec2(
		relative_point.x * cos(rect_rotation) - relative_point.y * sin(rect_rotation),
		relative_point.x * sin(rect_rotation) + relative_point.y * cos(rect_rotation)
	);
	unrotated_rect_point.x /= aspect_ratio;
	
	vec2 half_size = rect_size / 2.0;
	bool inside_rect =
		unrotated_rect_point.x >= -half_size.x && unrotated_rect_point.x <= half_size.x &&
		unrotated_rect_point.y >= -half_size.y && unrotated_rect_point.y <= half_size.y;
	return inside_rect;
}

bool is_inside_any_rects(vec2 uv, bool is_outline) {
	for (int i = 0; i < filter_object_max_count; i++) {
		float outline_offset = is_outline ? rect_outline_size_array[i] : 0.0;
		vec2 actual_rect_size = rect_size_array[i];
		actual_rect_size = vec2(actual_rect_size.x + outline_offset, actual_rect_size.y + outline_offset);
		
		bool inside_rect = is_inside_rect(uv, rect_position_array[i], actual_rect_size, rect_rotation_rad_array[i]);
		if (inside_rect) return true;
	}
	return false;
}

bool is_inside_circle(vec2 uv, vec2 circle_position, float circle_radius) {
	if (circle_radius < 0.0) return false;
	float aspect_ratio = texture_size.x / texture_size.y;
	circle_position.x *= aspect_ratio;
	vec2 stretched_uv = vec2(uv.x * aspect_ratio, uv.y);
	float dist_to_origin = get_dist(stretched_uv, circle_position);
	bool is_in_circle = dist_to_origin <= circle_radius;
	return is_in_circle;
}

bool is_inside_any_circles(vec2 uv) {
	for (int i = 0; i < filter_object_max_count; i++) {
		vec2 circle_position = circle_position_array[i];
		float circle_radius = circle_radius_array[i];
		bool inside_circle = is_inside_circle(uv, circle_position, circle_radius);
		if (inside_circle) return true;
	}
	return false;
}

const int hex_numeral_count = 16;

void fragment() {
	float aspect_ratio = texture_size.x / texture_size.y;
	vec2 uv_glyph_size = vec2(1.0, aspect_ratio);
	uv_glyph_size /= glyphs_per_axis;
	
	vec2 normalized_offset = vec2(glyph_offset.x / glyphs_per_axis, glyph_offset.y / glyphs_per_axis * aspect_ratio);
	vec2 offseted_uv = UV - normalized_offset;
	vec2 glyph_tile_coord = offseted_uv / uv_glyph_size;
	ivec2 glyph_tile_coord_exact = ivec2(floor(glyph_tile_coord));
	vec2 local_glyph_uv = fract(glyph_tile_coord);
	
	float first_glyph_bounds = (1.0 - glyph_scale) / 2.0, second_glyph_bounds = 1.0 - first_glyph_bounds;
	bool is_out_of_glyph = local_glyph_uv.x < first_glyph_bounds || local_glyph_uv.y < first_glyph_bounds ||
		local_glyph_uv.x > second_glyph_bounds || local_glyph_uv.y > second_glyph_bounds;
	vec2 scaled_local_uv = (local_glyph_uv - (1.0 - glyph_scale) / 2.0) / glyph_scale;
	int glyph_per_row = int(ceil(glyphs_per_axis));
	int glyph_index = glyph_per_row * glyph_tile_coord_exact.y + glyph_tile_coord_exact.x;
	
	int normalized_glyph_index = glyph_index % chosen_digit_count;
	int used_hex_numeral = digit_tile_array[normalized_glyph_index];
	float left_numeral_side_uv = 1.0 / float(hex_numeral_count) * float(used_hex_numeral);
	vec2 numeral_spritesheet_uv = vec2(left_numeral_side_uv + scaled_local_uv.x / float(hex_numeral_count), scaled_local_uv.y);
	
	bool is_in_rect = is_inside_any_rects(UV, false), is_in_rect_outline = is_inside_any_rects(UV, true);
	bool is_in_circle = is_inside_any_circles(UV);
	vec4 used_color = texture(memory_field_spritesheet, numeral_spritesheet_uv);
	used_color *= glyph_modulate;
	if (used_color.a == 0.0 || is_out_of_glyph) used_color = get_color_from_uv(UV);
	if (!is_in_rect || is_in_circle) used_color.a = 0.0;
	if (is_in_rect_outline && !is_in_rect && !is_in_circle) used_color = outline_color;
	COLOR = used_color;
}