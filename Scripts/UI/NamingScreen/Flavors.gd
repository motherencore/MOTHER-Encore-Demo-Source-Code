extends NinePatchRect


func _on_FlavorsArrow_moved(dir):
	match $FlavorsArrow.cursor_index:
		0:
			uiManager.set_menu_flavors("Plain")
		1:
			uiManager.set_menu_flavors("Mint")
		2:
			uiManager.set_menu_flavors("Strawberry")
		3:
			uiManager.set_menu_flavors("Banana")
		4:
			uiManager.set_menu_flavors("Peanut")
		5:
			uiManager.set_menu_flavors("Grape")
		6:
			uiManager.set_menu_flavors("Melon")
