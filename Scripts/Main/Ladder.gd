extends Area2D


func _on_Ladder_body_entered(body):
	if body.has_method("ladder"):
		body.ladder()
		body.global_position.x = global_position.x


func _on_Ladder_body_exited(body):
	if body.has_method("unladder"):
		body.unladder()
