extends Control

func _ready():
	$Title/Earth.playing = true

func set_logo_position(position):
	$Title.rect_position = position

func form_logo():
	$AnimationPlayer.play("Start")
