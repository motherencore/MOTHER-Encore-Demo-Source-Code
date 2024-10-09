tool

extends Area2D

export (String) var dialog
export (String) var thoughts
export var appear_flag = ""
export var disappear_flag = ""
export (Array, PoolStringArray) var event_dialog
export var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": true #Make "y" true if you want the player to turn up/down to face npc
}
export (Vector2) var button_offset = Vector2.ZERO setget set_button_offset



func _ready():
	check_flags()

func check_flags():
	if appear_flag != "":
		if globaldata.flags.has(appear_flag):
			if globaldata.flags[appear_flag]:
				show()
			else:
				hide()
	if disappear_flag != "":
		if globaldata.flags.has(disappear_flag):
			if globaldata.flags[disappear_flag]:
				hide()
			else:
				show()
	if !visible:
		queue_free()

func set_button_offset(offset):
	button_offset = offset
	$ButtonPrompt.offset = button_offset

func interact():
	set_dialog()
	global.set_dialog(dialog, null)
	uiManager.open_dialogue_box()

func telepathy():
	global.set_dialog(thoughts, null)
	uiManager.set_telepathy_effect(true)
	uiManager.open_dialogue_box()

func set_dialog():
	for flags in event_dialog:
		var flag = flags[0]
		var newdialog = flags[1]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					dialog = newdialog

func show_button():
	$ButtonPrompt.show_button()

func hide_button():
	$ButtonPrompt.hide_button()
