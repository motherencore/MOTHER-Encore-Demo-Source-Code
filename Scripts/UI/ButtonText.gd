extends Label

export (String, "ui_accept", "ui_cancel", "ui_toggle", "ui_select", "ui_focus_prev", "ui_focus_next", "ui_ctrl") var key = "ui_accept"
export var hintColor = true

func _ready():
	set_key_name(key)

func set_key_name(keyname):
	key = keyname
	text = globaldata.get_key_name(keyname)
	if hintColor:
		modulate = Color(globaldata.dialogHintColor)

func _on_ButtonText_visibility_changed():
	set_key_name(key)
