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
var inputVector

var _amount_box_timer: SceneTreeTimer

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
		var phone_cards := InventoryManager.find_all_occurrences("PhoneCard")
		if phone_cards:
			_show_amount_box(uiManager.phone_units, true)
			audio.playing = true
			global.set_dialog(dialog)
			uiManager.open_dialogue_box()		
			InventoryManager.reduce_or_drop_item_obj(phone_cards[0])
		else:
			_show_amount_box(uiManager.cash, true)
			if globaldata.cash >= 5:
				audio.playing = true
				global.set_dialog(dialog)
				uiManager.open_dialogue_box()
				globaldata.cash -= 5
			else:
				global.set_dialog("Reusable/payphonenomoney")
				uiManager.open_dialogue_box()
	else:
		global.set_dialog(dialog)
		uiManager.open_dialogue_box()
		audio.playing = true

func _show_amount_box(box, update: bool):
	if _amount_box_timer:
		_amount_box_timer.disconnect("timeout", self, "_hide_amount_box")
	box.open()
	if update:
		yield(get_tree().create_timer(0.5),"timeout")
		box.update()
	_amount_box_timer = get_tree().create_timer(1)
	_amount_box_timer.connect("timeout", self, "_hide_amount_box", [box], CONNECT_ONESHOT)
	
func _hide_amount_box(box):
	uiManager.close_item(box)
	_amount_box_timer = null

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
