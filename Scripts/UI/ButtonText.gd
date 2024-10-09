extends Label

export (String, "ui_accept", "ui_cancel", "ui_toggle", "ui_select", "ui_focus_prev", "ui_focus_next", "ui_scope") var key = "ui_accept"
export var hintColor = true

func _ready():
	set_key_name(key)
	global.connect("inputs_changed", self, "_on_inputs_changed")
	global.connect("locale_changed", self, "_on_inputs_changed")

func set_key_name(keyname):
	key = keyname
	text = globaldata.get_key_name(keyname)
	if hintColor:
		modulate = Color(globaldata.dialogHintColor)

func _on_ButtonText_visibility_changed():
	set_key_name(key)

func _on_inputs_changed():
	set_key_name(key)
