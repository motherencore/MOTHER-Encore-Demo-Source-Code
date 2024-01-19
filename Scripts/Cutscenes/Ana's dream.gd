extends Node2D

export (String) var music
export (String) var loop


func _ready():
	if loop != "":
		globaldata.musicLoop = loop 
	else:
		globaldata.musicLoop = null
	
	if music != null:
		
		global.play_music(music)
	
	global.persistPlayer.position.x = 160
	global.persistPlayer.position.y = 368
	

func _on_Area2D_body_entered(body):
	$Objects/npc.animationTree.active = false
	uiManager.blackBars.animaPlayer.play("Open")
	$AnimationPlayer.play("cutscene")
	global.persistPlayer.paused = true
	$Objects/Area2D.queue_free()
	
func _fade():
	uiManager.fade.material.set_shader_param("cut", 0)
	
func _shock():
	global.persistPlayer.get_node("emotes").animaPlayer.play("shock")
	
func _unpause():
	global.persistPlayer.paused = false
	global.persistPlayer.velocity = 30
