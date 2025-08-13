extends Node2D

func _process(delta):
	if Input.is_action_just_pressed("ui_F1"):
		clear_sky()

func clear_sky():
	$AnimationPlayer.play("Clear Up")
