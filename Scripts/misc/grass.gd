extends Area2D

onready var tween = $Tween
onready var timer = $Timer
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")


var objects = []

func set_grass(sprite, texture, flipped):
	animationTree.active = false
	set_physics_process(false)
	$Sprite.texture = load(texture)
	$Sprite.flip_h = flipped

func _physics_process(delta):
	if objects.size() > 0:
		var averagePos = Vector2.ZERO
		for i in objects:
			averagePos.x += i.global_position.x
		averagePos.x = int(averagePos.x / objects.size())
		if $Sprite.flip_h:
			blend_position((global_position - averagePos) / ($Sprite.texture.get_width() /8) * Vector2(-1, 0))
		else:
			blend_position((global_position - averagePos) / ($Sprite.texture.get_width() /8))
		animationState.travel("Ruffle")

func blend_position(vector2):
	animationTree.set("parameters/Ruffle/blend_position", vector2)

func _on_Grass_body_entered(body):
	if visible:
		objects.append(body)
		animationTree.active = true
		
		if objects.size() == 1:
			set_physics_process(true)
			animationTree.active = true
		
		if timer.time_left == 0:
			tween.interpolate_property($Sprite, "scale", 
				Vector2(1, 0.8), Vector2.ONE, 0.1)
			tween.start()

func _on_Grass_body_exited(body):
	if objects.has(body):
		objects.erase(body)
	if objects.size() == 0:
		set_physics_process(false)
		if timer != null:
			timer.start()

func _on_Timer_timeout():
	animationState.travel("Idle")
	tween.interpolate_property($Sprite, "scale", 
		Vector2(1, 0.8), Vector2.ONE, 0.2)
	tween.start()
	
	yield(tween, "tween_all_completed")
	
	animationTree.active = false

func _on_Grass_tree_exiting():
	timer.queue_free()
	timer = null
