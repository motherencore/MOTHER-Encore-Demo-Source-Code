extends ControlledTwoStatesObject
class_name JumpArea

signal jump

const TWEEN_TIME := 0.5
const ARROW_FURTHER_OFFSET := - Vector2(0, 20)

export var jump_height := 20
export var player_turn := { 
	"y": true, #Make "x" true if you want the player to turn left/right when jumping
	"x": true #Make "y" true if you want the player to turn up/down when jumping
}  #Putting both to true will apply both effects and enable diagonals

var _is_player_jumping := false
var _was_player_running := false
var _is_player_nearby := false
var _is_player_inside := false

var _is_enabled := true

var _arrow_pos := Vector2.ZERO

func _ready():
	_arrow_pos = $Sprite.position
	$Sprite.scale = Vector2.ZERO

func _input(event):
	if event.is_action_pressed("ui_accept"):
		start_jump_process()

func start_jump_process():
	if _can_jump() and global.persistPlayer.state == global.persistPlayer.MOVE and !global.persistPlayer.paused and uiManager.uiStack.size() == 0:
		$Camera2D.set_current()
		if global.persistPlayer.tap_run == true:
			_was_player_running = true
		_is_player_jumping = true
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
					yield(j, "action_done")
				j.active = false
			jump(j)
			if j == global.partyObjects[0]:
				emit_signal("jump")
			else:
				yield(self, "jump")
			yield(get_tree().create_timer(0.5), "timeout")
	elif _is_player_jumping:
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
			if _is_player_jumping:
				if jumper.get("jumps") == null:
					yield(self, "jump")
				elif jumper.jumps == 1:
					yield(self, "jump")
			jumper.jump(jump_height, 0.3, true)
			tween.interpolate_property(jumper, "global_position",
				jumper.global_position, i.global_position - jumper.get_node("Shadow").position, 0.525, 
				Tween.TRANS_LINEAR,Tween.EASE_IN, 0.1)
			tween.start()
			if jumper == global.persistPlayer:
				global.start_joy_vibration(0, 0.4, 0, 0.2)
				if i.get_index() != $"Jump Points".get_child_count() -1:
					var nextPoint = $"Jump Points".get_child(i.get_index() + 1)
					global.currentCamera.move_camera((i.global_position + nextPoint.global_position) / 2 + Vector2(0, -7), 0.6)
				else:
					global.currentCamera.move_camera(i.global_position + Vector2(0, -7), 0.6)
			yield(tween,"tween_completed")
	
	if jumper == global.persistPlayer:
		global.start_joy_vibration(0, 0.4, 0, 0.2)
		jumper.direction.x = round(jumper.direction.x)
		jumper.direction.y = round(jumper.direction.y)
		if _was_player_running == true:
			_was_player_running = false
			global.persistPlayer.running = true
			global.persistPlayer.tap_run = true
		global.persistPlayer.set_collision_layer_bit(0, true)
		global.persistPlayer.unpause()
		global.persistPlayer.camera.set_current()
		global.currentCamera.return_camera(0.5)
		jumper.state = jumper.MOVE
		_is_player_jumping = false
		emit_signal("jump")
		global.reset_party_positions()
	else:
		jumper.animationState.travel("Idle")
		jumper.active = true
		jumper.emit_signal("action_done")
		jumper.jumps -= 1
		if global.persistPlayer.state != global.persistPlayer.JUMPING and jumper.jumps == 0:
			jumper.set_physics_process(true)
			jumper.find_path()
	tween.queue_free()

func _on_Jump_Area_body_entered(body):
	if body == global.persistPlayer:
		_is_player_inside = true
		_update()

func _on_Jump_Area_body_exited(body):
	if body == global.persistPlayer:
		_is_player_inside = false
		_update()
		
func _on_Close_body_entered(body):
	if body == global.persistPlayer:
		_is_player_nearby = true
		_update()
		if global.persistPlayer.running:
			$Inside/CollisionShape2D.scale = Vector2(1.5, 1.5)
			yield(get_tree().create_timer(0.5),"timeout")
			$Inside/CollisionShape2D.scale = Vector2.ONE

func _on_Close_body_exited(body):
	if body == global.persistPlayer:
		_is_player_nearby = false
		_update()

func _has_skill():
	return globaldata.flags.get("eagle_feather")

func _are_prompts_enabled():
	return globaldata.buttonPrompts in ["Objects", "Both"]

func _can_jump():
	return _is_player_inside and _has_skill() and _is_enabled

# Override
func update_state(silent: bool = false):
	yield(_update(), "completed")
	.update_state(silent)

func _update():
	_is_enabled = _get_state()
	var offset := ARROW_FURTHER_OFFSET if _is_player_inside else Vector2.ZERO
	var size := Vector2.ONE if (_is_player_nearby and _has_skill() and _is_enabled and _are_prompts_enabled()) else Vector2.ZERO
	global.persistPlayer.can_interact = !_can_jump()
	$Tween.interpolate_property($Sprite,"position",
			$Sprite.position, _arrow_pos + offset, TWEEN_TIME,
			Tween.TRANS_QUART,Tween.EASE_OUT)
	$Tween.interpolate_property($Sprite,"scale",
		$Sprite.scale, size, TWEEN_TIME,
		Tween.TRANS_QUART,Tween.EASE_OUT)
	$Tween.start()
	if _is_player_nearby:
		$AnimationPlayer.play("Arrow")
	yield($Tween,"tween_all_completed")
	if !_is_player_nearby:
		$AnimationPlayer.stop()
