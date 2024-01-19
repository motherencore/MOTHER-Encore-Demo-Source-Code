extends Area2D

export (String) var music
export (String) var loop



func _on_MusicPlayer_body_entered(body):
	if loop != "":
		globaldata.musicLoop = loop 
	else:
		globaldata.musicLoop = null
	if music != null:
		global.play_music(music)
		


func _on_MusicPlayer_body_exited(body):
	global.music_fadeout()


