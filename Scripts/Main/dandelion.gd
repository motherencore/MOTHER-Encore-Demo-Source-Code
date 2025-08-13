extends Area2D

func _on_Dandelion_body_entered(body):
	if body == global.persistPlayer and $Sprite.frame == 0:
		$Sprite.frame = 1
		$CPUParticles2D.gravity = global.persistPlayer.direction * 5
		$CPUParticles2D.emitting = true
