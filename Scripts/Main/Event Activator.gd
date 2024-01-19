extends Area2D

export var object_path : NodePath
export (String) var function = ""
export (String) var check_flag = ""
export (bool) var check_flag_state = false
export (String) var flag_set = ""
export (bool) var set_flag_state = true

onready var object = get_node_or_null(object_path)

func _on_Event_Activator_body_entered(body):
	if body == global.persistPlayer:
		if check_flag != "":
			if globaldata.flags.has(check_flag):
				if globaldata.flags[check_flag] == check_flag_state:
					activate_event()
		else:
			activate_event()

func activate_event():
	if object != null and function != "":
		if object.has_method(function):
			object.call(function)
	set_flag()

func set_flag():
	if flag_set != "":
		if globaldata.flags.has(flag_set):
			globaldata.flags[flag_set] = set_flag_state
