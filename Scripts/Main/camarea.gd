extends Area2D

func _on_camarea_body_exited(body):
	if body == global.persistPlayer:
		global.currentCamera.camareas -= 1
		if global.currentCamera.camareas == 0:
			global.currentCamera.limit_top = -10000000
			global.currentCamera.limit_left = -10000000
			global.currentCamera.limit_right = 10000000
			global.currentCamera.limit_bottom = 10000000
			global.currentCamera.smoothing_enabled = false

func _on_camarea_body_entered(body):
	if body == global.persistPlayer:
		global.currentCamera.camareas += 1
		var size = $CollisionShape2D.shape.extents * 2 * self.transform.get_scale()
		size.x = round(size.x)
		size.y = round(size.y)
		var view_size = get_viewport_rect().size
		if size.y < view_size.y:
			size.y = view_size.y
			
		if size.x < view_size.x:
			size.x = view_size.x
		
		
		global.currentCamera.limit_top = $CollisionShape2D.global_position.y - size.y/2
		global.currentCamera.limit_left = $CollisionShape2D.global_position.x - size.x/2
		
		global.currentCamera.limit_bottom = global.currentCamera.limit_top + size.y
		global.currentCamera.limit_right = global.currentCamera.limit_left + size.x
		global.currentCamera.smoothing_enabled = true
		
		yield(get_tree().create_timer(0.2),"timeout")
		
		global.currentCamera.smoothing_enabled = false
