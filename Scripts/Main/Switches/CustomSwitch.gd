class_name CustomSwitch
extends ObjectsListSwitch

export (Array, String) var _controlled_objects_actions: Array

# Override
func _control_object(index: int):
	var action: String
	if index < _controlled_objects_actions.size():
		action = _controlled_objects_actions[index]
	return _controlled_objects[index].custom_switch_action(action)
