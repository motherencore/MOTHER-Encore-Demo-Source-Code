extends YSort

export var appear_flag = ""
export var disappear_flag = ""

func _ready():
	check_flags()
	global.connect("cutscene_ended", self, "check_flags")

func check_flags():
	if appear_flag != "":
		if globaldata.flags.has(appear_flag):
			if globaldata.flags[appear_flag] == true:
				show()
			else:
				hide()
		else:
			hide()
	if disappear_flag != "":
		if globaldata.flags.has(disappear_flag):
			if globaldata.flags[disappear_flag] == true:
				hide()

	if !visible:
		queue_free()
