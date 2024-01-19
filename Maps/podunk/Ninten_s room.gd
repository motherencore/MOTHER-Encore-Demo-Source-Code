extends AreaRoom

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "cutscene":
		uiManager.start_battle()
