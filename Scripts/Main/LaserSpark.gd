extends AnimatedSprite

var start_pos

func _ready():
	start_pos = global_position

func _process(delta):
	if animation == "Spark":
		global_position = start_pos
		global_rotation = 0

func _on_Timer_timeout():
	queue_free()


func _on_AnimatedSprite_animation_finished():
	if animation == "Explosion":
		queue_free()
