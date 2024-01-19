extends CanvasLayer

signal back
signal closeMenu

onready var topMenu = $OptionsMenu/NinePatchRect/VBoxContainer
onready var fileSettingsMenu = $OptionsMenu/NinePatchRect/FileSettings
onready var settingsMenu = $OptionsMenu/NinePatchRect/Settings
onready var arrow = $OptionsMenu/NinePatchRect/arrow


func _ready():
	$OptionsMenu.hide()

func Show_options():
	$OptionsMenu.show()
	arrow.on = true

func _on_arrow_selected(cursor_index):
	if arrow.menu_parent == topMenu:
		arrow.on = false
		match cursor_index:
			0:
				fileSettingsMenu.show()
				arrow.change_parent($OptionsMenu/NinePatchRect/FileSettings/VBoxContainer)
				arrow.set_cursor_from_index(0, true)
			1:
				settingsMenu.show()
				arrow.change_parent($OptionsMenu/NinePatchRect/Settings/VBoxContainer)
				arrow.set_cursor_from_index(0, true)
			2:
				$OptionsMenu/Door.enter()
				$OptionsMenu.hide()
				global.stop_playtime()
				emit_signal("closeMenu")
				
			3:
				global.save_settings()
				get_tree().quit()
		


func _on_arrow_cancel():
	if arrow.menu_parent != topMenu:
		fileSettingsMenu.hide()
		settingsMenu.hide()
		arrow.change_parent(topMenu)
		arrow.play_sfx('back')
	else:
		arrow.on = false
		Input.action_release("ui_cancel")
		Input.action_release("ui_toggle")
		emit_signal("back")
		$OptionsMenu.hide()


func _on_Door_done():
	uiManager.close_commands_menu(false)
