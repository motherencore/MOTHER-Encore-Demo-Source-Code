extends Area2D

export var stepping_sound : NodePath

onready var steppingSound = get_node_or_null(stepping_sound)

func _on_Area2D_body_entered(body):
	if body.has_method("damage"):
		if global.persistPlayer.paused == false:
			body.set_ripple(true)
			body.damage(4, 2, Vector2.ZERO, globaldata.ailments.Poisoned)
			steppingSound._on_Stepping_Sounds_body_entered(body)

func _on_Poison_body_exited(body):
	if body.has_method("damage"):
		body.undamage()
		body.set_ripple(false)
		steppingSound._on_Stepping_Sounds_body_exited(body)
