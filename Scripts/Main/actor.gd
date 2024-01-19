extends KinematicBody2D

signal finished_movement
signal finished_action
signal enemy_erased

enum {MOVETO, STEP, TALKING, ROTATING, IDLE}

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var emotes = $main/emotes
onready var tween = $Tween
onready var camera = $Camera2D
onready var animationState = animationTree.get("parameters/playback")
var speed = 64
var party_member = false
var pause = false
var jumping = false
var talking = false
var moonwalk = false
var looping = false
var blendPosition = true
var animating = false
var newPos = position
var direction = Vector2.ZERO
var velocity = Vector2.ZERO
var replaced = null
var drafted = false
var state = IDLE
var idleAnim = "Idle"
var onScreenId = null

var keepAfterBattle = false

func _ready():
	hide()

#only used in animation player
func replace_npc_from_path(npcpath):
	replace_npc(global.currentScene.get_node_or_null(npcpath))

func replace_npc(npc):
	replaced = npc
	replaced.hide()
	global_position = npc.global_position
	$main.texture = replaced.get_sprite_texture()
	set_spritesheet()
	if global.talker == replaced:
		global.talker = self
	if replaced == global.persistPlayer:
		camera.set_current()
	if replaced.get("direction") != null:
		direction = replaced.direction
	else:
		direction = replaced.inputVector
	set_blending(true)
	direction = round_vector(direction)
	blend_position(direction)
	if replaced.get("idle_animation") != null:
		idleAnim = replaced.idle_animation
	animationState.travel(idleAnim)
	if !replaced.get_node("Shadow").visible:
		$Shadow.visible = false
	else:
		$Shadow.scale.x = replaced.get_node("Shadow").scale.x
	show()

func update_npcs():
	replaced.global_position = global_position
	direction = round_vector(direction)
	if replaced.get("direction") != null:
		replaced.direction = direction
	else:
		replaced.inputVector = direction
	if replaced.get("startPos") != null:
		replaced.startPos = replaced.global_position
		replaced.newPos = replaced.global_position
	if replaced.has_method("blend_position"):
		replaced.blend_position(direction)
		replaced.animationState.travel(idleAnim)
	
	if replaced == global.persistPlayer:
		global.persistPlayer.camera.set_current()
		global.persistPlayer.camera.return_camera(0.5)
		if global.partySize > 1:
			for space in global.partySpace.size():
				global.partySpace.push_front(global.persistPlayer.position)
				global.partySpace.pop_back()
	
	replaced.show()
	hide()
	global.remove_persistent(self)
	global.remove_persistent(replaced)
	queue_free()

func change_replaced(replacement):
	if replaced in global.partyObjects:
		replaced.partyMemberClass.remove(replaced.partyMember)
		global.create_party_followers()
	else:
		global.remove_persistent(replaced)
		replaced.queue_free()
	
	replaced = replacement
	replaced.hide()

func set_direction(vector2):
	direction = vector2

func _physics_process(_delta):
	match state:
		MOVETO:
			move_to(newPos)
		STEP:
			move(newPos)
		IDLE:
			if !animating:
				if jumping and party_member:
					return
				elif talking:
					animationState.travel("Talk")
				else:
					animationState.travel(idleAnim)
			position = round_vector(position)
	if moonwalk:
		blend_position(direction * Vector2(-1, -1))
	else:
		blend_position(direction)

func move_queue(moves, animation, walk_speed, type, reverse = false, loop = false):
	if state != IDLE:
		yield(self, "finished_action")
	speed = walk_speed
	moonwalk = reverse
	looping = loop
	for action in moves:
		if typeof(action) == 5:
			if type in ["position", "1"]:
				state = MOVETO
				newPos = action
			elif type == "step":
				state = STEP
				newPos = global_position + action
			if animation != "":
				animationState.travel(animation)
			yield(self, "finished_movement")
		else:
			talking = false
			state = IDLE
			if animation != "":
				animationState.travel(idleAnim)
			yield(get_tree().create_timer(float(action)),"timeout")
	if looping:
		state = IDLE
		move_queue(moves, animation, walk_speed, type, reverse, loop)
	else:
		if moonwalk:
			direction = direction * Vector2(-1, -1)
		moonwalk = false
		state = IDLE
		if animation != "":
			animationState.travel(idleAnim)
		emit_signal("finished_action")

func stop_loop():
	looping = false

func move_to(vector2):
	var difference = max(ceil(abs(speed / int(Engine.get_frames_per_second()))), 1)
	if abs(global_position.x - newPos.x) > difference or abs(global_position.y - newPos.y) > difference:
		direction = global_position.direction_to(vector2)
		velocity = move_and_slide(direction * speed)
	else:
		global_position = newPos
		emit_signal("finished_movement")

func move(vector2):
	var difference = max(ceil(abs(speed / int(Engine.get_frames_per_second()))), 1)
	if abs(global_position.x - newPos.x) > difference or abs(global_position.y - newPos.y) > difference:
		var angle = global_position.angle_to_point(vector2)
		direction = Vector2(-cos(angle), -sin(angle))
		velocity = move_and_slide(direction * speed)
	else:
		global_position = newPos
		emit_signal("finished_movement")

func set_shadow(enabled):
	$Shadow.visible = enabled

func jump(height, length, times = 1, queue = false, Shadow = true, crouch = false): #height in pixels, speed in length of jump
	if queue:
		yield(self, "finished_action")
	blend_position(direction)
	if party_member and crouch:
		jumping = true
		animationState.travel("Crouch")
		yield(get_tree().create_timer(0.1), "timeout")
		animationState.travel("Jump")
	for i in times:
		if !Shadow:
			set_shadow(false)
		tween.interpolate_property($main, "position",
			Vector2(0, -4), Vector2(0,$main.position.y - height), length * 0.6,
			Tween.TRANS_QUART,Tween.EASE_OUT)
		tween.interpolate_property($main, "position",
			Vector2(0,$main.position.y - height), Vector2(0, -4), length * 0.4,
			Tween.TRANS_QUAD,Tween.EASE_IN, length * 0.6)
		tween.start()
		yield(tween, "tween_all_completed")
		if !Shadow:
			set_shadow(true)
		if times > 1:
			if party_member and crouch:
				animationState.travel("Crouch")
			yield(get_tree().create_timer(0.1), "timeout")
			if party_member and crouch:
				animationState.travel("Jump")
	jumping = false
	emit_signal("finished_action")
	

func rotate_to(newDir, rotSpeed = 0.2, queue = false):
	newDir = round_vector(newDir.normalized())
	if queue:
		yield(self, "finished_action")
	if newDir != direction.round():
		state = ROTATING
		var angle = 45 * sign(direction.angle_to(newDir))
		while direction != newDir:
			direction = round_vector(direction.rotated(angle).round().normalized())
			blend_position(direction)
			yield(get_tree().create_timer(rotSpeed),"timeout")
		state = IDLE
		emit_signal("finished_action")

func set_spritesheet():
	var sprite = replaced.duplicate_sprite()
	$main.offset.y = sprite.offset.y
	$main.hframes = sprite.hframes
	$main.vframes = sprite.vframes
	animationTree.active = false
	if $main.hframes == 10 and $main.vframes == 20:
		animationPlayer = $"8dirAnim"
		animationTree = $"8dirTree"
		party_member = true
	elif $main.hframes == 5 and $main.vframes == 4:
		animationPlayer = $AnimationPlayer
		animationTree = $AnimationTree
	else:
		var newAnimPlayer = replaced.animationPlayer.duplicate()
		#var newAnimationTree = replaced.animationTree.duplicate()
		add_child(newAnimPlayer)
		animationPlayer = newAnimPlayer
		
		
		#animationPlayer = $AnimationPlayer
		#animationTree = $AnimationTree
		#for i in newAnimPlayer.get_animation_list():
		#	if animationPlayer.has_animation(i):
		#		animationPlayer.remove_animation(i)
		#	animationPlayer.add_animation(i, newAnimPlayer.get_animation(i))
		
	animationTree.active = true
	animationState = animationTree.get("parameters/playback")

func play_anim(anim, type = 0, anim_speed = 1.0, queue = false):
	if queue:
		yield(self, "finished_action")
	if type == 0:
		animationTree.active = true
		animationState.travel(anim)
		animating = true
	else:
		animationTree.active = false
		animationPlayer.playback_speed = anim_speed
		animationPlayer.play(anim)
		animating = true
	if anim == idleAnim:
		animating = false
		animationPlayer.playback_speed = 1.0
		emit_signal("finished_action")

func shake(offset = Vector2(1, 0), length = 1.0, queue = false):
	if queue:
		yield(self, "finished_action")
	var oldOffset = $main.offset
	if length <= 0:
		looping = true
		length = 0.1
	for i in int(length * 10):
		$main.offset = oldOffset + offset
		yield(get_tree().create_timer(0.05),"timeout")
		$main.offset = oldOffset - offset
		yield(get_tree().create_timer(0.05),"timeout")
	$main.offset = oldOffset
	if looping:
		shake(offset, -1)
	else:
		emit_signal("finished_action")

func set_blending(blend):
	blendPosition = blend

func blend_position(vector2):
	var blend = true
	vector2 = round_vector(vector2)
	if !replaced in global.partyObjects and !party_member and abs(vector2.x) - abs(vector2.y) == 0 :
		blend = false
	if vector2 != Vector2.ZERO and blend and blendPosition:
		animationTree.set("parameters/Idle/blend_position", vector2)
		animationTree.set("parameters/Blink/blend_position", vector2)
		animationTree.set("parameters/Talk/blend_position", vector2)
		animationTree.set("parameters/Walk/blend_position", vector2)
		animationTree.set("parameters/Crouch/blend_position", vector2)
		animationTree.set("parameters/Run/blend_position", vector2)
		animationTree.set("parameters/Jump/blend_position", vector2)
		animationTree.set("parameters/Bat/blend_position", vector2)
		animationTree.set("parameters/ShootPrep/blend_position", vector2)
		animationTree.set("parameters/Cast/blend_position", vector2)
		animationTree.set("parameters/CastHold/blend_position", vector2)
		animationTree.set("parameters/CastPrep/blend_position", vector2)
		animationTree.set("parameters/ShootHold/blend_position", vector2)
		animationTree.set("parameters/Shoot/blend_position", vector2)
		replaced.blend_position(vector2)

func duplicate_sprite():
	return $main.duplicate()

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func activate():
	remove_battle()
	update_npcs()

func die():
	replaced.queue_free()
	remove_battle()
	emit_signal("enemy_erased")
	queue_free()

func updateId(id):
	onScreenId = id

func remove_battle():
	if onScreenId != null:
		uiManager.onScreenEnemies.remove(onScreenId)
		uiManager.update_enemy_ids()
		onScreenId = null
