extends KinematicBody2D

signal event_detector_entered(object)
signal event_detector_exited(object)

enum {
	MOVE,
	ATTACK_PREP,
	ATTACK,
	CAMERA,
	JUMPING
}

const SPEED_WALKING = 64
const SPEED_RUNNING = 96

const PAUSABLE_FLASH_ANIMS = ["Flash"]

var partyMember = globaldata.ninten
var state = MOVE
var PK_type = 0 
var direction = Vector2.ZERO
var knockback = Vector2.ZERO
var hitdirect = Vector2.ZERO
var inputVector  = Vector2.ZERO
var velocity = Vector2.ZERO
var speed: int = SPEED_WALKING
var walk = false
var damaging = false
var _attack_damage = 0
var _damage_variation = 0
var substantialMovement : bool
var costume = "Normal"
var run_sound = "wood"
var crouch = false
var tap_run = false
var running = false
var dialogue_box = true
var climbing = false
var _spinning = false
var _switching = false
var _spin_num = 0
var _switch = "None"
var _idle = false
var _event_collider = null


onready var sprite = $Position/main
onready var special = $SpecialAnimations
onready var animationPlayer = $AnimationPlayer
onready var flashAnim = $FlashAnim
onready var animationTree = $AnimationTree
onready var _collision = $CollisionShape2D
onready var animationState = animationTree.get("parameters/playback")
onready var eventRayCaster = $EventDetector
onready var Laser = preload("res://Nodes/Reusables/Overlap/Laser.tscn")
onready var Cast = preload("res://Nodes/Reusables/Overlap/PKOV.tscn")
onready var LaserSpark = preload("res://Nodes/Reusables/Overlap/LaserSpark.tscn")
onready var Dust = preload("res://Nodes/Overworld/Dust.tscn")
onready var emotes = $Position/main/emotes
onready var camera = $Camera2D
onready var tween = $Tween
onready var bat = $HitboxPivot/BatHitbox/CollisionShape2D
onready var viewArea = $EventDetector/ViewArea
onready var timer = $Timer
onready var _after_image_creator = $AfterImageCreator


export (int) var spriteSize_X = 10
export (int) var spriteSize_Y = 10
export (bool) var paused = false

signal paused
signal unpaused

func _ready():
	global.currentCamera = camera
	for i in global.partySpace.size():
		global.partySpace.push_front(position)
		global.partySpace.pop_back()
	animationTree.active = true
	tap_run = false
	crouch = false
	direction = Vector2(0,1)
	blend_position(direction)
	set_ripple(false)
	
	var sfx = load("res://Audio/Sound effects/Footsteps/" + run_sound + ".mp3")
	audioManager.add_sfx(sfx, "run")

# warning-ignore:unused_argument
func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		
		ATTACK_PREP:
			attack_hold()
		
		CAMERA:
			_controls()
			if inputVector != Vector2.ZERO:
				blend_position(camera.offset)
				travel_fainted("Idle", "FaintedIdle")
	
	
	
	
	if state != MOVE:
		set_running(false)

	if damaging == true and !paused:
		knockback = hitdirect * 50
		if $FlashAnim.get_current_animation() != "Flash":
			var damage = _attack_damage + int(rand_range(-_damage_variation, _damage_variation))
			camera.shake_camera(1, 0.2, Vector2(1, 0))
			global.start_joy_vibration(0, 0.6, 0.8, 0.1)
			global.party_call("play_flash_anim", "Flash")
			audioManager.play_sfx(load("res://Audio/Sound effects/Hurt 1.mp3"), "damage")
			if !global.party[0]["status"].has(globaldata.ailments.Unconscious):
				global.party[0]["hp"] -= damage
				uiManager.create_flying_num(damage, global_position)
				if global.party[0]["hp"] <= 0:
					global.party[0]["hp"] = 0
					global.party[0]["status"].clear()
					global.party[0]["status"].append(globaldata.ailments.Unconscious)
					if global.get_conscious_party() == []:
						game_over()
	knockback = knockback.move_toward(Vector2.ZERO, 200)


func move_state(delta):
	if !paused:
		
		if globaldata.buttonPrompts != "None":
			check_eventCollider()
		
		_controls()
		_movement(delta)
		if Input.is_action_just_pressed("ui_cancel") and !climbing and !_spinning and \
			((global.party[0] == globaldata.ninten and globaldata.flags["bat"]) or \
			(global.party[0] == globaldata.lloyd and globaldata.flags["laser"]) or \
			(global.party[0] == globaldata.ana)):
			
			if global.party[0] == globaldata.ninten:
				state = ATTACK
				crouch = false
				_idle = false
				tap_run = false
				set_running(false)
				walk = false
				attack_unleash()
			else:
				if global.party[0] == globaldata.lloyd:
					if global.currentScene.get_node("Objects").get_node_or_null("Laser") == null:
						$AimTime.start()
					else:
						return
				state = ATTACK_PREP
				crouch = false
				_idle = false
				tap_run = false
				set_running(false)
				walk = false
			if global.party[0] == globaldata.ana:
				animationState.travel("Cast")
				$PKTime.wait_time = 0.733
				$PKTime.start()
				$OutlineAnim.play("Flash")
		if Input.is_action_just_pressed("ui_scope", true) and !damaging:
			set_running(false)
			pause()
			state = CAMERA
			travel_fainted("Idle", "FaintedIdle")
			substantialMovement = false
			walk = false
	else:
		travel_fainted("Idle", "FaintedIdle")
		if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").playing:
			audioManager.get_sfx("run").stop()

func _controls():
	inputVector = controlsManager.get_controls_vector()

func move():
	if tap_run == true:
		velocity = direction * speed
	else:
		velocity = inputVector * speed
	
	if inputVector != Vector2.ZERO:
		direction = inputVector
		eventRayCaster.rotation = direction.angle() - TAU/4

func _movement(delta):
	if inputVector != Vector2.ZERO or tap_run == true:
		move()
		
		if _spinning == false:
			blend_position(direction)
			
		if climbing == true:
			animationPlayer.playback_speed = 1
		else:
			travel_fainted("Walk", "FaintedWalk")
			animationTree.set("parameters/FaintedWalk/TimeScale/scale", 1)
		if Input.is_action_pressed("ui_toggle") or tap_run == true:
			if  Input.is_action_just_pressed("ui_toggle") and crouch == false and running == false and climbing == false:
				crouch = true
			if Input.is_action_just_pressed("ui_toggle") and tap_run == true:
				tap_run = false
				set_running(false)
			if !paused and substantialMovement:
				set_running(true)
			travel_fainted("Run", "FaintedWalk")
			animationTree.set("parameters/FaintedWalk/TimeScale/scale", 2)
			speed = SPEED_RUNNING
		else:
			speed = SPEED_WALKING
			crouch = false
			if Input.is_action_just_released("ui_toggle") and !tap_run:
				set_running(false)
	else:
		velocity = Vector2.ZERO
		walk = false
		if Input.is_action_just_released("ui_toggle") and crouch == true:
			crouch = false
			speed = SPEED_RUNNING
			tap_run = true
			
			velocity = direction * speed

	var oldpos = self.position
	velocity = move_and_slide(velocity * delta * (speed/1.7))
	knockback = move_and_slide(knockback)
	if abs(velocity.x) > 0.1 or abs(velocity.y) > 0.1 or abs(knockback.x) > 0.1 or abs(knockback.y) > 0.1:
		substantialMovement = true
		_idle = false
	else:
		substantialMovement = false
	if substantialMovement:
		walk = true
		crouch = false
		update_party_positions(oldpos)
		if running == true and timer.time_left == 0:
			timer.start()
			if !climbing:
				dust()
				#if !$AudioStreamPlayer.playing:
				#	$AudioStreamPlayer.playing = true
	else:
		travel_fainted("Idle", "FaintedIdle")
		walk = false
		tap_run = false
		set_running(false)
		if climbing == true:
			animationPlayer.playback_speed = 0
		if Input.is_action_just_pressed("ui_toggle") and crouch == false:
			crouch = true
		elif Input.is_action_just_pressed("ui_toggle") and crouch == true:
			crouch = false
		if crouch == true:
			animationState.travel("Crouch")
		else:
			if $BlinkTime.time_left == 0:
				if _idle == false or _spinning:
					travel_fainted("Idle", "FaintedIdle")
					$BlinkTime.wait_time = 10 + randf()*5
					$BlinkTime.start()
				else:
					travel_fainted("Blink", "FaintedIdle")
	position = round_vector(position)
	
	var canClimb = true
	for i in global.partyObjects:
		if i.climbing:
			canClimb = false
	if canClimb and globaldata.flags["switch_leader"] and global.party.size() != 1 and globaldata.flags["switch_leader"]:
		if Input.is_action_just_pressed("ui_focus_next"):
			crouch = false
			_switching = true
			spin(8,45,0.015)
			_switch = "next"
		if Input.is_action_just_pressed("ui_focus_prev"):
			crouch = false
			_switching = true
			spin(8,-45,0.015)
			_switch = "prev"
		if _switching == true and _spinning == true and _spin_num == 4:
			match _switch:
				"next":
					global.party.push_back(global.party.pop_front())
				"prev":
					global.party.push_front(global.party.pop_back())
			for i in global.partyObjects:
				if i != self:
					i.set_partyMember()
				i._spritesheet()
	if Input.is_action_just_pressed("ui_accept") and !paused and dialogue_box and eventRayCaster.is_colliding():
		if crouch:
			use_telepathy()
		else:
			interact_with()
	

#emits a signal when the EventDetector detects a new object or when an object exits it
func check_eventCollider():
	var collide = eventRayCaster.get_collider()
	
	if _event_collider != collide:
		#print("_event_collider: " + str(_event_collider))
		#print("collide: " + str(collide))
	
		if collide != null:
			if !collide.is_connected("tree_exited", self, "set_eventCollider"):
				collide.connect("tree_exited", self, "set_eventCollider", [null])
			#print("Event collider entered: " + str(collide.name))
			emit_signal("event_detector_entered", collide)
		
		if _event_collider != null:
			if _event_collider.is_connected("tree_exited", self, "set_eventCollider"):
				_event_collider.disconnect("tree_exited", self, "set_eventCollider")
			#print("Event collider exited: " + str(_event_collider.name))
			emit_signal("event_detector_exited", _event_collider)
	
	_event_collider = collide


func set_eventCollider(collider):
	_event_collider = collider

func interact_with():
	if uiManager.uiStack.size() == 0:
		set_eventCollider(null)
		var collide = eventRayCaster.get_collider()
		if collide != null:
			if "interact" in collide.name:
				var collided = collide.get_parent()
				
				if collide.has_method("interact"):
					if collide.get("player_turn") != null:
						turn_to(collide, true)
					collide.interact()
				elif collided.has_method("interact"): 
					if collided.get("player_turn") != null:
						turn_to(collided, true)
					collided.interact()
				if collide.get_node_or_null("ButtonPrompt") != null:
					print("pressed :3")
					collide.get_node_or_null("ButtonPrompt").press_button()
			else:
				global.set_dialog("noproblem", null)
				uiManager.open_dialogue_box()
				pause()
		else:
			global.set_dialog("noproblem", null)
			uiManager.open_dialogue_box()
			pause()

func use_telepathy():
	if uiManager.uiStack.size() == 0 and global.party[0] in [globaldata.ninten, globaldata.ana]:
		set_eventCollider(null)
		var collide = eventRayCaster.get_collider()
		if collide != null:
			var collided = collide.get_parent()
			if collided.has_method("telepathy"): 
				if collided.thoughts != "":
					if collided.get("player_turn") != null:
						turn_to(collided, true)
					uiManager.set_telepathy_effect(true, collided)
					collided.telepathy()
				else:
					if collided.no_problem_thoughts:
						global.set_dialog("noproblem", null)
					else:
						global.set_dialog("Reusable/straythoughts", null) 
					uiManager.open_dialogue_box()
					pause()
			elif collide.has_method("telepathy"):
				if collide.thoughts != "":
					if collide.get("player_turn") != null:
						turn_to(collide, true)
					collide.telepathy()
				else:
					global.set_dialog("noproblem", null)
					uiManager.open_dialogue_box()
					pause()
			else:
				global.set_dialog("Reusable/nothoughts", null) 
				uiManager.open_dialogue_box()
				pause()
			
			if collide.get_node_or_null("ButtonPrompt") != null:
				if collide.get_node_or_null("ButtonPrompt").type == "NPCs":
					collide.get_node_or_null("ButtonPrompt").press_button()
		else:
			global.set_dialog("Reusable/nothoughts", null) 
			uiManager.open_dialogue_box()
			pause()

func _spritesheet():
	var texPathP1 := "res://Graphics/Character Sprites/"
	var texPathP2 := "/main.png"
	var textPathP3 := "/special.png"
	var texPathP4 := "Snow"
	var fullTextPath := str(texPathP1 + global.party[0]["sprite"] + texPathP2)
	var fullTextPath2 := str(texPathP1 + global.party[0]["sprite"] + textPathP3)
	var fullSnowPath := str(texPathP1 + global.party[0]["sprite"] + texPathP4 + texPathP2)
	partyMember = global.party[0]
	if ResourceLoader.exists(fullTextPath) and sprite.texture.resource_path != fullTextPath:
		if ResourceLoader.exists(fullTextPath2):
			special.texture = ResourceLoader.load(fullTextPath2)
		if global.persistPlayer.costume == "Snow" and ResourceLoader.exists(fullSnowPath):
				sprite.texture = ResourceLoader.load(fullSnowPath)
		else:
			sprite.texture = ResourceLoader.load(fullTextPath)
		$Position/main.offset.y = -$Position/main.texture.get_height()/40 + 14
		#print("Player sprite should now be: ", fullTexPath)
	elif not ResourceLoader.exists(fullTextPath):
		sprite.texture = ResourceLoader.load("res://Graphics/Character Sprites/Ninten/main.png")


func blend_position(vector2):
	if vector2 != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", vector2)
		animationTree.set("parameters/Blink/blend_position", vector2)
		animationTree.set("parameters/Walk/blend_position", vector2)
		animationTree.set("parameters/FaintedIdle/blend_position", vector2)
		animationTree.set("parameters/FaintedWalk/FaintedWalk/blend_position", vector2)
		animationTree.set("parameters/Crouch/blend_position", vector2)
		animationTree.set("parameters/Run/blend_position", vector2)
		animationTree.set("parameters/Jump/blend_position", vector2)
		animationTree.set("parameters/Bat/Bat/blend_position", vector2)
		animationTree.set("parameters/ShootPrep/blend_position", vector2)
		animationTree.set("parameters/Cast/blend_position", vector2)
		animationTree.set("parameters/CastHold/blend_position", vector2)
		animationTree.set("parameters/CastPrep/blend_position", vector2)
		animationTree.set("parameters/ShootHold/blend_position", vector2)
		animationTree.set("parameters/Shoot/blend_position", vector2)
		

func turn_to(target, cardinal):
	var rel_position = target.global_position - global_position
	if cardinal and target.get("player_turn") != null:
		if (abs(rel_position.x) > abs(rel_position.y) or !target.player_turn.y) and rel_position.x != 0 and target.player_turn.x:
			direction = Vector2(sign(rel_position.x),0)
		elif target.player_turn.y and rel_position.y != 0:
			direction = Vector2(0,sign(rel_position.y))
	else:
		direction = rel_position
	animationTree.set("parameters/Idle/blend_position", direction)
	travel_fainted("Idle", "FaintedIdle")
	

func attack_hold():
	var old_dir = direction
	_controls()
	if inputVector != Vector2.ZERO:
		set_direction(inputVector)
	if global.party[0] == globaldata.lloyd and global.currentScene.get_node("Objects").get_node_or_null("Laser") == null:
		animationState.travel("ShootHold")
		if $AimTime.time_left == 0 and old_dir != direction:
			camera.move_offset(direction.x * 30, direction.y * 20, 0.3)
	elif global.party[0] == globaldata.ana:
		animationState.travel("CastHold")
	elif global.party[0] == globaldata.teddy:
		state = MOVE
	else:
		state = MOVE
		
	if Input.is_action_just_released("ui_cancel"):
		state = ATTACK
		attack_unleash()

func attack_unleash():
	if global.party[0]== globaldata.ninten:
		$AudioStreamPlayer.stream = load("res://Audio/Sound effects/Ninten Bat.mp3")
		$AudioStreamPlayer.play()
		global.start_joy_vibration(0, 0.35, 0, 0.2)
		animationState.travel("Bat")
		if global.party[0].status.has(globaldata.ailments.Unconscious):
			animationTree.set("parameters/Bat/TimeScale/scale", 0.7)
		else:
			animationTree.set("parameters/Bat/TimeScale/scale", 1)
	elif global.party[0]["sprite"] == "Lloyd":
		animationState.travel("Shoot")
		camera.return_offset(0.4)
	elif global.party[0]["sprite"] == "Ana":
		animationState.travel("Cast")
		$OutlineAnim.play("Normal")
		$PKTime.stop()
	elif global.party[0]["sprite"] == "Teddy":
		state = MOVE
	else:
		state = MOVE

func attack_animation_finished():
	$HitboxPivot/BatHitbox/CollisionShape2D.disabled = true
	state = MOVE
	tap_run = false

func hit_stop(length, camShake, pause = false, timeScale = 0.0, animation = ""):
	var oldTimeScale = 1
	if animation != "":
		oldTimeScale = animationTree.get("parameters/" + animation + "/TimeScale/scale")
		animationTree.set("parameters/"+ animation +"/TimeScale/scale", timeScale)
	if pause:
		get_tree().paused = true
	
	if length != 0 and !camera.shaking:
		if camShake != 0:
			camera.shake_camera(camShake, 0.1, Vector2(1, 0))
		
		yield(get_tree().create_timer(float(length)), "timeout")
	
	if pause:
		get_tree().paused = false
	if animation != "":
		animationTree.set("parameters/"+ animation +"/TimeScale/scale", oldTimeScale)

func dust():
	var dust = Dust.instance()
	global.currentScene.get_node("Objects").add_child(dust)
	dust.position.x = self.position.x + round(rand_range(-3,2))
	dust.position.y = self.position.y + round(rand_range(-3,2))
	dust.position.y = dust.position.y - 0.01 * global.party.size()
	
	dust.get_node("AnimationPlayer").play("Dusty")
	yield(dust.get_node("AnimationPlayer"),"animation_finished")
	dust.queue_free()




func shoot():
	var La = Laser.instance()
	global.currentScene.get_node("Objects").add_child(La)
	var laser = La.get_node("LaserHead")
	laser.animationTree.set("parameters/shoot/blend_position", direction)
	laser.global_position = $HitboxPivot/BulletSpawn.global_position
	laser.inputVector = direction
	laser.rotation = $HitboxPivot/BulletSpawn.global_rotation
	laser.animationState.travel("shoot")
	La.show()

func cast():
	var ini_dir = direction
	var ini_pos = $HitboxPivot/BulletSpawn.global_position
	var wait = Timer.new()
	wait.set_wait_time(0.067)
	wait.set_one_shot(true)
	self.add_child(wait)
	for i in 3 :
		var Pk = Cast.instance()
		if ini_dir.x != 0:
			Pk.position = (ini_pos + (Vector2(30 * i,30 * i) * ini_dir.normalized()))
		else:
			Pk.position = (ini_pos + (Vector2(30 * i,25 * i) * ini_dir.normalized()))
		global.currentScene.get_node("Objects").add_child(Pk)
		wait.start()
		yield(wait, "timeout")
	
	wait.queue_free()

func jump(height, length, hideShadow):
	state = JUMPING
	blend_position(direction)
	animationState.travel("Crouch")
	yield(get_tree().create_timer(0.1), "timeout")
	animationState.travel("Jump")
	if hideShadow:
		$Shadow.hide()
	tween.interpolate_property($Position/main, "scale",
		 Vector2(0.9,1.1), Vector2(1,1), length,
		Tween.TRANS_QUART,Tween.EASE_OUT, 0.02)
	tween.interpolate_property($Position, "position",
		Vector2(0,0), Vector2(0,-height), length,
		Tween.TRANS_QUART,Tween.EASE_OUT)
	tween.interpolate_property($Position, "position",
		Vector2(0,-height), Vector2(0,0), length*0.75,
		Tween.TRANS_QUAD,Tween.EASE_IN, length)
	tween.start()
	yield(tween, "tween_all_completed")
	if hideShadow:
		$Shadow.show()

func spin(times, angle, rot_speed):
	_spinning = true
	_spin_num = 0
	var dir = round_vector(direction)
	for n in times:
		_spin_num += 1
		dir = round_vector(dir.rotated(angle))
		blend_position(dir)
		yield(get_tree().create_timer(rot_speed),"timeout")
	_switching = false
	_spinning = false

func rotate_to(newDir, rot_speed):
	newDir = round_vector(newDir.normalized())
	direction = round_vector(direction)
	var angle = 45 * sign(direction.angle_to(newDir))
	while direction != newDir:
		direction = round_vector(direction.rotated(angle).round().normalized())
		blend_position(direction)
		yield(get_tree().create_timer(rot_speed),"timeout")
	

func damage(Damage, DamageVariation = 0, Hitdirect = Vector2.ZERO, Status = null):
	damaging = true
	_attack_damage = Damage
	_damage_variation = DamageVariation
	hitdirect = Hitdirect
	if Status != null and !global.party[0]["status"].has(Status) and !global.party[0]["status"].has(globaldata.ailments.Unconscious):
		global.party[0]["status"].append(Status)

func undamage():
	damaging = false

func game_over():
	pause()
	uiManager.game_over()

func ladder():
	animationTree.active = false
	animationPlayer.play("Ladder")
	animationPlayer.playback_speed = 0
	climbing = true
	state = MOVE
	if audioManager.get_sfx("run") != null:
		audioManager.get_sfx("run").stop()

func unladder():
	animationTree.active = true
	animationPlayer.stop()
	travel_fainted("Idle", "FaintedIdle")
	$Position.position.y = 0
	$Shadow.visible = true
	climbing = false
	if running:
		set_running(true)

func set_ripple(enabled):
	$Shadow.visible = !enabled
	$Ripple.visible = enabled

func travel_fainted(anim, faintanim):
	if !climbing:
		if global.party[0].status.has(globaldata.ailments.Unconscious):
			animationState.travel(faintanim)
		else:
			animationState.travel(anim)

func set_running(enabled):
	running = enabled
	if !paused and state == MOVE:
		if enabled and !climbing:
			var sfx = load("res://Audio/Sound effects/Footsteps/" + run_sound + ".mp3")
			if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").stream == sfx:
				if !audioManager.get_sfx("run").playing :
					audioManager.get_sfx("run").play()
			else:
				audioManager.play_sfx(sfx, "run")
	if audioManager.get_sfx("run") != null and audioManager.get_sfx("run").playing and !enabled:
		audioManager.get_sfx("run").stop()

func pause():
	global.party_call("pause_flash_anim")
	global.party_call("stop_creating_afterimage")
	crouch = false
	tap_run = false
	walk = false
	state = MOVE
	paused = true
	inputVector = Vector2.ZERO
	$AudioStreamPlayer.playing = false
	$AudioStreamPlayer.stream_paused = true
	set_running(false)
	_set_collision_masks(false)
	emit_signal("paused")

func unpause():
	$AudioStreamPlayer.stream_paused = false
	global.party_call("resume_flash_anim")
	paused = false
	_set_collision_masks(true)
	emit_signal("unpaused")
	if running:
		set_running(true)

func exit_camera():
	state = MOVE
	unpause()
	blend_position(direction)
	travel_fainted("Idle", "FaintedIdle")

func _set_collision_masks(enabled):
	set_collision_mask_bit(0, enabled)
	set_collision_mask_bit(8, enabled)

# Duplicated in party.gd
func set_all_collisions(value):
	_collision.disabled = !value

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func _on_BlinkTime_timeout():
	_idle = true

func _on_PKTime_timeout():
	PK_type += 1
	if PK_type > 2:
		PK_type = 0
	match PK_type:
		0:
			$EffectsAnim.play("Fire")
		1:
			$EffectsAnim.play("Freeze")
		2:
			$EffectsAnim.play("Thunder")
	$OutlineAnim.play("Flash")
	$PKTime.wait_time = 1
	$PKTime.start()

func _on_OutlineAnim_animation_finished(anim_name):
	if anim_name == "Flash":
		match PK_type:
			0:
				$OutlineAnim.play("Fire")
			1:
				$OutlineAnim.play("Freeze")
			2:
				$OutlineAnim.play("Thunder")

func duplicate_sprite():
	return $Position/main.duplicate()

func duplicate_special():
	return $SpecialAnimations.duplicate()

func get_sprite_texture():
	return $Position/main.texture

func _on_AimTime_timeout():
	if state == ATTACK_PREP:
		camera.move_offset(direction.x * 30, direction.y * 20, 0.3)

func set_direction(newDir):
	direction = newDir
	blend_position(newDir)

func update_party_positions(oldpos, multiplier = 1):
	var maxDist = round(max(abs(oldpos.x-self.position.x), abs(oldpos.y-self.position.y)) * multiplier)
	for i in maxDist:
		global.partySpace.push_front(lerp(oldpos, position.round(), (i+1)/maxDist))
		global.partySpace.pop_back()

# Duplicated in party.gd
func play_flash_anim(anim):
	flashAnim.play(anim)

# Duplicated in party.gd
func pause_flash_anim():
	if flashAnim.get_current_animation() in PAUSABLE_FLASH_ANIMS:
		flashAnim.stop(false)
	else:
		flashAnim.play("RESET")

# Duplicated in party.gd
func resume_flash_anim():
	if flashAnim.get_assigned_animation() in PAUSABLE_FLASH_ANIMS \
	and flashAnim.get_current_animation_position() > 0 and flashAnim.get_current_animation_position() < flashAnim.get_current_animation_length():
		flashAnim.play(flashAnim.get_assigned_animation())

func start_creating_afterimage():
	_after_image_creator.start_creating()

func stop_creating_afterimage():
	_after_image_creator.stop_creating()

