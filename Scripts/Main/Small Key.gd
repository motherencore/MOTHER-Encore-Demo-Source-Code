extends "res://Scripts/Main/FlaggableObject.gd"


func _ready():
	if _get_flag_status():
		queue_free()

func _on_Area2D_body_entered(body):
	if body == global.persistPlayer and !$AudioStreamPlayer.playing:
		if uiManager.try_alter_key_count(+1):
			_set_flag_status()
			uiManager.update_key_indicator()
		$AudioStreamPlayer.playing = true
		self.visible = false
		$Area2D/CollisionShape2D.set_deferred("disabled", true)

func _on_AudioStreamPlayer_finished():
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
