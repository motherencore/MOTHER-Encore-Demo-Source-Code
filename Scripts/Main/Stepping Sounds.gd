extends Area2D

export (String, "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var entering_sound = "grass"
export (String, "", "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var exiting_sound = ""

var enabled = true

func _on_Stepping_Sounds_body_entered(body):
	if body == global.persistPlayer and enabled:
		set_player_run_sound(entering_sound)

func _on_Stepping_Sounds_body_exited(body):
	if body == global.persistPlayer and exiting_sound != "" and enabled:
		set_player_run_sound(exiting_sound)

func set_player_run_sound(sound):
	global.persistPlayer.run_sound = sound

func enable():
	enabled = true

func disable():
	enabled = false
