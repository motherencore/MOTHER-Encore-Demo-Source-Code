# A switch that controls a determined list of objects
class_name ObjectsListSwitch
extends AbstractSwitch

export (bool) var _pause_when_changed := false
export (bool) var _focus_objects_when_changed := false
export (float) var _camera_delay := 1
export (Array, NodePath) var _controlled_objects: Array

func _enter_tree():
	for i in _controlled_objects.size():
		if _controlled_objects[i] is NodePath:
			_controlled_objects[i] = get_node(_controlled_objects[i])

func _do_switch_action():
	_update_controlled_objects()

func _update_controlled_objects():
	if _pause_when_changed:
		global.persistPlayer.pause()
		global.cutscene = true

	_controlled_objects.sort_custom(self, "_sort_controlled_objects")
	var cur_order: int = _controlled_objects[0].get_update_order() if _controlled_objects else 0
	var actions_to_wait := []
	var objects_to_focus := []
	for i in _controlled_objects.size():
		var cur_object = _controlled_objects[i]

		if cur_object.get_update_order() > cur_order:
			var cam_in_progress = _wait_and_move_camera(objects_to_focus, actions_to_wait)
			if cam_in_progress: yield(cam_in_progress, "completed")
			cur_order = cur_object.get_update_order()

		var in_progress: GDScriptFunctionState = _control_object(i)
		if in_progress:
			actions_to_wait.append(in_progress)
		if _focus_objects_when_changed and cur_object.does_move_cam_when_changed():
			objects_to_focus.append(cur_object)

	var cam_in_progress = _wait_and_move_camera(objects_to_focus, actions_to_wait)
	if cam_in_progress: 
		yield(cam_in_progress, "completed")

	if _focus_objects_when_changed:
		yield(get_tree(), "idle_frame")
		yield(global.persistPlayer.camera.return_camera(_camera_delay), "completed")
	
	if _pause_when_changed:
		global.persistPlayer.unpause()
		global.cutscene = false


# Overridden
func _control_object(index: int):
	return _controlled_objects[index].update_state()

func _sort_controlled_objects(obj1, obj2):
	return obj1.get_update_order() < obj2.get_update_order()

func _wait_and_move_camera(objects_to_focus: Array, actions_to_wait: Array):
	if objects_to_focus.size() > 0:
		var camera_pos := Vector2.ZERO
		for obj_to_focus in objects_to_focus:
			camera_pos += obj_to_focus.get_move_cam_position()
		camera_pos /= objects_to_focus.size()
		yield(global.persistPlayer.camera.move_camera(camera_pos, _camera_delay), "completed")
	for in_progress in actions_to_wait:
		if in_progress.is_valid():
			yield(in_progress, "completed")
	actions_to_wait.clear()
	objects_to_focus.clear()
