extends Sprite

signal switch_hit

var active = false
export (String) var flag = ""

func _ready():
	if (flag != null or flag != "") and globaldata.flags.has(flag) and globaldata.flags[flag] == true:
		active = true
		$AnimationPlayer.play("Down")
		yield(get_tree(), "idle_frame")
		emit_signal("switch_hit")


func _on_Area2D_body_entered(body):
	if body == global.persistPlayer and active == false:
		$AnimationPlayer.play("Down")
		$AudioStreamPlayer.playing = true
		active = true
		if (flag != null or flag != "") and globaldata.flags.has(flag) and globaldata.flags[flag] == false:
			globaldata.flags[flag] = true
		emit_signal("switch_hit")

