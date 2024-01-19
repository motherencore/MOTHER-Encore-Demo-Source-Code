extends ColorRect

var oldColor

func _ready():
	oldColor = color
	uiManager.connect("menuFlavorUpdated", self, "setColor")
	connect("visibility_changed", self, "setColor")
	setColor()

func setColor():
	for i in ["1", "2", "3", "4", "5", "6", "7"]:
		if oldColor == uiManager.menuFlavorShader.get_shader_param("OLDCOLOR" + i):
			color = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR" + i)
