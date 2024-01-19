extends Area2D

export var flag = ""
export var value = true #the value it should set the flag to

func _ready():
	if globaldata.flags.has(flag):
		if globaldata.flags[flag] == value:
			queue_free()

func _on_Cutscene_Area_body_entered(body):
	if body == global.persistPlayer:
		if globaldata.flags.has(flag):
			globaldata.flags[flag] = value
