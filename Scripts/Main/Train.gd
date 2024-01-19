extends KinematicBody2D

var inputVector := Vector2.ZERO
var lastPos := Vector2.ZERO
export (int) var spacing = 20
var delay = 0.2


onready var animation = $AnimationPlayer
onready var animationTree = $AnimationTree

func _ready():
	animation.play("Move Right")
	
	
func _physics_process(delta):
	global.persistPlayer.position.x = self.global_position.x
	global.persistPlayer.position.y = self.global_position.y
	
