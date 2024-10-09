extends CanvasLayer

onready var _anim_player = $AnimationPlayer
var _is_open = false

func toggle(open):
	if open and !_is_open:
		_anim_player.play("Open")
		_is_open = true
	elif !open and _is_open:
		_anim_player.play("Close")
		_is_open = false
