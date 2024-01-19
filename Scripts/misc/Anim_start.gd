extends AnimationPlayer

export var animation = ""
export var play_on_start = true

func _ready():
	if play_on_start:
		play(animation)

func play_anim():
	play(animation)
