extends Area2D

signal done

export var targetX = 0
export var targetY = 0
export var dir = Vector2.ZERO
export var sound = ""
export var end_sound = ""
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_in_anim = "Fade"
export (String, "Fade", "Circle", "Circle Focus", "Circle Pop", "Cut") var transit_out_anim = "Fade"
export var transit_in_color = Color.black
export var transit_out_color = Color.black
export var fade_in_speed = 1.0
export var fade_out_speed = 1.0
export var fadeout_music_on_scene_change = true
export var fadeout_music_length = 0.9
export var targetScene = ""
export var set_respawn = false
export var set_crumbs = false
export var unpause_player = true
export (String) var flag_set = ""
export (bool) var set_flag_state = true

var targetCutoff = 0
var currentState = 0
var player = null
var sameScene = false
var activeDoor = true
var fade = null
var wasRunning = false

onready var newpos = $Position2D


func _ready():
	set_process(false)

func _on_Door_body_entered(body):
	if body == global.persistPlayer:
		wasRunning = global.persistPlayer.tap_run
		global.persistPlayer.pause()
		yield(get_tree(), "idle_frame")
		enter(body)

func _process(_delta):
	if currentState != 0:
		match currentState:
			1:
				if fade.colorRect.material.get_shader_param("cut") == targetCutoff:
					currentState = 2
			2:
				global.persistPlayer.camera.current = true
				global.persistPlayer.visible = true
				fade.colorRect.material.set_shader_param("cut", 0)
				if !sameScene:
					_change_scene()
					#_move_player()
					
				else :
					_goto()
				if dir != Vector2.ZERO:
					player.animationTree.active = true
					player.direction = dir
					player.inputVector = dir
					player.blend_position(dir)
					player.animationState.travel("Idle")
					
				
				currentState = 3
			3:
				create_party()
				fade_out()
				if end_sound != null and end_sound != "":
					$AudioStreamPlayer.stream = load("res://Audio/Sound effects/" + end_sound)
					$AudioStreamPlayer.play()
				currentState = 4
			4:
				if fade.colorRect.material.get_shader_param("cut") == targetCutoff:
					set_process(false)
					if !global.cutscene and unpause_player:
						if wasRunning:
							wasRunning = false
							player.running = true
							player.tap_run = true
						if dir != Vector2.ZERO:
							player.direction = dir
							player.inputVector = dir
							player.blend_position(dir)
							player.animationState.travel("Idle")
						if set_crumbs and InventoryManager.crumbTrail.scene != "":
							InventoryManager.setCrumbs(global.currentScene.filename, player.global_position)
						player.unpause()
					if !sameScene:
						global.remove_persistent(self)
						queue_free()
					else:
						activeDoor = true
						currentState = 0
					if set_respawn:
						global.set_respawn()
					emit_signal("done")

func _change_scene():
	global.goto_scene("res://Maps/" + targetScene + ".tscn", Vector2(targetX, targetY - 7))
	var cam = global.persistPlayer.get_node("Camera2D")
	#cam.limit_top = -10000000
	#cam.limit_left = -10000000
	#cam.limit_right = 10000000
	#cam.limit_bottom = 10000000
	cam.smoothing_enabled = false
	uiManager.onScreenEnemies.clear()

func _move_player():
	player.global_position.x = targetX
	player.global_position.y = targetY - 7
	global.enteringDoorScene = false
	yield(get_tree(), "idle_frame")
	

func _goto():
	var cam = global.persistPlayer.get_node("Camera2D")
	player.global_position.x = newpos.global_position.x
	player.global_position.y = newpos.global_position.y - 7
	
	#cam.limit_top = -10000000
	#cam.limit_left = -10000000
	#cam.limit_right = 10000000
	#cam.limit_bottom = 10000000
	#cam.smoothing_enabled = false

func create_party():
	if global.partySize > 1:
		for i in global.partySpace.size():
			global.partySpace.push_front(player.position)
			global.partySpace.pop_back()
		for i in range(1, global.partyObjects.size()):
			global.partyObjects[i].position = player.position
			global.partyObjects[i].initiate()
			global.partyObjects[i].disappear()

func fade_in():
	targetCutoff = 0
	fade.fade_in(transit_in_anim, transit_in_color, fade_in_speed)

func fade_out():
	targetCutoff = 1
	if transit_out_anim == "":
		transit_out_anim = transit_in_anim
	fade.fade_out(transit_out_anim, transit_out_color, fade_out_speed)

func enter(_player=global.persistPlayer):
	player = _player
	if !global.cutscene:
		set_flag()
		fade = uiManager.fade
		if activeDoor:
			if global.currentScene.get_name() == targetScene or targetScene == "":
				sameScene = true
			else:
				if fadeout_music_on_scene_change:
					for musicChanger in audioManager.musicChangers:
						musicChanger.stop_music(fadeout_music_length)
				global.add_persistent(self)
			activeDoor = false
			if sound != null and sound != "":
				$AudioStreamPlayer.stream = load("res://Audio/Sound effects/" + sound)
				$AudioStreamPlayer.play()
			global.persistPlayer.pause()
			fade_in()
			currentState = 1
			set_process(true)

func set_flag():
	if flag_set != "":
		if globaldata.flags.has(flag_set):
			globaldata.flags[flag_set] = set_flag_state
