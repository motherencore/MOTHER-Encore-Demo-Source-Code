extends AreaRoom

func _on_main_switch_hit():
	global.persistPlayer.pause()
	global.cutscene = true
	audioManager.music_fadeout(0)

func _on_wall_door_state_changed(state: bool, silent: bool):
	if state and !silent:
		yield(get_tree().create_timer(0.5), "timeout")
		$Music/MusicArea.play_music()
		global.cutscene = false
		global.persistPlayer.unpause()
