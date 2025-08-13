class_name SaveSelect

extends Control

enum Type { LOAD, SAVE }

var SaveFile = preload("res://Nodes/Ui/Saves/saveFile.tscn")

onready var _saves_list = $CanvasLayer/Body/Saves/SaveList
onready var _menus_cursor = $CanvasLayer/Body/Cursor
var _cursor_top := true
var _max_files := 30 if OS.is_debug_build() else 10
var _index = clamp(globaldata.saveFile, 1, _max_files)
var _saves_offset := 21
var _save_file_height := 76
var _active := false
var _copying := false
var _type: int = Type.LOAD
var _is_embed := false
var _save_dict := {}

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"invalid": load("res://Audio/Sound effects/M3/bump.wav"),
}

func init(type, index, embed = null):
	_type = type
	_index = index
	_is_embed = embed if (embed != null) else (_type == Type.SAVE)
	

func _ready():
	_saves_offset = $CanvasLayer/Body/Saves.rect_position.y
	$CanvasLayer/Body/Cursor/cursor_menu/AnimationPlayer.play("idle")
	$CanvasLayer/SaveConfirmation.hide()
	$CanvasLayer/DeleteConfirmation.hide()
	$CanvasLayer/ButtonPrompts.hide()
	$CanvasLayer/Flavors.hide()
	$CanvasLayer/TextSpeed.hide()
	for i in _max_files:
		var saveFile = SaveFile.instance()
		saveFile.init(_is_embed, i + 1)
		_saves_list.add_child(saveFile)
		saveFile.connect("deactivate", self, "activate")
		saveFile.connect("show_copy", self, "set_copy_mode")
		saveFile.connect("show_delete", self, "show_delete_confirm")
		saveFile.connect("show_textSpeed", self, "show_textSpeed_setting")
		saveFile.connect("show_menuFlavor", self, "show_menuFlavor_setting")
		saveFile.connect("show_buttonPrompts", self, "show_buttonPrompts_setting")
	if _is_embed:
		$Background.hide()
		audioManager.music_muffle(0, 1)
		$CanvasLayer/Body.margin_left = 32
		$CanvasLayer/Body.margin_right = -32
	$CanvasLayer/Body/Saves.rect_position.y = _saves_offset - (_index - 1) * 76
	_saves_offset = $CanvasLayer/Body/Saves.rect_position.y
	yield(get_tree().create_timer(0.5), "timeout")
	$CanvasLayer/Body/Cursor.show()
	_active = true

func _input(event):
	if _active:
		if event.is_action_pressed("ui_accept"):
			var saveFile = _saves_list.get_child(_index - 1)
			if _copying:
				play_sfx("cursor2")
				if !saveFile.has_data():
					overwrite_save(true)
					_copying = false
				else:
					show_save_confirm()
			else:
				match _type:
					Type.LOAD:
						if saveFile.has_data():
							if _is_embed:
								yield(saveFile.load_game(), "completed")
								_finish()
							else:
								play_sfx("cursor2")
								deactivate()
								saveFile.activate(true)
						else:
							play_sfx("invalid")
					Type.SAVE:
						play_sfx("cursor2")
						if !saveFile.has_data():
							overwrite_save(false)
						else:
							show_save_confirm()
		
		if event.is_action_pressed("ui_cancel"):
			if _copying:
				play_sfx("back")
				_copying = false
				$CanvasLayer/Body/Saves/CopyCursor.hide()
			else:
				Input.action_release("ui_cancel")
				_finish()

func _physics_process(delta):
	if _active:
		
		var direction = controlsManager.get_controls_vector(true).y
		
		if direction < 0 and _index > 1:
			play_sfx("cursor1")
			_index -= 1
			if !_cursor_top:
				_cursor_top = true
				$Tween.interpolate_property(_menus_cursor, "rect_position:y",
					_menus_cursor.rect_position.y, 0, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
			else:
				var new_saves_offset = _saves_offset + _save_file_height
				$Tween.interpolate_property($CanvasLayer/Body/Saves, "rect_position:y",
					$CanvasLayer/Body/Saves.rect_position.y, new_saves_offset, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
				_saves_offset = new_saves_offset
				
		elif direction < 0 and _index == 1:
			play_sfx("cursor1")
			_index = _max_files
			_cursor_top = false
			$Tween.interpolate_property(_menus_cursor, "rect_position:y",
				_menus_cursor.rect_position.y, _save_file_height, 0.2, 
				Tween.TRANS_QUART, Tween.EASE_OUT)
			var new_saves_offset = _saves_offset - (_save_file_height * (_max_files - 2))
			$Tween.interpolate_property($CanvasLayer/Body/Saves, "rect_position:y",
				$CanvasLayer/Body/Saves.rect_position.y, new_saves_offset, 0.2, 
				Tween.TRANS_QUART, Tween.EASE_OUT)
			_saves_offset = new_saves_offset
			$Tween.start()
			
		elif direction > 0 and _index < _max_files:
			play_sfx("cursor1")
			_index += 1
			if _cursor_top:
				_cursor_top = false
				$Tween.interpolate_property(_menus_cursor, "rect_position:y",
					_menus_cursor.rect_position.y, _save_file_height, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
			else:
				var new_saves_offset = _saves_offset - _save_file_height
				$Tween.interpolate_property($CanvasLayer/Body/Saves, "rect_position:y",
					$CanvasLayer/Body/Saves.rect_position.y, new_saves_offset, 0.2, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
				_saves_offset = new_saves_offset

		elif direction > 0 and _index == _max_files:
			play_sfx("cursor1")
			$Tween.interpolate_property(_menus_cursor, "rect_position:y",
				_menus_cursor.rect_position.y, 0, 0.2, 
				Tween.TRANS_QUART, Tween.EASE_OUT)
			var new_saves_offset
			if _cursor_top:
				new_saves_offset = _saves_offset + (_save_file_height * (_max_files - 1))
			else:
				new_saves_offset = _saves_offset + (_save_file_height * (_max_files - 2))
			$Tween.interpolate_property($CanvasLayer/Body/Saves, "rect_position:y",
				$CanvasLayer/Body/Saves.rect_position.y, new_saves_offset, 0.2, 
				Tween.TRANS_QUART, Tween.EASE_OUT)
			_index = 1
			_cursor_top = true
			_saves_offset = new_saves_offset
			$Tween.start()

func activate():
	_active = true
	$CanvasLayer/Body/Cursor/cursor_menu/AnimationPlayer.play("idle")

func deactivate():
	_active = false
	$CanvasLayer/Body/Cursor/cursor_menu/AnimationPlayer.play("select")

func play_sfx(sfx):
	var stream = soundEffects[sfx]
	audioManager.play_sfx(stream, "cursor")

func _load_save_dict(num):
	var dict = global.load_to_dict(num)
	if dict != null:
		_save_dict = dict

func _finish():
	if _is_embed:
		uiManager.remove_ui(self)
	else:
		_active = false
		$Objects/Door.enter()

func close():
	audioManager.music_muffle(0, 0)
	if is_instance_valid(uiManager.dialogueBox):
		uiManager.dialogueBox.next_phrase()
	else:
		global.persistPlayer.unpause()
	queue_free()

func overwrite_save(fromDict = false):
	var saveFile = _saves_list.get_child(_index - 1)
	if fromDict:
		global.save_from_dict(_index, _save_dict)
	else:
		global.save_game(_index)
	saveFile.load_data(_index)
	globaldata.saveFile = _index
	_copying = false
	global.save_settings()
	$CanvasLayer/Body/Saves/CopyCursor.hide()

func erase_save():
	global.erase_save(_index)
	var saveFile = _saves_list.get_child(_index - 1)
	saveFile.clear_data()

func show_save_confirm():
	yield(get_tree(), "idle_frame")
	$CanvasLayer/SaveConfirmation/saveArrow.on = true
	$CanvasLayer/SaveConfirmation.show()
	deactivate()

func show_delete_confirm():
	yield(get_tree(), "idle_frame")
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = true
	$CanvasLayer/DeleteConfirmation.show()
	deactivate()

func show_textSpeed_type():
	yield(get_tree(), "idle_frame")
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = true
	$CanvasLayer/DeleteConfirmation.show()
	deactivate()

func show_textSpeed_setting():
	yield(get_tree(), "idle_frame")
	_load_save_dict(_index)
	$CanvasLayer/TextSpeed/TextSpeedArrow.on = true
	$CanvasLayer/TextSpeed.show()
	deactivate()
	var textSpeedArrow = $CanvasLayer/TextSpeed/TextSpeedArrow
	var text_speed_index = globaldata.TEXT_SPEEDS.find(_save_dict["textspeed"])
	textSpeedArrow.set_cursor_from_index(text_speed_index, false)
	$CanvasLayer/TextSpeed._on_TextSpeedArrow_moved(null)

func show_menuFlavor_setting():
	_load_save_dict(_index)
	$CanvasLayer/Flavors/FlavorsArrow.on = true
	$CanvasLayer/Flavors.show()
	deactivate()
	var flavorsArrow = $CanvasLayer/Flavors/FlavorsArrow
	var flavor_index = globaldata.FLAVORS.find(_save_dict["menuflavor"])
	flavorsArrow.set_cursor_from_index(flavor_index, false)
	$CanvasLayer/Flavors._on_FlavorsArrow_moved(null)

func show_buttonPrompts_setting():
	_load_save_dict(_index)
	$CanvasLayer/ButtonPrompts/ButtonPromptsArrow.on = true
	$CanvasLayer/ButtonPrompts.show()
	deactivate()
	var buttonPromptsArrow = $CanvasLayer/ButtonPrompts/ButtonPromptsArrow
	match _save_dict["buttonprompts"]:
		"Both":
			buttonPromptsArrow.set_cursor_from_index(0, false)
		"Objects":
			buttonPromptsArrow.set_cursor_from_index(1, false)
		"NPCs":
			buttonPromptsArrow.set_cursor_from_index(2, false)
		"None":
			buttonPromptsArrow.set_cursor_from_index(3, false)
	$CanvasLayer/ButtonPrompts.refresh(true)

func set_copy_mode():
	_load_save_dict(_index)
	_copying = true
	activate()
	$CanvasLayer/Body/Saves/CopyCursor.show()
	$CanvasLayer/Body/Saves/CopyCursor.rect_global_position = $CanvasLayer/Body/Cursor.rect_global_position

func _on_arrow_selected(cursor_index):
	if cursor_index == 0:
		overwrite_save(_copying)
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
			var saveFile = _saves_list.get_child(_index - 1)
			saveFile.activate()
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = false
	$CanvasLayer/DeleteConfirmation.hide()

func _on_deleteArrow_cancel():
	var saveFile = _saves_list.get_child(_index - 1)
	saveFile.activate()
	$CanvasLayer/DeleteConfirmation/deleteArrow.on = false
	$CanvasLayer/DeleteConfirmation.hide()

func _on_TextSpeedArrow_selected(cursor_index):
	_save_dict["textspeed"] = globaldata.TEXT_SPEEDS[cursor_index]
	hide_textSpeedOption()
	overwrite_save(true)

func _on_TextSpeedArrow_cancel():
	hide_textSpeedOption()

func hide_textSpeedOption():
	var saveFile = _saves_list.get_child(_index - 1)
	saveFile.activate()
	$CanvasLayer/TextSpeed/TextSpeedArrow.on = false
	$CanvasLayer/TextSpeed.hide()

func _on_FlavorsArrow_selected(cursor_index):
	_save_dict["menuflavor"] = globaldata.FLAVORS[cursor_index]
	overwrite_save(true)
	hide_menuFlavorsOption()

func _on_FlavorsArrow_cancel():
	hide_menuFlavorsOption()

func hide_menuFlavorsOption():
	var saveFile = _saves_list.get_child(_index - 1)
	saveFile.activate()
	$CanvasLayer/Flavors/FlavorsArrow.on = false
	$CanvasLayer/Flavors.hide()

func _on_ButtonPromptsArrow_selected(cursor_index):
	match cursor_index:
		0:
			_save_dict["buttonprompts"] = "Both"
		1:
			_save_dict["buttonprompts"] = "Objects"
		2:
			_save_dict["buttonprompts"] = "NPCs"
		3:
			_save_dict["buttonprompts"] = "None"
	overwrite_save(true)
	hide_buttonPromptsOption()

func _on_ButtonPromptsArrow_cancel():
	hide_buttonPromptsOption()

func hide_buttonPromptsOption():
	var saveFile = _saves_list.get_child(_index - 1)
	saveFile.activate()
	$CanvasLayer/ButtonPrompts/ButtonPromptsArrow.on = false
	$CanvasLayer/ButtonPrompts.hide()
