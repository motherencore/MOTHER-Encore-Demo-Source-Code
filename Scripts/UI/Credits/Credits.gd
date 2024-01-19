extends Control

func _ready():
	global.stop_playtime()
	yield(get_tree().create_timer(3), "timeout")
	global.persistPlayer.hide()
	global.persistPlayer.pause()
	$AnimationPlayer.play("Scroll")
	play_music()

func play_music():
	audioManager.stop_all_music()
	audioManager.add_audio_player()
	audioManager.play_music_from_id("DemoCredits.mp3", "", audioManager.get_audio_player_count() - 1)
	audioManager.set_audio_player_volume(audioManager.get_audio_player_count() - 1, 12)



func _on_AnimationPlayer_animation_finished(anim_name):
	$Door.enter()
