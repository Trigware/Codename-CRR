class_name AnimatedLogo
extends Node2D

const logo_size = Vector2(400, 128)
const logo_height_offset = -8

@onready var weird_tree = $"Weird Tree"
@onready var mushroom = $Mushroom
@onready var leaf = $Leaf
@onready var crowbar = $Crowbar
@onready var magnets_root = $Magnet
@onready var blue_magnet = $"Magnet/Blue Magnet"
@onready var red_magnet = $"Magnet/Red Magnet"
@onready var rocks = $Rocks

@onready var eye = $Eye
@onready var center_eye = $Eye/Center
@onready var top_eye = $Eye/Top
@onready var down_eye = $Eye/Down

@onready var blue_dna = $"Blue DNA"
@onready var orange_dna = $"Orange DNA"
@onready var generic_cross = $"Generic Cross"

var skip_enabled: bool

func _ready():
	hide_all_logo_elements()
	await get_tree().process_frame
	if skip_enabled:
		leaf.modulate.a = 1
		animate_generic_cross()
		return
	await handle_logo_animation()

func handle_logo_animation():
	show_weird_tree()
	await Help.wait(0.6)
	show_mushroom()
	await Help.wait(0.55)
	animate_leaf()
	await Help.wait(0.85)
	animate_crowbar()
	await Help.wait(0.5)
	animate_magnets()
	rocks.animate_rocks()
	await Help.wait(0.55)
	animate_generic_cross()
	await Help.wait(0.1)
	animate_eye()
	animate_dna()

func hide_all_logo_elements():
	for child in get_children(): child.modulate.a = 0

const weird_tree_traveled_distance = 55
const weird_tree_tween_duration = 0.8

func show_weird_tree():
	var final_x_pos = weird_tree.position.x
	weird_tree.position.x = final_x_pos - weird_tree_traveled_distance
	create_tween().tween_property(weird_tree, "modulate:a", 1, weird_tree_tween_duration / 2)
	var tree_tween = create_tween().tween_property(weird_tree, "position:x", final_x_pos, weird_tree_tween_duration)
	tree_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	weird_tree.frame = 0
	
	await Help.wait(0.3)
	Audio.play(UID.SFX_SWOOSH)
	weird_tree.play()

const mushroom_start_y_pos = -120
const mushroom_fall_tween_duration = 0.9

func show_mushroom():
	mushroom.modulate.a = 1
	mushroom.position.y = mushroom_start_y_pos
	mushroom.rotation = PI
	create_tween().tween_property(mushroom, "position:y", 0, mushroom_fall_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(mushroom, "rotation", 0, mushroom_fall_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	await Help.wait(0.45)
	Audio.play(UID.SFX_MUSHROOM_FALL)

const leaf_origin_pos_y = 15
const leaf_animation_tween_duration = 0.8

func animate_leaf():
	leaf.position.y = leaf_origin_pos_y
	create_tween().tween_property(leaf, "modulate:a", 1, leaf_animation_tween_duration / 2)
	create_tween().tween_property(leaf, "position:y", 0, leaf_animation_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CIRC)
	leaf.play()
	await Help.wait(0.45)
	Audio.play(UID.SFX_LEAF_APPEAR)

const origin_crowbar_rot_degrees = -30
const crowbar_tween_duration = 0.3

func animate_crowbar():
	crowbar.rotation_degrees = origin_crowbar_rot_degrees
	create_tween().tween_property(crowbar, "modulate:a", 1, crowbar_tween_duration / 2)
	create_tween().tween_property(crowbar, "rotation", 0, crowbar_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	crowbar.play()
	await Help.wait(0.15)
	Audio.play(UID.SFX_CROWBAR)

const magnets_origin_y_offset = 75
const magnets_visibility_show_duration = 0.185
const magnets_drop_tween_duration = 0.3
const magnets_post_drop_sfx_duration = 0.25

func animate_magnets():
	create_tween().tween_property(magnets_root, "modulate:a", 1, magnets_visibility_show_duration)
	var red_magnet_y_origin = red_magnet.position.y
	red_magnet.position.y += magnets_origin_y_offset
	blue_magnet.position.y = -magnets_origin_y_offset
	
	create_tween().tween_property(red_magnet, "position:y", red_magnet_y_origin, magnets_drop_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(blue_magnet, "position:y", 0, magnets_drop_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		
	await Help.wait(magnets_post_drop_sfx_duration)
	Audio.play(UID.SFX_MAGNET_DROP)
	Help.shake_multiple(self, "shake_shift", 3)

var shake_shift = Vector2.ZERO

const eye_visibility_tween_duration = 0.25
const eyebrows_full_y_offset = 25
const eyebrows_origin_y_offset = 10
const eyebrows_show_up_tween_duration = 0.15

func animate_eye():
	center_eye.modulate.a = 0
	top_eye.position.y = -eyebrows_origin_y_offset
	down_eye.position.y = eyebrows_origin_y_offset
	create_tween().tween_property(eye, "modulate:a", 1, eye_visibility_tween_duration)
	
	create_tween().tween_property(top_eye, "position:y", -eyebrows_full_y_offset, eyebrows_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	create_tween().tween_property(down_eye, "position:y", eyebrows_full_y_offset, eyebrows_show_up_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)

func animate_dna():
	blue_dna.modulate.a = 1
	orange_dna.modulate.a = 1
	blue_dna.play()
	orange_dna.play()
	Audio.play(UID.SFX_DNA_APPEAR)

const generic_cross_final_x_pos = 221
const generic_cross_origin_x_pos = -100
const cross_move_tween_duration = 0.6
const cross_show_duration = 0.15
const cross_overlay_wait_duration = 0.4
const cross_overlay_inbetween_wait = 0.325
const eye_center_tween_show_duration = 0.4

var white_overlay_alpha: float = 0

func animate_generic_cross():
	generic_cross.position.x = generic_cross_origin_x_pos
	create_tween().tween_property(generic_cross, "modulate:a", 1, cross_show_duration)
	create_tween().tween_property(generic_cross, "position:x", generic_cross_final_x_pos, cross_move_tween_duration).\
		set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	Audio.play(UID.SFX_CROSS_APPEAR)
	
	if not skip_enabled: await Help.wait(cross_overlay_wait_duration)
	var overlay_tween_duration = cross_move_tween_duration - cross_overlay_wait_duration
	create_tween().tween_property(center_eye, "modulate:a", 1, eye_center_tween_show_duration)
	if not skip_enabled: await create_tween().tween_property(self, "white_overlay_alpha", 1, overlay_tween_duration).finished
	await Help.wait(cross_overlay_inbetween_wait)
	hide_logo()
	create_tween().tween_property(self, "white_overlay_alpha", 0, overlay_tween_duration)
	whiteout_ended.emit()

const leaf_center_move_tween_duration = 0.65

func hide_logo():
	for child in get_children():
		if child == leaf: continue
		child.hide()

signal whiteout_ended
