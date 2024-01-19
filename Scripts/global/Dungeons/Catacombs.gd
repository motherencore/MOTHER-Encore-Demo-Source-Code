extends Node


func _on_switch_switch_hit():
	global.cutscene = true
	audioManager.music_fadeout(0)
	global.persistPlayer.pause()
	
	global.persistPlayer.camera.move_camera(-648,164, 1)
	get_parent().get_node("Timer").start()
	
	yield (get_parent().get_node("Timer"),"timeout")
	
	get_parent().get_node("Bottom2/Wall Door/AnimationPlayer").play("Open")
	global.persistPlayer.camera.shake_camera(2, 0.4, Vector2(1, 0))
	yield(get_tree().create_timer(0.75), "timeout")
	global.persistPlayer.camera.shake_camera(4, 0.7, Vector2(1, 0))
	yield(get_parent().get_node("Bottom2/Wall Door/AnimationPlayer"),"animation_finished")
	
	get_parent().get_node("Timer").start()
	global.persistPlayer.camera.return_camera(1)
	
	yield (get_parent().get_node("Timer"),"timeout")
	
	global.persistPlayer.unpause()
	global.cutscene = false
	get_parent().get_node("Music/MusicArea").play_music()
