tool
extends AnimatedSprite

export (String, "shadow", "ripple", "magic") var start_anim setget set_anim

var in_front_anims = ["ripple"]


func set_anim(anim) -> void:
	start_anim = anim
	play(anim)
	_set_behind_parent(!anim in in_front_anims)

func _set_behind_parent(enabled = false) -> void:
	show_behind_parent = enabled
