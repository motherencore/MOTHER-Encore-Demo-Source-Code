class_name FlaggableObject
extends Sprite

export (String) var flag := ""
export (bool) var reset_when_leaving_region := false
export (bool) var reset_when_leaving_area := false

func _ready():
	if !Engine.is_editor_hint():
		global.currentScene.connect("area_left", self, "_on_leave_area")

func _get_flag_status() -> bool:
	if !Engine.is_editor_hint():
		if flag != null and flag != "":
			return globaldata.flags.get(flag, false)
		else:
			return globaldata.object_flags.get(global.currentScene.name + "/" + name, false)
	return false
	
func _set_flag_status(value = true):
	if !Engine.is_editor_hint():
		if flag != null and flag != "":
			globaldata.flags[flag] = value
		else:
			globaldata.object_flags[global.currentScene.name + "/" + name] = value

func _on_leave_area(region_changed: bool):
	if reset_when_leaving_area or (region_changed and reset_when_leaving_region):
		_set_flag_status(false)
