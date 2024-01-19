extends KinematicBody2D


var velocity = Vector2.ZERO
var inputVector = Vector2.ZERO
var speed = 30
var direction = 1
var start_pos
var Return = false

onready var sprite = $Sprite
onready var animationPlayer = $AnimationPlayer
onready var animationPlayer2 = $AnimationPlayer2

func _ready():
	sprite.texture = load("res://Graphics/Character Sprites/Npcs/misc/butterflies/" + var2str(randi()%5) + ".png")
	start_pos = position
	set_process(false)
	hide()

func _process(_delta):
	_movement()
	var old_pos = global_position
	if Return == true:
		position = position.move_toward(start_pos, speed * _delta)
		if old_pos.x < global_position.x:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
		if global_position == start_pos:
			Return = false

func _on_Area_body_entered(body):
	if body == global.persistPlayer and global.persistPlayer.walk:
		Return = false
		inputVector = -sprite.global_position.direction_to(body.global_position)
		if body.global_position.x < sprite.global_position.x:
			sprite.flip_h = false
		else:
			sprite.flip_h = true

func _on_Area_body_exited(body):
	if body == global.persistPlayer and global_position != start_pos:
		$Timer.start()
		yield($Timer,"timeout")
		inputVector = Vector2.ZERO
		$Timer.start()
		yield($Timer,"timeout")
		Return = true

func _movement():
	if inputVector != Vector2.ZERO:
		velocity = inputVector * speed
		velocity = move_and_slide(velocity)

func _on_AnimationPlayer2_animation_finished(anim_name):
	if anim_name == "Disappear":
		inputVector = Vector2.ZERO
	
func _on_VisibilityNotifier2D_screen_entered():
	animationPlayer.play("Fly")
	animationPlayer2.play("Flying")
	animationPlayer.seek((randf()*0.3), true)
	animationPlayer2.seek((randf()*20), true)
	set_process(true)
	show()

func _on_VisibilityNotifier2D_screen_exited():
	animationPlayer.stop()
	animationPlayer2.stop()
	set_process(false)
	hide()
