extends Node2D

var time := 0.0

func _ready():
	for i in range(get_child_count()):
			get_child(i).playing = true

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_up"):
		$arrowU/AnimationPlayer.play("Point")
	if Input.is_action_just_pressed("ui_down"):
		$arrowD/AnimationPlayer.play("Point")
	if Input.is_action_just_pressed("ui_left"):
		$arrowL/AnimationPlayer.play("Point")
	if Input.is_action_just_pressed("ui_right"):
		$arrowR/AnimationPlayer.play("Point")
	if Input.is_action_just_released("ui_up"):
		$arrowU/AnimationPlayer.play("UnPoint")
	if Input.is_action_just_released("ui_down"):
		$arrowD/AnimationPlayer.play("UnPoint")
	if Input.is_action_just_released("ui_left"):
		$arrowL/AnimationPlayer.play("UnPoint")
	if Input.is_action_just_released("ui_right"):
		$arrowR/AnimationPlayer.play("UnPoint")
