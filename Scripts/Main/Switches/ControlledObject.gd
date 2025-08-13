class_name ControlledObject
extends Sprite

export (bool) var _move_cam_when_changed := false
export (Vector2) var _move_cam_offset := Vector2.ZERO
export (int) var _update_order := 0

# To be overridden for objects that are directly controlled by switches
func custom_switch_action(action_name: String):
	print("%s do action %s" % [self, action_name])
	pass

# Overridden
func update_state(silent: bool = false):
	pass

func does_move_cam_when_changed() -> bool:
	return _move_cam_when_changed

func get_move_cam_position() -> Vector2:
	return position + _move_cam_offset

# Overridden
func get_update_order() -> int:
	return _update_order
