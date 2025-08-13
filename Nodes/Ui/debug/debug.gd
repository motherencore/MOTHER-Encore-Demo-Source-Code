extends Control


func _input(event):
	if Input.is_action_just_pressed("ui_backtick"):
		# FRENCHTEAM Fixed debug menu immediately reopening when closed
		yield(get_tree(), "idle_frame")
		uiManager.remove_ui(self)
