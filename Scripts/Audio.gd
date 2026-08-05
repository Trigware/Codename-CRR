class_name AudioManager
extends Node

func play(sound, volume = 0, pitch = 1):
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = sound
	sound_player.volume_db = volume
	sound_player.pitch_scale = pitch
	add_child(sound_player)
	sound_player.play()
	await sound_player.finished
	sound_player.queue_free()

const default_pitch_range = 0.2

func play_pitch(sound, volume = 0, pitch_range = default_pitch_range):
	var chosen_pitch = randf_range(-pitch_range, pitch_range)
	await play(sound, volume, 1 + chosen_pitch)
