extends NinePatchRect


func _process(delta):
	var player = global.persistPlayer
	$VBoxContainer/fpsdisplay.text = "FPS: " + var2str(Engine.get_frames_per_second())
	$VBoxContainer/map.text = "Map: " + get_tree().get_current_scene().get_name()
	$VBoxContainer/pos.text = "XY: " + var2str(int(global.persistPlayer.position.x)) + " " + var2str(int(global.persistPlayer.position.y))
	if player.walk == true:
		$VBoxContainer/state.text = "State: Walk"
	else:
		$VBoxContainer/state.text = "State: Idle"
	$VBoxContainer/velocity.text = "Vel: " + str(global.persistPlayer.velocity)
	$VBoxContainer/Anim.text = "Anim: " + player.animationPlayer.current_animation
