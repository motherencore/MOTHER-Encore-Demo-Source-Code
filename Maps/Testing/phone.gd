extends Sprite


export (String) var dialog
export (bool) var payphone
export var appear_flag = ""
export var disappear_flag = ""
export var save_location = ""
export (Array, PoolStringArray) var event_dialog
var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": true #Make "y" true if you want the player to turn up/down to face npc
}
var player = null
var talking = false
var pause
var inputVector


onready var animationPlayer = $AnimationPlayer
onready var audio = $AudioStreamPlayer2D

func _ring():
	if animationPlayer.current_animation != "Ring":
		audio.stream = ResourceLoader.load("res://Audio/Sound effects/phonering.wav")
		animationPlayer.play("Ring")

func interact():
	audio.stream = ResourceLoader.load("res://Audio/Sound effects/phonehangup.wav")
	animationPlayer.play("Idle")
	global.phoneLocation = save_location
	set_dialog()
	if payphone:
		uiManager.cash.open()
		if globaldata.cash >= 5:
			audio.playing = true
			global.set_dialog(dialog, null)
			uiManager.open_dialogue_box()
			yield(get_tree().create_timer(1),"timeout")
			globaldata.cash -= 5
			uiManager.cash.update()
			yield(get_tree().create_timer(1),"timeout")
			uiManager.close_item(uiManager.cash)
		else:
			global.set_dialog("Reusable/payphonenomoney", null)
			uiManager.open_dialogue_box()
			yield(get_tree().create_timer(1),"timeout")
			uiManager.close_item(uiManager.cash)
	else:
		global.set_dialog(dialog, null)
		uiManager.open_dialogue_box()
		audio.playing = true

func set_dialog():
	for flags in event_dialog:
		var flag = flags[0]
		var newdialog = flags[1]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					dialog = newdialog

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
	if !visible:
		queue_free()

func duplicate_sprite():
	return $main.duplicate()
