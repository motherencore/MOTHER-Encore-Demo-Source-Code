extends Sprite

var opened = false 
export var flag = "" 

func _ready():
	if flag != null or flag != "":
		if globaldata.flags.has(flag):
			if globaldata.flags[flag] == true:
				opened = true
				$Sprite.frame = 11
				open()

func interact(): #Opens the door if you have a key. Otherwise it opens a dialog box that says you can't open it.
	if opened == false:
		if uiManager.check_keys(global.currentScene.name) > 0:
			globaldata.keys[global.currentScene.name] -= 1
			$AnimationPlayer.play("Open")
			opened = true
			globaldata.flags[flag] = true
			uiManager.key.update()
			if uiManager.check_keys(global.currentScene.name) == 0:
				uiManager.key.close()
		else:
			global.set_dialog("Reusable/locklocked", null)
			uiManager.open_dialogue_box()
			global.persistPlayer.pause()

func open():
	$StaticBody2D/CollisionShape2D.disabled = true
