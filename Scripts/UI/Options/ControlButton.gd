extends Panel

func _ready():
	focus_mode = FOCUS_CLICK
	uiManager.connect("menuFlavorUpdated", self, "_update_color")
	connect("visibility_changed", self, "_update_color")
	connect("focus_entered", self, "_update_color")
	connect("focus_exited", self, "_update_color")
	_update_color()

func _update_color():
	if has_focus():
		self_modulate = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR5")
	else:
		self_modulate = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR3")
