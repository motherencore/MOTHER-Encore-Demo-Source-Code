extends Area2D

export (String) var dialog
export var appear_flag = ""
export var disappear_flag = ""

func _ready():
	set_process(false)

func _process(delta):
	if !global.cutscene and !global.inBattle and !uiManager.commandsMenuActive:
		if check_flags():
			start_cutscene()
			set_process(false)
		else:
			set_process(false)

func _on_Cutscene_Area_body_entered(body):
	if body == global.persistPlayer:
		check_start()

func _on_Cutscene_Area_body_exited(body):
	if body == global.persistPlayer and !global.inBattle:
		set_process(false)

func check_start():
	if dialog != "":
		if check_flags():
			print("yippie")
			set_process(true)
		else:
			#start checking when player becomes unpaused again
			set_process(true)

func start_cutscene():
	global.persistPlayer.pause()
	global.set_dialog(dialog, null) 
	uiManager.open_dialogue_box()

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
