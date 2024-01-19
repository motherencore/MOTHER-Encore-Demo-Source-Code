tool

extends Sprite

export (Texture) var sprite setget set_texture 
export var sound = ""
export var end_sound = ""
export var key = "" #leave null if there's no need for a key item
export var blocked = false
export var remove_key = false
export var flag = ""
export var one_way = false

var unlocked = true
var touching = 0

func set_texture(tex):
	sprite = tex
	$Sprite.texture = sprite

func _ready():
	if !Engine.is_editor_hint():
		if key == "":
			unlock()
			$interact/ButtonPrompt.enabled = false
		else: 
			lock()
			$interact/ButtonPrompt.enabled = true
		if blocked:
			lock()
			$interact/ButtonPrompt.enabled = true
		if one_way:
			lock()
		if flag != "":
			if globaldata.flags.has(flag):
				unlocked = globaldata.flags[flag]
				$interact/ButtonPrompt.enabled = !globaldata.flags[flag]
		$AnimationPlayer.play("Normal")

func _on_Area2D_body_entered(body):
	if touching == 0 and $Timer.time_left == 0 and unlocked == true and $AnimationPlayer.current_animation == "Normal" and !one_way:
		open()
	if one_way and global.persistPlayer.paused:
		unlock()
		open()
	if blocked and global.persistPlayer.running and global.persistPlayer.direction.y == -1 and !unlocked:
		global.currentCamera.shake_camera(1, 0.2, Vector2(2,0))
		open()
		unlock()
		$interact/ButtonPrompt.hide_button()
		$interact/ButtonPrompt.enabled = false
		blocked = false
		if flag != "":
			if globaldata.flags.has(flag):
				globaldata.flags[flag] = true
	touching += 1

func _on_Area2D_body_exited(body):
	touching -= 1
	if global.persistPlayer.paused:
		$AnimationPlayer.play("Normal")
	elif touching == 0 and unlocked == true:
		$Timer.start()

func _on_Timer_timeout():
	if touching == 0:
		$AnimationPlayer.play("Normal")
		if end_sound != "" and !global.persistPlayer.paused:
			$AudioStreamPlayer.stream = load("Audio/Sound effects/" + end_sound)
			$AudioStreamPlayer.play()
		if one_way:
			lock()
			$AudioStreamPlayer.stream = load("Audio/Sound effects/" + end_sound)
			$AudioStreamPlayer.play()

func open():
	$AnimationPlayer.play("Action")
	if sound != "" and !global.persistPlayer.paused:
		if blocked and !unlocked:
			$AudioStreamPlayer.stream = load("res://Audio/Sound effects/bash.mp3")
		else:
			$AudioStreamPlayer.stream = load("Audio/Sound effects/" + sound)
		$AudioStreamPlayer.play()

func unlock():
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	unlocked = true

func lock():
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)
	unlocked = false

func interact():
	if !unlocked:
		if blocked:
			global.set_dialog("Reusable/doorblocked", null)
		elif InventoryManager.checkItemForAll(key):
			globaldata.flags[flag] = true
			open()
			unlock()
			$interact/ButtonPrompt.enabled = false
			if remove_key:
				InventoryManager.removeItem(key)
			var ItemName = InventoryManager.Load_item_data(key)["name"][globaldata.language]
			var ItemArt = InventoryManager.Load_item_data(key)["article"][globaldata.language]
			global.itemname = ItemName
			global.itemart = ItemArt
			global.set_dialog("Reusable/lockopened", null) 
		else:
			global.set_dialog("Reusable/locklocked", null)
		uiManager.open_dialogue_box()
		global.persistPlayer.pause()
