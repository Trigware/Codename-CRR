shader_type canvas_item;

const int digit_array_count = 256;

uniform vec2 pixel_count = vec2(1000, 1000);
uniform vec2 texture_size;
uniform vec2 texture_scale;
uniform float diagonal_lines;
uniform float gap_size;
uniform float pattern_repeated;
uniform vec4 line_color;
uniform vec4 gap_color;
uniform sampler2D base_texture: filter_nearest;
uniform float texture_progress;
uniform float alpha_modulate = 1.0;
uniform float tile_size;
uniform bool[digit_array_count] empty_tiles;
uniform bool circle_filter_enabled;
uniform float outer_circle_radius;
uniform float inner_circle_radius;
uniform float highlight_circle_radius_offset;
uniform vec4 highlighted_circle_modulate;
uniform bool is_shadow;

const vec2 pixel_offset = vec2(0.5), center = vec2(0.5);
const vec2 comparison_pivot = vec2(0.0);

float get_dist(vec2 a, vec2 b) {
	float x_dist = a.x - b.x, y_dist = a.y - b.y;
	return sqrt(x_dist*x_dist + y_dist*y_dist);
}

bool is_in_circle(vec2 uv, float radius) {
	float dist_from_center = get_dist(center, uv);
	return dist_from_center < radius;
}

vec4 handle_circle_filtering(vec4 used_color, vec2 uv) {
	if (!is_in_circle(uv, outer_circle_radius) || is_in_circle(uv, inner_circle_radius)) used_color.a = 0.0;
	if (is_in_circle(uv, inner_circle_radius + highlight_circle_radius_offset))
		used_color *= highlighted_circle_modulate;
	return used_color;
}

void fragment() {
	vec2 pixel_size = 1.0 / pixel_count;
	vec2 used_uv = UV * texture_size / texture_scale;
	vec2 pixel_coord = floor(used_uv / pixel_size) + pixel_offset;
	vec2 pixel_uv = pixel_coord / pixel_count;
	
	vec2 rotated_uv = vec2(pixel_uv.y, pixel_uv.x);
	vec2 midpoint = (pixel_uv + rotated_uv) / 2.0;
	float dist = get_dist(midpoint, comparison_pivot) - pattern_repeated;
	
	float sector_length = 1.0 / diagonal_lines;
	float sector_portion = fract(dist / sector_length);
	float half_gap = gap_size / 2.0;
	bool in_gap = (sector_portion <= half_gap || sector_portion >= 1.0 - half_gap) && gap_size != 0.0;
	
	vec4 diagonals_color = in_gap ? gap_color : line_color;
	vec4 used_color = vec4(0.0, 0.0, 0.0, 0.0);
	vec4 texture_color = texture(base_texture, UV);
	vec4 lerped_diagonals = mix(diagonals_color, texture_color, texture_progress);
	if (texture_color.a == 1.0) used_color = lerped_diagonals;
	used_color.a *= alpha_modulate;
	
	float aspect_ratio = texture_size.y / texture_size.x / texture_scale.y;
	int y_tile_pos = int(UV.y * aspect_ratio / tile_size);
	ivec2 tile_pos = ivec2(int(UV.x / tile_size), y_tile_pos);
	int tile_x_count = int(ceil(1.0 / tile_size));
	int tile_index = tile_pos.y * tile_x_count + tile_pos.x;
	int normalized_tile_index = tile_index % digit_array_count;
	bool is_tile_empty = empty_tiles[normalized_tile_index];
	if (is_tile_empty) used_color.a = 0.0;
	
	if (circle_filter_enabled) used_color = handle_circle_filtering(used_color, UV);
	if (is_shadow) used_color.rgb = vec3(0);
	COLOR = used_color;
}