extends CanvasLayer

func open():
	update()
	$HBoxContainer.show()
	$Tween.stop_all()
	$Tween.interpolate_property($HBoxContainer, "rect_position:x",
		$HBoxContainer.rect_position.x, 280, 0.2, 
		Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func close():
	$Tween.interpolate_property($HBoxContainer, "rect_position:x",
		$HBoxContainer.rect_position.x, 320, 0.2, 
		Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()
	yield($Tween,"tween_completed")
	$HBoxContainer.hide()

func update():
	$HBoxContainer/Money.text = "x " + str(uiManager.check_keys(global.currentScene.name))
	if $HBoxContainer.rect_position.x == 280:
		$Tween.interpolate_property($HBoxContainer, "rect_position:y",
			$HBoxContainer.rect_position.y - 4, $HBoxContainer.rect_position.y + 3, 0.1, 
			Tween.TRANS_SINE, Tween.EASE_OUT)
		$Tween.interpolate_property($HBoxContainer, "rect_position:y",
			$HBoxContainer.rect_position.y + 3, $HBoxContainer.rect_position.y, 0.2, 
			Tween.TRANS_SINE, Tween.EASE_OUT, 0.1)
		$Tween.start()
