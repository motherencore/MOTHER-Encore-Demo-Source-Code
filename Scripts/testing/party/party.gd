extends KinematicBody2D

signal actionDone
export (int) var spacing = 20
var currentSpace = 20
enum {
	FOLLOW,
	GO
}

const PAUSABLE_FLASH_ANIMS = ["Flash"]

var inputVector := Vector2.ZERO
var lastPos := Vector2.ZERO
var directionMultiplier := Vector2.ONE
var delay = 0.2
var speed: int = 1
var followerIdx : int = 1 #should be at least 1, since player is 0.
var partyMember = globaldata.ninten
var partyMemberClass = global.party
var damaged = false
var idle = true
var attack_damage = 0
var damage_variation = 0
var active = true
var spinning = false
var start_run = true
var climbing = false
var jumps = 0
var walk_type = FOLLOW
onready var sprite = $Position/main
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var _collision = $CollisionShape2D
onready var Dust = preload("res://Nodes/Overworld/Dust.tscn")
onready var dust_time = $Dust_time
onready var after_image_creator = $AfterImageCreator
onready var flashAnim = $FlashAnim


func initiate():
	lastPos = position
	currentSpace = spacing
	if position != global.partySpace[currentSpace-1]:
		set_direction(position.direction_to(global.partySpace[currentSpace-1]))
	else:
		set_direction(global.persistPlayer.direction)
	animationTree.active = true
	set_partyMember()
	set_ripple(false)
	_spritesheet()

func _physics_process(_delta):
	if global.partySpace[spacing] != null and active:
		var player = global.persistPlayer
		var old_pos = round_vector(position)
		if !(abs(position.x - global.partySpace[spacing].x) > 2 or abs(position.y - global.partySpace[spacing].y) > 2): #and directionMultiplier == Vector2.ONE:
			walk_type = FOLLOW
			#if currentSpace < spacing:
			#	currentSpace = spacing 
		if walk_type == GO :
			position = position.move_toward(global.partySpace[currentSpace], 4000)
			#if position == global.partySpace[currentSpace]:
			if !player.paused:
				currentSpace -= speed
			
			if currentSpace < spacing:
				currentSpace = spacing
				walk_type = FOLLOW
			#if !player.walk and !player.paused:
			#	currentSpace -= 1
		else:
			if currentSpace < spacing and player.walk:
				currentSpace += 1 
				if player.running:
					currentSpace += 1
			position = global.partySpace[currentSpace]
		$Timer.wait_time = delay
		if old_pos != round_vector(position): #(position.direction_to(global.partySpace[currentSpace-1]) != Vector2.ZERO and player.walk) or 
			inputVector = position.direction_to(global.partySpace[currentSpace-1])
			idle = false
			if !spinning:
				blend_position(inputVector)
			if climbing == true:
				animationPlayer.playback_speed = 1
			else:
				travel_fainted("Walk", "FaintedWalk")
				animationTree.set("parameters/FaintedWalk/TimeScale/scale", 1)
				$BlinkTime.stop()
			if player.running == true or walk_type == GO:
				travel_fainted("Run", "FaintedWalk")
				animationTree.set("parameters/FaintedWalk/TimeScale/scale", 2)
				if start_run == true:
					dust_time.wait_time = 0.083 * followerIdx
					dust_time.start()
					start_run = false
				if start_run == false and dust_time.time_left == 0:
					dust_time.wait_time = 0.25
					dust_time.start()
					if !climbing:
						dust()
			else: 
				dust_time.wait_time = 0.083 * followerIdx
				start_run = true
			if modulate == Color(1, 1, 1, 0):
				appear()
		else:
			if climbing == true:
				animationPlayer.playback_speed = 0
			elif $BlinkTime.time_left == 0:
				if idle == false or spinning:
					travel_fainted("Idle", "FaintedIdle")
					$BlinkTime.wait_time = 10 * followerIdx + randf()*5
					$BlinkTime.start()
				else:
					travel_fainted("Blink", "FaintedIdle")
			dust_time.wait_time = 0.083 * followerIdx
			start_run = true
		
		if player.crouch == true:
			travel_fainted("Crouch", "FaintedIdle")
		
		if damaged == true and $FlashAnim.get_current_animation() != "Flash" and !global.persistPlayer.paused:
			var damage = attack_damage + int(rand_range(-damage_variation, damage_variation))
			$FlashAnim.play("Flash")
			travel_fainted("Idle", "FaintedIdle")
			audioManager.play_sfx(load("res://Audio/Sound effects/Hurt 1.mp3"), "damage")
			if !partyMember["status"].has(globaldata.ailments.Unconscious) and partyMember["maxhp"] != 0:
				partyMember["hp"] -= damage
				uiManager.create_flying_num(damage, global_position)
				if partyMember["hp"] <= 0:
					partyMember["hp"] = 0
					partyMember["status"].clear()
					partyMember["status"].append(globaldata.ailments.Unconscious)
				if global.get_conscious_party() == []:
					global.persistPlayer.game_over()
		
		if walk_type == FOLLOW:
			self.position.x = round(self.position.x)
			self.position.y = round(self.position.y) - global.partyObjects.find(self) * 0.01
		else:
			self.position.y = round(self.position.y)
	else:
		travel_fainted("Idle", "FaintedIdle")
		
	var canClimb = true
	for i in global.partyObjects:
		if i.climbing:
			canClimb = false
	if global.persistPlayer.state == global.persistPlayer.MOVE and !global.persistPlayer.paused and canClimb and globaldata.flags["switch_leader"] and global.party.size() != 1 and partyMemberClass == global.party:
		if Input.is_action_just_pressed("ui_focus_next"):
			spin(8,45,0.015)
		if Input.is_action_just_pressed("ui_focus_prev"):
			spin(8,-45,0.015)

func disappear():
	modulate = Color(1, 1, 1, 0)

func appear():
	$Tween.interpolate_property(self, "modulate",
	Color(0, 0, 0, 0), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR)
	$Tween.start()
	_spritesheet()

func find_path(runSpeed = 2):
	walk_type = GO
	speed = runSpeed
	for i in global.partySpace.size() - spacing:
		var space = spacing + i
		if global.partySpace.size() > space:
			if position.distance_to(global.partySpace[space]) < position.distance_to(global.partySpace[currentSpace]):
				currentSpace = space

func set_spacing(space):
	spacing = followerIdx * space

func set_ripple(enabled):
	$Shadow.visible = !enabled
	$Ripple.visible = enabled

func set_partyMember():
	var idx := followerIdx
	if partyMemberClass == global.partyNpcs:
		idx -= global.party.size()
	if idx >= 0:
		partyMember = partyMemberClass[idx]

func _spritesheet():
	var texPathP1 := "res://Graphics/Character Sprites/"
	var texPathP2 := "/main.png"
	var texPathP4 := "Snow"
	var fullTexPath := str(texPathP1 + partyMember["sprite"] + texPathP2)
	var fullSnowPath := str(texPathP1 + partyMember["sprite"] + texPathP4 + texPathP2)
	if ResourceLoader.exists(fullTexPath) and sprite.texture.resource_path != fullTexPath:
		if global.persistPlayer.costume == "Snow" and ResourceLoader.exists(fullSnowPath):
			sprite.texture = ResourceLoader.load(fullSnowPath)
		else:
			sprite.texture = ResourceLoader.load(fullTexPath)
			travel_fainted("Idle", "FaintedIdle")
		$Position/main.vframes = 20
		$Position/main.offset.y = -$Position/main.texture.get_height()/40 + 14
	elif not ResourceLoader.exists(fullTexPath):
		sprite.texture = ResourceLoader.load("res://Graphics/Character Sprites/Ninten/main.png")

func _on_Timer_timeout():
	pass

func spin(times, angle, rot_speed):
	spinning = true
	var dir = round_vector(inputVector)
	var wait = Timer.new()
	wait.set_wait_time(rot_speed)
	wait.set_one_shot(true)
	self.add_child(wait)
	for n in times:
		dir = round_vector(dir.rotated(angle))
		blend_position(dir)
		wait.start()
		yield(wait,"timeout")
	spinning = false
	wait.queue_free()

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func damage(Damage, DamageVariation = 0, _Hitdirect = Vector2.ZERO, Status = null):
	damaged = true
	attack_damage = Damage
	damage_variation = DamageVariation
	if Status != null and !partyMember["status"].has(Status) and !partyMember["status"].has(globaldata.ailments.Unconscious):
		partyMember["status"].append(Status)

func undamage():
	damaged = false

func travel_fainted(anim, faintanim):
	if partyMember.status.has(globaldata.ailments.Unconscious):
		animationState.travel(faintanim)
	else:
		animationState.travel(anim)

func dust():
	var dust = Dust.instance()
	global.currentScene.get_node("Objects").add_child(dust)
	dust.position.x = self.position.x + round(rand_range(-3,2))
	dust.position.y = self.position.y + round(rand_range(-3,2))
	dust.position.y = dust.position.y - 0.01 * global.partyObjects.size()
	dust.get_node("AnimationPlayer").play("Dusty")
	yield(dust.get_node("AnimationPlayer"),"animation_finished")
	dust.queue_free()
	
func ladder():
	animationTree.active = false
	animationPlayer.play("Ladder")
	animationPlayer.playback_speed = 0
	climbing = true

func unladder():
	animationTree.active = true
	animationPlayer.stop()
	travel_fainted("Idle", "FaintedIdle")
	$Position.position.y = 0
	$Shadow.visible = true
	climbing = false

func jump(height, jump_speed, hideShadow):
	idle = false
	blend_position(inputVector)
	animationState.travel("Crouch")
	yield(get_tree().create_timer(0.1), "timeout")
	animationState.travel("Jump")
	if hideShadow:
		$Shadow.hide()
	$Tween.interpolate_property($Position/main, "scale",
		 Vector2(0.9,1.1), Vector2(1,1), jump_speed,
		Tween.TRANS_QUART,Tween.EASE_OUT, 0.02)
	$Tween.interpolate_property($Position, "position",
		Vector2(0,0), Vector2(0,-height), jump_speed,
		Tween.TRANS_QUART,Tween.EASE_OUT)
	$Tween.interpolate_property($Position, "position",
		Vector2(0,-height), Vector2(0,0), jump_speed*0.75,
		Tween.TRANS_QUAD,Tween.EASE_IN, jump_speed)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	if hideShadow:
		$Shadow.show()

func blend_position(vector2):
	if Vector2(vector2.x * directionMultiplier.x, vector2.y * directionMultiplier.y) != Vector2.ZERO:
		vector2.x = vector2.x * directionMultiplier.x
		vector2.y = vector2.y * directionMultiplier.y
	if vector2 != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", vector2)
		animationTree.set("parameters/Blink/blend_position", vector2)
		animationTree.set("parameters/Walk/blend_position", vector2)
		animationTree.set("parameters/FaintedIdle/blend_position", vector2)
		animationTree.set("parameters/FaintedWalk/FaintedWalk/blend_position", vector2)
		animationTree.set("parameters/Crouch/blend_position", vector2)
		animationTree.set("parameters/Run/blend_position", vector2)
		animationTree.set("parameters/Jump/blend_position", vector2)

func get_sprite_texture():
	return $Position/main.texture

func _on_BlinkTime_timeout():
	idle = true

func duplicate_sprite():
	return $Position/main.duplicate()

func set_direction(newDir):
	inputVector = newDir
	blend_position(newDir)

# Duplicated in Player.gd
func set_all_collisions(value):
	_collision.disabled = !value

# Duplicated in Player.gd
func play_flash_anim(anim):
	flashAnim.play(anim)

# Duplicated in Player.gd
func pause_flash_anim():
	if flashAnim.get_current_animation() in PAUSABLE_FLASH_ANIMS:
		flashAnim.stop(false)
	else:
		flashAnim.play("RESET")

# Duplicated in Player.gd
func resume_flash_anim():
	if flashAnim.get_assigned_animation() in PAUSABLE_FLASH_ANIMS \
	and flashAnim.get_current_animation_position() > 0 and flashAnim.get_current_animation_position() < flashAnim.get_current_animation_length():
		flashAnim.play(flashAnim.get_assigned_animation())

func start_creating_afterimage():
	after_image_creator.start_creating()

func stop_creating_afterimage():
	after_image_creator.stop_creating()

func rotate_to(newDir, rot_speed):
	newDir = round_vector(newDir)
	var angle = 45 * sign(inputVector.angle_to(newDir))
	while inputVector != newDir:
		inputVector = round_vector(inputVector.rotated(angle))
		blend_position(inputVector)
		yield(get_tree().create_timer(rot_speed),"timeout")
