shader_type canvas_item;

#include "TilingDiagonals.gdshaderinc"

void fragment() {
	COLOR = get_color_from_uv(UV);
}