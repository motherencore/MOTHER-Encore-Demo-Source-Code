extends KinematicBody2D

var speed = 260
var inputVector = Vector2.ZERO
var trail
var gone = false
var move = true

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var spark = preload("res://Nodes/Reusables/Overlap/LaserSpark.tscn")
onready var sfx = load("res://Audio/Sound effects/Lloyd Laser.mp3")


func _ready():
	animationTree.active = true
	animationTree.set("parameters/shoot/blend_position", inputVector)
	audioManager.play_sfx(sfx, "laser")
	
	
	

func _physics_process(delta):
	if !gone:
		animationTree.set("parameters/shoot/blend_position", inputVector)
		if move == true:
			position = position + transform.x * speed * delta
		position.x = round(position.x)
		position.y = round(position.y)
		$Area2D2.global_position = global_position + Vector2(0,7)

func _on_Timer_timeout():
	create_spark("Explosion")
	disappear()

func _on_Area2D_area_entered(area):
	var mirror = area.get_parent()
	if "reflect" in mirror:
		var wait = Timer.new()
		$AnimatedSprite.hide()
		move = false
		wait.set_wait_time(0.05)
		wait.set_one_shot(true)
		self.add_child(wait)
		wait.start()
		create_spark("Spark")
		inputVector = inputVector.bounce(mirror.reflect).normalized()
		yield(wait,"timeout")
		move = true
		wait.start()
		yield(wait,"timeout")
		if !gone:
			$AnimatedSprite.show()
		wait.queue_free()
	else:
		print(area.get_parent())
		create_spark("Explosion")
		disappear()

func _on_Area2D2_body_entered(_body):
	create_spark("Explosion")
	disappear()
	
func disappear():
	gone = true
	$AnimatedSprite.hide()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)

func create_spark(animation):
	var sparkle = spark.instance()
	if animation == "Explosion":
		get_parent().get_parent().add_child(sparkle)
	else:
		add_child(sparkle)
	sparkle.global_position = global_position
	sparkle.animation = animation


