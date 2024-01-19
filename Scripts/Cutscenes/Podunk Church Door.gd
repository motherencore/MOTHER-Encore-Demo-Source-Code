extends Sprite

func open():
	$AnimationPlayer.play("Open")
	yield($AnimationPlayer, "animation_finished")
	queue_free()
