extends NinePatchRect

signal back
signal exit

var active = false
var doingAction = false

func show_dialogBox(dialog, character = null, action = ""):
	active = true
	if "User" in dialog and character != null:
		dialog = dialog.replace("User", globaldata[character]["nickname"])
	$TextLabel.text = dialog
	$AnimationPlayer.play("Open")

func _input(event):
	if !doingAction and active and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle")):
		active = false
		Input.action_release("ui_accept")
		Input.action_release("ui_cancel")
		Input.action_release("ui_toggle")
		$AnimationPlayer.play("Close")
		emit_signal("back")
