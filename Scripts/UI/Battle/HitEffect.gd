extends Control

func _on_AnimationPlayer_animation_started(_anim_name):
	if (randi()%2+0) == 1:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
	if (randi()%2+0) == 1:
		$Sprite.flip_v = true
	else:
		$Sprite.flip_v = false
	$Sprite.offset = Vector2(rand_range(-10, 10), rand_range(-10, 10))
