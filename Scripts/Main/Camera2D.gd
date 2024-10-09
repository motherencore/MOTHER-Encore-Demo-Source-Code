extends Camera2D

signal stoped_shaking

const cam_limit = 50
var inputVector = Vector2.ZERO
var current_offset = Vector2.ZERO #used for knowing the normal offset when shaking it
var camareas = 0
var shaking = false

onready var arrowUp = $ArrowPos/arrowU
onready var arrowDown = $ArrowPos/arrowD
onready var arrowLeft = $ArrowPos/arrowL
onready var arrowRight = $ArrowPos/arrowR




func _ready():
	if get_parent() == global.persistPlayer:
		global.persistPlayer.connect("paused", self, "arrows_come_out")

func _process(_delta):
	if $ArrowPos.visible:
		$ArrowPos.global_position = get_camera_screen_center()

func _physics_process(_delta):
	if !global.persistPlayer.damaging and self == global.currentCamera and global.persistPlayer.state == global.persistPlayer.CAMERA:
		if Input.is_action_just_pressed("ui_scope", true):
			global_position = get_camera_screen_center()
			$ArrowsAnim.play("Come In")
		if Input.is_action_just_released("ui_scope", true):
			$ArrowsAnim.play("Come Out")
			global.persistPlayer.exit_camera()
			return_offset(0.3)
		if Input.is_action_pressed("ui_scope", true) and global.persistPlayer.state != global.persistPlayer.ATTACK:
			global.persistPlayer.state = global.persistPlayer.CAMERA
			var up = 0
			var down = 0
			var left = 0
			var right = 0
			var input = controlsManager.get_controls_vector()
			if offset.y > -cam_limit and get_camera_screen_center().y - 90 > limit_top:
				if input.y < 0:
					up = 1
				if !arrowUp.visible:
					arrowUp.show()
			elif arrowUp.visible:
				arrowUp.hide()
			if offset.y < cam_limit and get_camera_screen_center().y + 90< limit_bottom:
				if input.y > 0:
					down = 1
				if !arrowDown.visible:
					arrowDown.show()
			elif arrowDown.visible:
				arrowDown.hide()
			if offset.x > -cam_limit and get_camera_screen_center().x - 160 > limit_left:
				if input.x < 0:
					left = 1
				if !arrowLeft.visible:
					arrowLeft.show()
			elif arrowLeft.visible:
				arrowLeft.hide()
			if offset.x < cam_limit and get_camera_screen_center().x + 160 < limit_right:
				if input.x > 0:
					right = 1
				if !arrowRight.visible:
					arrowRight.show()
			elif arrowRight.visible:
				arrowRight.hide()
			
			inputVector.x = int(right) - int(left)
			inputVector.y = int(down) - int(up)
			offset += inputVector * 2
			current_offset = offset

func _input(event):
	if controlsManager.get_just_pressed_up():
		arrowUp.get_node("AnimationPlayer").play("Point")
	if controlsManager.get_just_pressed_down():
		arrowDown.get_node("AnimationPlayer").play("Point")
	if controlsManager.get_just_pressed_left():
		arrowLeft.get_node("AnimationPlayer").play("Point")
	if controlsManager.get_just_pressed_right():
		arrowRight.get_node("AnimationPlayer").play("Point")
	if controlsManager.get_just_released_up():
		arrowUp.get_node("AnimationPlayer").play("UnPoint")
	if controlsManager.get_just_released_down():
		arrowDown.get_node("AnimationPlayer").play("UnPoint")
	if controlsManager.get_just_released_left():
		arrowLeft.get_node("AnimationPlayer").play("UnPoint")
	if controlsManager.get_just_released_right():
		arrowRight.get_node("AnimationPlayer").play("UnPoint")


func arrows_come_out():
	if arrowDown.position.y != 100:
		$ArrowsAnim.play("Come Out")

func move_camera(position_x,position_y, time):
	$Tween.interpolate_property(self,"global_position",
		get_camera_screen_center(), Vector2(position_x,position_y), time,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func move_offset(offset_x,offset_y, time):
	var new_pos = global_position + Vector2(offset_x, offset_y)
	if new_pos.y - 90 < limit_top and offset_y < 0:
		if global_position.y - 90 > limit_top:
			offset_y = limit_top - global_position.x - 90
		else:
			offset_y = 0
	if new_pos.y + 90 > limit_bottom and offset_y > 0:
		if global_position.y + 160 < limit_bottom:
			offset_y =  limit_bottom - global_position.y - 90
		else:
			offset_y = 0
	if new_pos.x - 160 < limit_left and offset_x < 0:
		if global_position.x - 160 > limit_left:
			offset_x = limit_left - global_position.x - 160
		else:
			offset_x = 0
	if new_pos.x + 160 > limit_right and offset_x > 0:
		if global_position.x + 160 < limit_right:
			offset_x =  limit_right - global_position.x - 160
		else:
			offset_x = 0
	$Tween.interpolate_property(self,"offset",
		offset, Vector2(offset_x,offset_y), time,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	current_offset = offset
	$Tween.start()

func return_camera(time = 1):
	$Tween.stop_all()
	$Tween.interpolate_property(self,"position",
		position, Vector2.ZERO, time,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	
	$Tween.start()
	
	yield($Tween,"tween_completed")
	
	position = Vector2.ZERO

func return_offset(time = 1):
	$Tween.stop_all()
	$Tween.interpolate_property(self,"offset",
		offset, Vector2.ZERO, time,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	
	$Tween.start()
	
	$Tween.interpolate_property(self,"position",
		position, Vector2.ZERO, time,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	
	$Tween.start()
	
	yield($Tween,"tween_completed")
	
	position = Vector2.ZERO
	offset = Vector2.ZERO
	current_offset = offset

func reset():
	position = Vector2.ZERO
	offset = Vector2.ZERO

func shake_camera(magnitude = 1.0, time = 1.0, direction = Vector2.ONE):
	if !$Tween.is_active():
		var old_offset = current_offset
		var shake = magnitude
		shaking = true
		if shake < 1.0:
			shake = 1.0
		if time < 0.2:
			time = 0.2
		for i in int(time / .02):
			if !global.queuedBattle and !global.inBattle and global.persistPlayer.state != global.persistPlayer.CAMERA:
				var new_offset = Vector2.ZERO
				if abs(shake) > 1:
					shake = shake * -1
					magnitude = magnitude * -1
				else:
					if shake < 0.5:
						shake = 1.0
					else:
						shake = 0.0
				new_offset = Vector2(shake, shake) * direction
				#offset = new_offset
				$Tween.interpolate_property(self, "offset",
					offset, new_offset, 0.02, 
					Tween.TRANS_QUART, Tween.EASE_OUT)
				$Tween.start()
				yield(get_tree().create_timer(.02), "timeout")
				if abs(shake) > 1:
					shake -= magnitude / int(time / .02)
				
		offset = old_offset
		shaking = false
		emit_signal("stoped_shaking")

func set_current():
	limit_bottom = global.currentCamera.limit_bottom
	limit_left = global.currentCamera.limit_left
	limit_right = global.currentCamera.limit_right
	limit_top = global.currentCamera.limit_top
	camareas = global.currentCamera.camareas
	global_position = global.currentCamera.get_camera_screen_center()
	make_current()
	global.currentCamera = self
