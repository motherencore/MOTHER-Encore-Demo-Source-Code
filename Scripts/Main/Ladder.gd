extends Area2D




func _on_Ladder_body_entered(body):
	if body.has_method("ladder"):
		body.ladder()


func _on_Ladder_body_exited(body):
	if body.has_method("unladder"):
		body.unladder()
