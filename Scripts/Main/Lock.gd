extends "res://Scripts/Main/FlaggableObject.gd"

var opened = false 

func _ready():
	if _get_flag_status():
		opened = true
		$Sprite.frame = 11
		open()

func interact(): #Opens the door if you have a key. Otherwise it opens a dialog box that says you can't open it.
	if opened == false:
		if uiManager.try_alter_key_count(-1):
			$AnimationPlayer.play("Open")
			opened = true
			_set_flag_status()
			uiManager.update_key_indicator()
		else:
			global.set_dialog("Reusable/locklocked")
			uiManager.open_dialogue_box()
			global.persistPlayer.pause()

func open():
	$StaticBody2D/CollisionShape2D.disabled = true
