extends Area2D

export (String, "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var entering_sound = "grass"
export (String, "", "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var exiting_sound = ""

var enabled = true

func _on_Stepping_Sounds_body_entered(body):
	if body == global.persistPlayer and enabled:
		global.persistPlayer.run_sound = entering_sound + ".wav"

func _on_Stepping_Sounds_body_exited(body):
	if body == global.persistPlayer and exiting_sound != "" and enabled:
		global.persistPlayer.run_sound = exiting_sound + ".wav"

func enable():
	enabled = true

func disable():
	enabled = false
