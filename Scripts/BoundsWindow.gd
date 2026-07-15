class_name BoundsWindow
extends Window

@onready var background = $Background
@onready var animated_logo = $AnimatedLogo
@onready var overlay = $Overlay

var bounds_window_size: Vector2i
const bounds_background_size_multiplier = 1.5
const init_title = "LeafCROSS"
const logo_spacing_multiplier = 0.885
const monitor_window_size_multiplier = 0.6
const window_height_multiplier = 0.6

func _ready():
	background.show()
	var monitor_size = DisplayServer.screen_get_size()
	bounds_window_size = Vector2(monitor_size) * monitor_window_size_multiplier
	bounds_window_size.y *= window_height_multiplier
	size = bounds_window_size
	background.color = Color.BLACK
	title = init_title
	animated_logo.whiteout_ended.connect(on_logo_whiteout_ended)
	
	unresizable = true
	position = monitor_size / 2 - bounds_window_size / 2
	close_requested.connect(on_close_requested)

const expected_height_offset_size: float = 300
const window_header_height = 36

func _process(_delta):
	if mode != Window.MODE_WINDOWED: mode = Window.MODE_WINDOWED
	background.size = size * bounds_background_size_multiplier
	overlay.size = background.size
	overlay.color.a = animated_logo.white_overlay_alpha
	
	if has_whiteout_ended: size = intended_window_size
	handle_logo_position()

func on_close_requested():
	get_tree().quit()

func handle_logo_position():
	if has_whiteout_ended: return
	var scale_multiplier = min(size.x / animated_logo.logo_size.x, size.y / animated_logo.logo_size.y)
	var used_multiplier = scale_multiplier * logo_spacing_multiplier
	var x_remainder = size.x - animated_logo.logo_size.x * used_multiplier
	var x_logo_pos = x_remainder / 2
	
	var height_offset_multiplier = size.y / expected_height_offset_size
	var y_logo_pos = size.y / 2 + animated_logo.logo_height_offset * height_offset_multiplier
	animated_logo.position = Vector2(x_logo_pos, y_logo_pos) + animated_logo.shake_shift
	animated_logo.scale = Vector2.ONE * used_multiplier

const window_resize_tween_duration = 0.6
const leaf_scale_multiplier = 1.4
var has_whiteout_ended = false
var intended_window_size: Vector2

signal leaf_resize_end

func on_logo_whiteout_ended():
	var final_window_width = bounds_window_size.y
	var final_width_difference = size.x - final_window_width
	var final_window_pos_x = position.x + final_width_difference / 2
	has_whiteout_ended = true
	var final_leaf_scale = Vector2.ONE * leaf_scale_multiplier
	intended_window_size = size
	
	create_tween().tween_property(self, "intended_window_size:x", final_window_width, window_resize_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(self, "position:x", final_window_pos_x, window_resize_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	
	create_tween().tween_property(animated_logo.leaf, "global_position:x", final_window_width / 2, window_resize_tween_duration)
	await create_tween().tween_property(animated_logo.leaf, "scale", final_leaf_scale, window_resize_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD).finished
	leaf_resize_end.emit()
