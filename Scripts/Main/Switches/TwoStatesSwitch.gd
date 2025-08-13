# An on/off switch that controls a determined list of two-states objects
class_name TwoStatesSwitch
extends ObjectsListSwitch

export (bool) var _is_one_way := false

func _enter_tree():
	for controlled_object in _controlled_objects:
		controlled_object.register_switch(self)

func _ready():
	_on_state_changed(is_on())

func is_on() -> bool:
	return _get_flag_status()

# Override
func _do_switch_action():
	toggle()

func toggle():
	turn_on_off(!is_on())

func turn_on_off(value):
	_set_flag_status(value)
	_on_state_changed(value)
	_update_controlled_objects()

func _on_state_changed(state: bool):
	if state:
		_anim_player.play("TurnOn")
		if _is_one_way:
			_is_disabled = true
	else:
		_anim_player.play("TurnOff")

