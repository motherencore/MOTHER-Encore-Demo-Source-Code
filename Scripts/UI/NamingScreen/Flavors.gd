extends NinePatchRect


func _on_FlavorsArrow_moved(dir):
	uiManager.set_menu_flavors(globaldata.FLAVORS[$FlavorsArrow.cursor_index])
