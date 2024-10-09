extends Node2D

var time := 0.0

func _ready():
	for i in range(get_child_count()):
			get_child(i).playing = true

func _input(event):
	if controlsManager.get_just_pressed_up():
		$arrowU/AnimationPlayer.play("Point")
	if controlsManager.get_just_pressed_down():
		$arrowD/AnimationPlayer.play("Point")
	if controlsManager.get_just_pressed_left():
		$arrowL/AnimationPlayer.play("Point")
	if controlsManager.get_just_pressed_right():
		$arrowR/AnimationPlayer.play("Point")
	if controlsManager.get_just_released_up():
		$arrowU/AnimationPlayer.play("UnPoint")
	if controlsManager.get_just_released_down():
		$arrowD/AnimationPlayer.play("UnPoint")
	if controlsManager.get_just_released_left():
		$arrowL/AnimationPlayer.play("UnPoint")
	if controlsManager.get_just_released_right():
		$arrowR/AnimationPlayer.play("UnPoint")
