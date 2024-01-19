extends CanvasLayer

func open():
	update()
	if $Box.rect_position.y < 6:
		$AnimationPlayer.play("Open")

func update():
	$Box/Money.text = var2str(globaldata.cash)

func close():
	if $Box.rect_position.y > -27:
		$AnimationPlayer.play("Close")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Close":
		uiManager.remove_ui(self)
