extends TextureProgress

var highlighted = false setget _set_highlighted

func _ready():
	uiManager.connect("menuFlavorUpdated", self, "_refresh_tint")
	_refresh_tint()

func _set_highlighted(value):
	highlighted = value
	_refresh()

func _on_visibility_changed():
	if !is_visible_in_tree():
		highlighted = false
	_refresh()

func _on_value_changed(value):
	_refresh()

func _refresh():
	var volRange = max_value - min_value
	$Thumb.rect_position.x = (value - 1) * (rect_size.x) / volRange

	$Thumb/ThumbRect.rect_size.y = value
	$Thumb/ThumbRect.rect_position.y = volRange - $Thumb/ThumbRect.rect_size.y

	$Thumb/ThumbLowerRect.visible = highlighted
	$LowerLine.visible = highlighted

func _refresh_tint():
	tint_under = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 3)
	tint_progress = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 5)
	$Thumb/ThumbRect.color = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 1)
	$Thumb/ThumbLowerRect.color = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 1)
	$LowerLine.color = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 3)

