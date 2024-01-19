extends Node2D

export (String) var music
export (String) var loop


# Called when the node enters the scene tree for the first time.
func _ready():
	if loop != "":
		globaldata.musicLoop = loop 
	else:
		globaldata.musicLoop = null
	
	if music != null:
		
		global.play_music(music)
		
