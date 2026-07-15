extends AnimatedSprite2D

func start():
	play()
	Audio.play(UID.SFX_EXPLOSION)
	await animation_finished
	queue_free()
