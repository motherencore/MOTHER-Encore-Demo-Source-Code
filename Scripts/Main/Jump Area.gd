extends Area2D

signal jump

export var jumpHeight = 20
export var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right when jumping
	"x": true #Make "y" true if you want the player to turn up/down when jumping
}  #Putting both to true will apply both effects and enable diagonals
var canJump
var jumping = false
var arrowPos = Vector2.ZERO
var wasRunning = false

func _ready():
	arrowPos = $Sprite.position
	$Sprite.scale = Vector2.ZERO

func _input(event):
	if event.is_action_pressed("ui_accept"):
		start_jump_process()

func start_jump_process():
	if canJump and !global.persistPlayer.paused and uiManager.uiStack.size() == 0 and global.persistPlayer.state == global.persistPlayer.MOVE:
		$Camera2D.set_current()
		if global.persistPlayer.tap_run == true:
			wasRunning = true
		jumping = true
		global.persistPlayer.pause()
		global.persistPlayer.set_collision_layer_bit(0, false)
		_on_Close_body_exited(global.persistPlayer)
		#pauses all characters in party
		for i in range(1, global.partyObjects.size()):
			global.partyObjects[i].jumps += 1
			if global.partyObjects[i].is_physics_processing():
				global.partyObjects[i].animationState.travel("Idle")
				global.partyObjects[i].set_physics_process(false)
		#now it's time to make them jump!
		for j in global.partyObjects:
			if j.get("jumps") != null:
				if !j.active:
					yield(j, "actionDone")
				j.active = false
			jump(j)
			if j == global.partyObjects[0]:
				emit_signal("jump")
			else:
				yield(self, "jump")
			yield(get_tree().create_timer(0.5), "timeout")
	elif jumping:
		emit_signal("jump")

func jump(jumper):
	var tween = Tween.new()
	self.add_child(tween)
	for i in $"Jump Points".get_children():
		if i.get_class() == "Position2D":
			if jumper.get("direction"):
				global.start_joy_vibration(0, 0.4, 0, 0.2)
				jumper.direction = jumper.global_position.direction_to(i.global_position)
				if !player_turn.x:
					jumper.direction.x = 0
				if !player_turn.y:
					jumper.direction.y = 0
			else:
				jumper.inputVector = jumper.global_position.direction_to(i.global_position).normalized()
				if !player_turn.x:
					jumper.inputVector.x = 0
				if !player_turn.y:
					jumper.inputVector.y = 0
			jumper.animationState.travel("Idle")
			if jumping:
				if jumper.get("jumps") == null:
					yield(self, "jump")
				elif jumper.jumps == 1:
					yield(self, "jump")
			jumper.jump(jumpHeight, 0.3, true)
			tween.interpolate_property(jumper, "global_position",
				jumper.global_position, i.global_position - jumper.get_node("Shadow").position, 0.525, 
				Tween.TRANS_LINEAR,Tween.EASE_IN, 0.1)
			tween.start()
			if jumper == global.persistPlayer:
				global.start_joy_vibration(0, 0.4, 0, 0.2)
				if i.get_index() != $"Jump Points".get_child_count() -1:
					var nextPoint = $"Jump Points".get_child(i.get_index() + 1)
					global.currentCamera.move_camera((i.global_position.x + nextPoint.global_position.x) / 2, (i.global_position.y + nextPoint.global_position.y) / 2 - 7, 0.6)
				else:
					global.currentCamera.move_camera(i.global_position.x, i.global_position.y - 7, 0.6)
			yield(tween,"tween_completed")
	
	if jumper == global.persistPlayer:
		global.start_joy_vibration(0, 0.4, 0, 0.2)
		jumper.direction.x = round(jumper.direction.x)
		jumper.direction.y = round(jumper.direction.y)
		if wasRunning == true:
			wasRunning = false
			global.persistPlayer.running = true
			global.persistPlayer.tap_run = true
		global.persistPlayer.set_collision_layer_bit(0, true)
		global.persistPlayer.unpause()
		global.persistPlayer.camera.set_current()
		global.currentCamera.return_camera(0.5)
		jumper.state = jumper.MOVE
		jumping = false
		emit_signal("jump")
		global.reset_party_positions()
	else:
		jumper.animationState.travel("Idle")
		jumper.active = true
		jumper.emit_signal("actionDone")
		jumper.jumps -= 1
		if global.persistPlayer.state != global.persistPlayer.JUMPING and jumper.jumps == 0:
			jumper.set_physics_process(true)
			jumper.find_path()
	tween.queue_free()

func _on_Jump_Area_body_entered(body):
	if body == global.persistPlayer and globaldata.flags["eagle_feather"]:
		canJump = true
		global.persistPlayer.dialogue_box = false
		if globaldata.buttonPrompts == "Objects" or globaldata.buttonPrompts == "Both":
			$Tween.interpolate_property($Sprite,"position",
				$Sprite.position, arrowPos - Vector2(0, 20), 0.5,
				Tween.TRANS_QUART,Tween.EASE_OUT)
			$Tween.start()

func _on_Jump_Area_body_exited(body):
	if body == global.persistPlayer and globaldata.flags["eagle_feather"]:
		canJump = false
		global.persistPlayer.dialogue_box = true
		$Tween.interpolate_property($Sprite,"position",
			$Sprite.position, arrowPos, 0.5,
			Tween.TRANS_QUART,Tween.EASE_OUT)
		$Tween.start()

func _on_Close_body_entered(body):
	if body == global.persistPlayer and globaldata.flags["eagle_feather"] and (globaldata.buttonPrompts == "Objects" or globaldata.buttonPrompts == "Both"):
		$AnimationPlayer.play("Arrow")
		$Tween.interpolate_property($Sprite,"scale",
			$Sprite.scale, Vector2.ONE, 0.5,
			Tween.TRANS_QUART,Tween.EASE_OUT)
		$Tween.start()
		if global.persistPlayer.running == true:
			$CollisionShape2D.scale = Vector2(1.5, 1.5)
			yield(get_tree().create_timer(0.5),"timeout")
			$CollisionShape2D.scale = Vector2.ONE

func _on_Close_body_exited(body):
	if body == global.persistPlayer and globaldata.flags["eagle_feather"]:
		$Tween.interpolate_property($Sprite,"scale",
			$Sprite.scale, Vector2.ZERO, 0.5,
			Tween.TRANS_QUART,Tween.EASE_OUT)
		$Tween.start()
		yield($Tween,"tween_all_completed")
		if $Sprite.scale == Vector2.ZERO:
			$AnimationPlayer.stop()
