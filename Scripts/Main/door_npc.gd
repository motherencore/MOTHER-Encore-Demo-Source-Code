extends Area2D

export (String) var dialog
var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": false #Make "y" true if you want the player to turn up/down to face npc
}

func _on_Door_NPC_body_entered(body):
	if body == global.persistPlayer:
		if dialog != "":
			global.persistPlayer.turn_to(self, true)
			global.persistPlayer.pause()
			global.cutscene = true
			uiManager.blackBars.open()
			$AudioStreamPlayer.play()
			yield(get_tree().create_timer(1),"timeout")
			global.set_dialog(dialog, null) 
			uiManager.open_dialogue_box()
			global.cutscene = false
