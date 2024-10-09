extends CanvasLayer

const gameOverDialog = "GameOver"

var fade

signal fade_done

func _init():
	fade = uiManager.fade
	
	#uiManager.add_ui(fade)
	uiManager.clearOnScreenEnemies()

func _ready():
	global.gameover = true
	uiManager.reset_battle_cutscenes()
	turn_off_music_changers()
	global.persistPlayer.set_all_collisions(false)
	if globaldata.cash == 1:
		globaldata.cash = 0 # This is not very nice!
	else:
		globaldata.cash = int(globaldata.cash/2.0)
	fade.fade_in("Circle")
	yield(fade, "fade_in_done")
	
	emit_signal("fade_done")
	$Timer.start()
	yield($Timer, "timeout")
	fade.set_cut(1, 0.01)
	audioManager.stop_all_music()
	audioManager.remove_all_unplaying()
	audioManager.add_audio_player()
	audioManager.play_music_from_id("", "Game_Over.ogg", audioManager.get_audio_player_count()-1)
	$AnimationPlayer.play("nintenFall")
	yield($AnimationPlayer, "animation_finished")
	
	global.set_dialog(gameOverDialog, null)
	var dialogueBox = uiManager.open_dialogue_box()
	dialogueBox.unpausePlayer = false
	dialogueBox.connect("finalPhrase", self, "end_phrase")
	
	

func end_phrase(phrase):
	print(phrase)
	if phrase == 9:
		audioManager.music_fadeout(audioManager.get_audio_player_count()-1, 5)
		$AnimationPlayer.play("nintenGetup")
		yield($AnimationPlayer, "animation_finished")
		
		$AnimationPlayer.play("transitionOut")
		fade.fade_in("Fade", Color.white, 0.3)
		yield($AnimationPlayer, "animation_finished")
		
		revive_party()
		global.goto_respawn()
		$GameOverLayer.hide()
		fade.fade_out("Fade", Color.white)
		yield(fade, "fade_out_done")
		
		global.persistPlayer.set_all_collisions(true)
		global.persistPlayer.unpause()
		
		global.gameover = false
		uiManager.commandsMenuActive = false
		uiManager.remove_ui(self)
	elif phrase == 7:
		audioManager.music_fadeout(audioManager.get_audio_player_count()-1, 5)
		$AnimationPlayer.play("transitionOut")
		fade.fade_in("Fade", Color.black, 0.2)
		yield($AnimationPlayer, "animation_finished")
		$GameOverLayer.hide()
		$Door.enter()
		
		yield($Door, "done")
		global.gameover = false
		uiManager.commandsMenuActive = false
		uiManager.remove_ui(self)

func turn_off_music_changers():
	for musicChanger in audioManager.musicChangers:
		musicChanger.stop_music_immediately()

func revive_party():
	for i in global.party:
		i.status.clear()
		if i == global.party[0]:
			i.hp = i.maxhp + i.boosts.maxhp
			i.pp = i.maxpp + i.boosts.maxpp
		else:
			i.status.append(globaldata.ailments.Unconscious)
			i.pp = i.maxpp + i.boosts.maxpp
