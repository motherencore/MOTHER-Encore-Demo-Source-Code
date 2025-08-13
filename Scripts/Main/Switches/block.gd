extends ControlledTwoStatesObject

func _init():
	_state_anim_player = "AnimationPlayer"
	_is_synced_with_room = true

func set_initially_on(value: bool):
	_initially_on = value

func _ready():
	if _initially_on:
		$Sprite.texture = load("res://Graphics/Objects/Block Red.png")
	else:
		$Sprite.texture = load("res://Graphics/Objects/Block Blue.png")


func _on_Area2D_body_entered(body):
	pass # Replace with function body.


func _on_Area2D_body_exited(body):
	pass # Replace with function body.
