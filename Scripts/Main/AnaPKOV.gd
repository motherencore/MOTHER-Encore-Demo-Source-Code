extends Area2D

func _ready():
	$Sprite.texture = load("res://Graphics/VFX/AnaPKOV" + var2str(global.persistPlayer.PK_type) + ".png")
	$RayCast2D.cast_to = global.persistPlayer.get_node("CollisionShape2D").global_position - global_position
	
	yield ($Timer,"timeout")
	if $RayCast2D.get_collider() != null:
		if $RayCast2D.get_collider().get_class() != "KinematicBody2D":
			queue_free()
		else:
			$AnimationPlayer.play("Grow")
			$AudioStreamPlayer.play()
	else:
		$AnimationPlayer.play("Grow")
		$AudioStreamPlayer.play()
	
func _on_AnimationPlayer_animation_finished(_anim_name):
	queue_free()

