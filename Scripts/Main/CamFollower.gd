extends ColorRect

func _process(delta):
	rect_global_position = global.currentCamera.get_camera_screen_center() - rect_size/2
