extends KinematicBody2D

var velocity = Vector2.ZERO
var inputVector = Vector2.ZERO
var speed = 150
var direction = 1
var start_pos

func _ready():
	_prepare()
	set_process(false)
	hide()

func _prepare():
	$Sprite.texture = load("res://Graphics/Character Sprites/Npcs/misc/birds/" + var2str(randi()%3+0) + ".png")
	$AnimationPlayer.play("Idle")
	$AnimationPlayer.seek((randf()*4), true)
	if (randi()%2+0) == 1:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
	speed = 150 + (randi()%50)
	inputVector = Vector2.ZERO
	start_pos = position


func _process(_delta):
	_movement()
	if !$VisibilityNotifier2D.is_on_screen() and $Timer.time_left == 0:
		show()

func _on_Area_body_entered(body):
	if body == global.persistPlayer and body.position.x <= position.x:
		$AnimationPlayer.play("Fly")
		self.z_index = 1
		inputVector.y = -1
		$Sprite.flip_h = false
		inputVector.x = 1
	elif body == global.persistPlayer and body.position.x > position.x:
		$AnimationPlayer.play("Fly")
		self.z_index = 1
		inputVector.y = -1
		$Sprite.flip_h = true
		inputVector.x = -1
	$Timer.start()
	

func _movement():
	if inputVector != Vector2.ZERO:
		velocity = inputVector * speed
		velocity = move_and_slide(velocity)

func _on_AnimationPlayer_animation_finished(anim_name):
		
	if anim_name == "hop" or "hop right":
		$AnimationPlayer.play("Idle")
		
	if anim_name == "Idle":
		if $Sprite.flip_h == false:
			$Sprite.flip_h = true
			$AnimationPlayer.play("hop")
		else:
			$Sprite.flip_h = false
			$AnimationPlayer.play("hop right")
		


func _on_VisibilityNotifier2D_screen_exited():
	position = start_pos
	hide()
	_ready()
	set_process(false)
	hide()


func _on_VisibilityNotifier2D_screen_entered():
	if $Timer.time_left == 0:
		show()
		set_process(true)
		_prepare()

