extends KinematicBody2D



onready var animation = $AnimationPlayer
onready var animationTree = $AnimationTree

func _ready():
	animation.play("Move Left")
