extends Area2D

export (String) var dialog
export (Array, PoolStringArray) var event_dialog
export var appear_flag = ""
export var disappear_flag = ""
var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": false #Make "y" true if you want the player to turn up/down to face npc
}

func _ready():
	set_process(false)

func _process(delta):
	if !global.cutscene and !global.inBattle and !uiManager.commandsMenuActive:
		if check_flags():
			start_cutscene()
			set_process(false)
		else:
			set_process(false)

func set_dialog():
	for flags in event_dialog:
		var flag = flags[0]
		var newdialog = flags[1]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					dialog = newdialog

func check_flags():
	var flagOn = true
	if appear_flag != "":
		if globaldata.flags.has(appear_flag):
			if globaldata.flags[appear_flag] == true:
				flagOn = true
			else:
				flagOn = false
	if disappear_flag != "":
		if globaldata.flags.has(disappear_flag):
			if globaldata.flags[disappear_flag] == true:
				flagOn = false
	return flagOn

func start_cutscene():
	set_dialog()
	global.persistPlayer.turn_to(self, true)
	global.persistPlayer.pause()
	global.cutscene = true
	uiManager.toggle_black_bars(true)
	$AudioStreamPlayer.play()
	yield(get_tree().create_timer(1),"timeout")
	global.set_dialog(dialog) 
	uiManager.open_dialogue_box()
	global.cutscene = false

func _on_Door_NPC_body_entered(body):
	if body == global.persistPlayer:
		if dialog != "":
			if check_flags():
				#if !global.cutscene and !global.inBattle:
				print("yippie")
				set_process(true)
			else:
				#start checking when player becomes unpaused again
				set_process(true)
