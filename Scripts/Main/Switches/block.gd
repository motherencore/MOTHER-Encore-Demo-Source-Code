extends Sprite

var active = false
var can_activate = true
onready var animationState = $AnimationTree.get("parameters/playback")
onready var partyMember = preload("res://Nodes/Reusables/PartyFollower.tscn")

func _ready():
	$AnimationTree.active = true
	if active:
		$Sprite.texture = load("res://Graphics/Objects/Block Blue.png")
		animationState.travel("Stay Open")
	else:
		$Sprite.texture = load("res://Graphics/Objects/Block Red.png")
		animationState.travel("Stay Closed")

func _process(delta):
	if "block" in global.currentScene and can_activate == true:
		if (global.currentScene.block and active) or (!global.currentScene.block and !active):
			animationState.travel("Stay Open")
		else:
			animationState.travel("Stay Closed")

func _on_Area2D_body_entered(body):
	if body == global.persistPlayer:
		can_activate = false
		
func _on_Area2D_body_exited(body):
	if body == global.persistPlayer:
		can_activate = true
	
