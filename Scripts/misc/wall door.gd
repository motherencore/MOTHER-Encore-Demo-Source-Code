extends ControlledTwoStatesObject

func _init():
	_state_anim_player = "AnimationPlayer"

func _shake(duration: float):
	global.persistPlayer.camera.shake_camera(2, duration, Vector2(1, 0))
