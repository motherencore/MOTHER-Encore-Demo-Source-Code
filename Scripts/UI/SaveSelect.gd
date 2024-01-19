extends Control

onready var savesList = $CanvasLayer/Saves/SaveList
onready var menusCursor = $CanvasLayer/Cursor
var cursorTop = true
var saveFileNode = preload("res://Nodes/Ui/Saves/saveFile.tscn")
var files = []
var party = global.party
var index = 1
var maxFiles = 10
var savesOffset = 21
var active = false
var copying = false
var state = 0
var saveDict = {}
#state 0 for loading, 1 for saving

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"invalid": load("res://Audio/Sound effects/M3/bump.wav"),
}

func _ready():
	savesOffset = $CanvasLayer/Saves.rect_position.y
	$CanvasLayer/Cursor/cursor_menu/AnimationPlayer.play("idle")
	$CanvasLayer/SaveConfirmation.hide()
	$CanvasLayer/DeleteConfirmation.hide()
	$CanvasLayer/ButtonPrompts.hide()
	$CanvasLayer/Flavors.hide()
	$CanvasLayer/TextSpeed.hide()
	for i in maxFiles:
		var saveFile = saveFileNode.instance()
		saveFile.fileNum = i + 1
		savesList.add_child(saveFile)
		saveFile.connect("deactivate", self, "activate")
		saveFile.connect("show_copy", self, "set_copy_mode")
		saveFile.connect("show_delete", self, "show_delete_confirm")
		saveFile.connect("show_textSpeed", self, "show_textSpeed_setting")
		saveFile.connect("show_menuFlavor", self, "show_menuFlavor_setting")
		saveFile.connect("show_buttonPrompts", self, "show_buttonPrompts_setting")
		saveFile.set_type(state)
	if state == 1:
		$Background.hide()
		audioManager.set_audio_player_bus(0, "Filter")
	$CanvasLayer/Saves.rect_position.y = savesOffset - (index - 1) * 76
	savesOffset = $CanvasLayer/Saves.rect_position.y
	yield(get_tree().create_timer(0.5), "timeout")
	active = true

func _input(event):
	if active:
		if event.is_action_pressed("ui_accept"):
			var saveFile = savesList.get_child(index - 1)
			if copying:
				play_sfx("cursor2")
				if saveFile.saveData == null:
					overwrite_save(true)
					copying = false
				else:
					show_save_confirm()
			else:
				match state:
					0:
						if saveFile.saveData != null:
							play_sfx("cursor2")
							deactivate()
							saveFile.activate()
						else:
							play_sfx("invalid")
					1:
						play_sfx("cursor2")
						if saveFile.saveData == null:
							overwrite_save(false)
						else:
							show_save_confirm()
		
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
			if copying:
				play_sfx("back")
				copying = false
				$CanvasLayer/Saves/CopyCursor.hide()
			else:
				match state:
					0:
						active = false
						$Objects/Door.enter()
					1:
						audioManager.set_audio_player_bus(0, "Master")
						uiManager.remove_ui(self)
						uiManager.dialogueBox.next_dialog()
					
func _physics_process(delta):
	if active:
		if Input.is_action_just_pressed("ui_up") and index != 1:
			play_sfx("cursor1")
			index -= 1
			if !cursorTop:
				cursorTop = true
				$Tween.interpolate_property(menusCursor, "position:y",
					menusCursor.position.y, 0, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
			else:
				$Tween.interpolate_property($CanvasLayer/Saves, "rect_position:y",
					$CanvasLayer/Saves.rect_position.y, savesOffset + 76, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
				savesOffset += 76
				
		if Input.is_action_just_pressed("ui_down") and index != maxFiles:
			play_sfx("cursor1")
			index += 1
			if cursorTop:
				cursorTop = false
				$Tween.interpolate_property(menusCursor, "position:y",
					menusCursor.position.y, 76, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
			else:
				$Tween.interpolate_property($CanvasLayer/Saves, "rect_position:y",
					$CanvasLayer/Saves.rect_position.y, savesOffset - 76, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
				savesOffset -= 76

func activate():
	active = true
	$CanvasLayer/Cursor/cursor_menu/AnimationPlayer.play("idle")

func deactivate():
	active = false
	$CanvasLayer/Cursor/cursor_menu/AnimationPlayer.play("select")

func does_save_exist(num):
	var saveGame = File.new()
	if not saveGame.file_exists("user://saveFile" + var2str(num) + ".save"):
		return 

func play_sfx(sfx):
	var stream = soundEffects[sfx]
	audioManager.play_sfx(stream, "cursor")

func load_saveDict(num): #benichi code
	var saveGame = File.new()
	if not saveGame.file_exists("user://saveFile" + var2str(num) + ".save"):
		return 
	
	saveGame.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.READ,"ENCORE")
	
	saveDict = parse_json(saveGame.get_line())

func overwrite_save(fromDict = false):
	var saveFile = savesList.get_child(index - 1)
	if fromDict:
		global.save_from_dict(index, saveDict)
	else:
		global.save_game(index)
	saveFile.load_data(index)
	if saveFile.saveData != null:
		saveFile.set_info()
	globaldata.saveFile = index
	copying = false
	$CanvasLayer/Saves/CopyCursor.hide()

func erase_save():
	global.erase_save(index)
	var saveFile = savesList.get_child(index - 1)
	saveFile.saveData = null
	saveFile.get_node("NoData").show()
	saveFile.set_menu_flavor("Plain")

func show_save_confirm():
	$CanvasLayer/SaveConfirmation/saveArrow.on = true
	$CanvasLayer/SaveConfirmation.show()
	deactivate()

func show_delete_confirm():
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = true
	$CanvasLayer/DeleteConfirmation.show()
	deactivate()

func show_textSpeed_type():
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = true
	$CanvasLayer/DeleteConfirmation.show()
	deactivate()

func show_textSpeed_setting():
	load_saveDict(index)
	$CanvasLayer/TextSpeed/TextSpeedArrow.on = true
	$CanvasLayer/TextSpeed.show()
	deactivate()
	var textSpeedArrow = $CanvasLayer/TextSpeed/TextSpeedArrow
	match saveDict["textspeed"]:
		0.02:
			textSpeedArrow.set_cursor_from_index(0, false)
		0.035:
			textSpeedArrow.set_cursor_from_index(1, false)
		0.05:
			textSpeedArrow.set_cursor_from_index(2, false)
	$CanvasLayer/TextSpeed._on_TextSpeedArrow_moved(null)

func show_menuFlavor_setting():
	load_saveDict(index)
	$CanvasLayer/Flavors/FlavorsArrow.on = true
	$CanvasLayer/Flavors.show()
	deactivate()
	var flavorsArrow = $CanvasLayer/Flavors/FlavorsArrow
	match saveDict["menuflavor"]:
		"Plain":
			flavorsArrow.set_cursor_from_index(0, false)
		"Mint":
			flavorsArrow.set_cursor_from_index(1, false)
		"Strawberry":
			flavorsArrow.set_cursor_from_index(2, false)
		"Banana":
			flavorsArrow.set_cursor_from_index(3, false)
		"Peanut":
			flavorsArrow.set_cursor_from_index(4, false)
		"Grape":
			flavorsArrow.set_cursor_from_index(5, false)
		"Melon":
			flavorsArrow.set_cursor_from_index(6, false)
	$CanvasLayer/Flavors._on_FlavorsArrow_moved(null)

func show_buttonPrompts_setting():
	load_saveDict(index)
	$CanvasLayer/ButtonPrompts/ButtonPromptsArrow.on = true
	$CanvasLayer/ButtonPrompts.show()
	deactivate()
	var buttonPromptsArrow = $CanvasLayer/ButtonPrompts/ButtonPromptsArrow
	match saveDict["buttonprompts"]:
		"Both":
			buttonPromptsArrow.set_cursor_from_index(0, false)
		"Objects":
			buttonPromptsArrow.set_cursor_from_index(1, false)
		"NPCs":
			buttonPromptsArrow.set_cursor_from_index(2, false)
		"None":
			buttonPromptsArrow.set_cursor_from_index(3, false)
	$CanvasLayer/ButtonPrompts.quick_set()

func set_copy_mode():
	load_saveDict(index)
	copying = true
	activate()
	$CanvasLayer/Saves/CopyCursor.show()
	$CanvasLayer/Saves/CopyCursor.global_position = $CanvasLayer/Cursor.global_position

func _on_arrow_selected(cursor_index):
	if cursor_index == 0:
		overwrite_save(copying)
		play_sfx("cursor2")
	else:
		play_sfx("back")
	activate()
	$CanvasLayer/SaveConfirmation/saveArrow.on = false
	$CanvasLayer/SaveConfirmation.hide()

func _on_arrow_cancel():
	activate()
	$CanvasLayer/SaveConfirmation/saveArrow.on = false
	$CanvasLayer/SaveConfirmation.hide()


func _on_deleteArrow_selected(cursor_index):
	match cursor_index:
		0:
			play_sfx("cursor2")
			erase_save()
			activate()
		1:
			play_sfx("back")
			var saveFile = savesList.get_child(index - 1)
			saveFile.activate()
			saveFile.arrow.set_cursor_from_index(2, false)
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = false
	$CanvasLayer/DeleteConfirmation.hide()

func _on_deleteArrow_cancel():
	var saveFile = savesList.get_child(index - 1)
	saveFile.activate()
	saveFile.arrow.set_cursor_from_index(2, false)
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = false
	$CanvasLayer/DeleteConfirmation.hide()

func _on_TextSpeedArrow_selected(cursor_index):
	match cursor_index:
		0:
			saveDict["textspeed"] = 0.02
		1:
			saveDict["textspeed"]= 0.035
		2:
			saveDict["textspeed"] = 0.05
	hide_textSpeedOption()
	overwrite_save(true)

func _on_TextSpeedArrow_cancel():
	hide_textSpeedOption()

func hide_textSpeedOption():
	var saveFile = savesList.get_child(index - 1)
	saveFile.activate()
	saveFile.arrow.set_cursor_from_index(0, false)
	$CanvasLayer/TextSpeed/TextSpeedArrow.on = false
	$CanvasLayer/TextSpeed.hide()

func _on_FlavorsArrow_selected(cursor_index):
	match cursor_index:
		0:
			saveDict["menuflavor"] = "Plain"
		1:
			saveDict["menuflavor"] = "Mint"
		2:
			saveDict["menuflavor"] = "Strawberry"
		3:
			saveDict["menuflavor"] = "Banana"
		4:
			saveDict["menuflavor"] = "Peanut"
		5:
			saveDict["menuflavor"] = "Grape"
		6:
			saveDict["menuflavor"] = "Melon"
	overwrite_save(true)
	hide_menuFlavorsOption()

func _on_FlavorsArrow_cancel():
	hide_menuFlavorsOption()

func hide_menuFlavorsOption():
	var saveFile = savesList.get_child(index - 1)
	saveFile.activate()
	saveFile.arrow.set_cursor_from_index(1, false)
	$CanvasLayer/Flavors/FlavorsArrow.on = false
	$CanvasLayer/Flavors.hide()

func _on_ButtonPromptsArrow_selected(cursor_index):
	saveDict["buttonprompts"] = $CanvasLayer/ButtonPrompts/ButtonPromptsArrow.get_menu_item_at_index(cursor_index).text
	overwrite_save(true)
	hide_buttonPromptsOption()

func _on_ButtonPromptsArrow_cancel():
	hide_buttonPromptsOption()

func hide_buttonPromptsOption():
	var saveFile = savesList.get_child(index - 1)
	saveFile.activate()
	saveFile.arrow.set_cursor_from_index(2, false)
	$CanvasLayer/ButtonPrompts/ButtonPromptsArrow.on = false
	$CanvasLayer/ButtonPrompts.hide()
