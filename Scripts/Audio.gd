class_name AudioManager
extends Node

func play(sound):
	var sound_player = AudioStreamPlayer.new()
	sound_player.stream = sound
	add_child(sound_player)
	sound_player.play()
	await sound_player.finished
	sound_player.queue_free()
