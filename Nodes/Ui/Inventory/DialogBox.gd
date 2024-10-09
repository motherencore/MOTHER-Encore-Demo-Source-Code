extends NinePatchRect

signal back
signal exit

var active = false
var doingAction = false

func show_dialogBox(dialog, character = null, action = ""):
	active = true
	# LOCALIZATION Code change: moved substitution of "User" to separate method
	# Which also does more substitutions
	if character:
		global.itemUser = globaldata[character]
	$TextLabel.text = globaldata.replaceText(dialog)
	$AnimationPlayer.play("Open")

func _input(event):
	if !doingAction and active and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		active = false
		Input.action_release("ui_accept")
		Input.action_release("ui_cancel")
		$AnimationPlayer.play("Close")
		emit_signal("back")
