extends Area2D

export (String, "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var entering_sound = "grass"
export (String, "", "grass", "stone", "soil", "sand", "wood", "metal", "water", "cave") var exiting_sound = ""
export (String, "", "shadow", "ripple", "magic") var enter_shadow_effect = "shadow"
export (String, "", "shadow", "ripple", "magic") var exit_shadow_effect = ""


var enabled = true

func _on_Stepping_Sounds_body_entered(body):
	if body == global.persistPlayer and enabled:
		set_player_run_sound(entering_sound)
	if body.has_method("set_shadow") and enter_shadow_effect != "":
		body.set_shadow(enter_shadow_effect)
		

func _on_Stepping_Sounds_body_exited(body):
	if body == global.persistPlayer and exiting_sound != "" and enabled:
		set_player_run_sound(exiting_sound)
	if body.has_method("set_shadow") and exit_shadow_effect != "":
		body.set_shadow(exit_shadow_effect)



func set_player_run_sound(sound):
	global.persistPlayer.run_sound = sound

func enable():
	enabled = true

func disable():
	enabled = false
