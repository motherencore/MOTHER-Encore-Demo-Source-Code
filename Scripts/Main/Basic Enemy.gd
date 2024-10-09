extends KinematicBody2D


signal enemy_erased

export (String) var enemy = ""
export (String) var anim = "" #animation json
export (Array, PoolStringArray) var connections = [] 
export var spriteOffset = [0, 0]
export var shadow = true
export var returning = true
export var maxDistance = 100
export var maxSpeed: int = 64
export var acceleration: int = 200
export var friction: int = 200
export var walk_frequency = 1.0


onready var eventRayCaster = $EventDetector
onready var tween = $Tween
onready var characterSprite = $CharacterSprite
onready var emotes = $CharacterSprite/emotes

var vectorSpriteOffset = Vector2.ZERO
var sprite = ""
var enemyData = []
var seeing = false
var blind = false
var underLevel = false
var drafted = false
var direction = Vector2.ZERO
var inputVector  = Vector2.ZERO
var velocity = Vector2.ZERO
var start_pos = Vector2.ZERO
var knockback = Vector2.ZERO
var newPos = null
var onScreenId = null
var startingHP = 0
var changingParents = false


enum {
	WANDER,
	RETURN
	CHASE,
	STUNNED
}
var state = WANDER

func _ready():
	if enemy != "Gorilla2OV":
		enemyData = Load_enemy_data(enemy)
		load_enemy_data()
		startingHP = enemyData["hp"]
		var highestLevel = 0
		for i in global.party.size():
			if global.party[i]["level"] > highestLevel:
				highestLevel = global.party[i]["level"]
		if highestLevel >= enemyData["level"] + 10:
			underLevel = true
		newPos = position
		characterSprite.animationTree.active = true
		set_spritesheet()
		set_physics_process(false)
		$Shadow.visible = shadow
		start_pos = position
		inputVector.x = round(rand_range(-1, 1))
		inputVector.y = round(rand_range(-1, 1))
		if walk_frequency != 0:
			$WanderRadius/Timer.wait_time = rand_range(0.1, walk_frequency)
			$WanderRadius/Timer.start()
		state = WANDER
	
func _physics_process(delta):	
	if enemy != "Gorilla2OV":
		if !global.persistPlayer.paused:
			characterSprite.animationTree.active = true
			eventRayCaster.look_at(global.persistPlayer.global_position + global.persistPlayer.get_node("CollisionShape2D").position * 2)
	#	ADVANTAGE BUG HOTFIX
			var fuckingdirectionihatethiswhyamidoingthis
			if rad2deg(atan2(direction.x, direction.y)) in [180.0, 0.0]:
				fuckingdirectionihatethiswhyamidoingthis = atan2(direction.x, direction.y) - deg2rad(90)
			elif rad2deg(atan2(direction.x, direction.y)) in [90.0, -90.0]:
				fuckingdirectionihatethiswhyamidoingthis = atan2(direction.x, direction.y) + deg2rad(90)
			elif rad2deg(atan2(direction.x, direction.y)) in [45.0, -135.0]:
				fuckingdirectionihatethiswhyamidoingthis = atan2(direction.x, direction.y) + deg2rad(180)
			else:
				fuckingdirectionihatethiswhyamidoingthis = atan2(direction.x, direction.y)
			$Position2D/BlindSpot/CollisionPolygon2D.set_rotation(fuckingdirectionihatethiswhyamidoingthis)
			$Position2D/ViewArea/CollisionPolygon2D.set_rotation(fuckingdirectionihatethiswhyamidoingthis)
			if rad2deg(fuckingdirectionihatethiswhyamidoingthis) > 0:
				$Position2D/BlindSpot/CollisionPolygon2D.set_position(Vector2(-13, 0))
				$Position2D/ViewArea/CollisionPolygon2D.set_position(Vector2(-13, 0))
			else:
				$Position2D/BlindSpot/CollisionPolygon2D.set_position(Vector2(9, 0))
				$Position2D/ViewArea/CollisionPolygon2D.set_position(Vector2(9, 0))
			if eventRayCaster.get_collider() == global.persistPlayer and position.distance_to(start_pos) <= maxDistance:
				if state != CHASE and state != STUNNED:
					if (seeing == true or (global.persistPlayer.running == true and global.persistPlayer.substantialMovement == true)) and state != CHASE and !blind:
						start_chase()
				$Timer.wait_time = 2
				$Timer.start()
			else: 
				if $Timer.time_left == 0:
					if state == CHASE:
						chase_stop()
			var oldPos = position
			match state:
				WANDER:
					if newPos != null and position != newPos:
						inputVector = position.direction_to(newPos)
						global_position = global_position.move_toward(newPos, delta * maxSpeed)
						characterSprite.travel("Walk")
					else:
						characterSprite.travel("Idle")
				RETURN:
					if $Timer.time_left == 0:
						inputVector = position.direction_to(newPos)
						position = position.move_toward(newPos, maxSpeed * delta)
						characterSprite.travel("Walk")
					if (position == newPos):
						inputVector = Vector2.ZERO
						state = WANDER
						characterSprite.travel("Idle")
				CHASE:
					if underLevel:
						inputVector = global.partyObjects[int(global.partyObjects.size()/2)].global_position.direction_to(global_position)
					else:
						inputVector = global_position.direction_to(global.partyObjects[int(global.partyObjects.size()/2)].global_position)
					if $ChaseTimer.time_left == 0:
						velocity = velocity.move_toward(inputVector * maxSpeed, acceleration * delta)
						characterSprite.travel("Walk")
			
			inputVector = round_vector(inputVector)
			
			velocity = move_and_slide(velocity)
			knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
			knockback = move_and_slide(knockback)
			
			position = round_vector(position)
			
			var newDirection = position.direction_to(newPos)
			if oldPos != position and (newDirection.x == 0 or newDirection.x == 0):
				direction = oldPos.direction_to(position)
			else:
				direction = inputVector
			#if characterSprite.offset.y == spriteOffset[1]:
			characterSprite.blend_position(direction)
		else:
			characterSprite.animationTree.active = false

func move():
	if enemy != "Gorilla2OV":
		var oldPos = position
		
		var x = position.x
		var y = position.y
		
		if randi()%2 == 1: 
			x = rand_range(start_pos.x, start_pos.x+$WanderRadius/CollisionShape2D2.shape.radius)
		else:
			y = rand_range(start_pos.y, start_pos.y+$WanderRadius/CollisionShape2D2.shape.radius)
		var travelPos = Vector2(round(x),round(y))
		$RayCast2D.enabled = true
		$RayCast2D.set_cast_to(travelPos - position)
		var ample_distance_x = travelPos.x - oldPos.x
		var ample_distance_y = travelPos.y - oldPos.y
		if !$RayCast2D.is_colliding() and (ample_distance_x > 8 or ample_distance_x <-8 or ample_distance_y > 8 or ample_distance_y <-8):
			newPos = travelPos
			inputVector = oldPos.direction_to(newPos)
		else:
			$RayCast2D.enabled = false
			move()

func jump():
	characterSprite.travel("Walk")
	tween.interpolate_property(characterSprite, "offset",
		vectorSpriteOffset, vectorSpriteOffset - Vector2(0, 5), 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.interpolate_property(characterSprite, "offset",
		vectorSpriteOffset - Vector2(0, 5), vectorSpriteOffset, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN, 0.1)
	tween.start()

func start_chase():
	if (state == WANDER or state == RETURN) and !emotes.animaPlayer.is_playing() and !global.persistPlayer.paused:
		state = CHASE
		jump()
		if underLevel:
			emotes.animaPlayer.play("blueExclamation")
		else:
			emotes.animaPlayer.play("exclamation")
		$ChaseTimer.start()

func chase_stop():
	velocity = velocity.move_toward(Vector2.ZERO, friction)
	characterSprite.travel("Idle")
	$Timer.wait_time = 1
	$Timer.start()
	if returning == true:
		state = RETURN
		newPos = start_pos
	else: 
		state = WANDER

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func _on_Timer_timeout():
	if walk_frequency != 0:
		if state == WANDER and start_pos != null and $VisibilityNotifier2D.is_on_screen():
			move()
		$WanderRadius/Timer.wait_time = rand_range(walk_frequency - 0.5,walk_frequency + 0.5)

func _on_ViewArea_body_entered(body):
	if body == global.persistPlayer:
		seeing = true

func _on_ViewArea_body_exited(body):
	if body == global.persistPlayer:
		seeing = false

func _on_BlindSpot_body_entered(body):
	if body == global.persistPlayer:
		blind = true

func _on_BlindSpot_body_exited(body):
	if body == global.persistPlayer:
		blind = false

func _on_interact_body_entered(body):
	if visible and (body.name == "player" or "PartyFollower" in body.name) and !global.cutscene:
		if global.persistPlayer.paused:
			yield(global.persistPlayer, "unpaused")
		if enemy != "":
			if underLevel and global.persistPlayer.running and global.persistPlayer.substantialMovement:
				if state != STUNNED:
					global.currentCamera.shake_camera(2, 0.2)
					global.start_joy_vibration(0, 0.5, 0.6, 0.2)
					$AudioStreamPlayer.play()
					flash(1, 0.08, 0.6, true)
					#characterSprite.offset.y = spriteOffset[1]
					tween.stop_all()
					tween.interpolate_property(characterSprite, "position",
						characterSprite.position, Vector2(0, characterSprite.position.y - 64), 0.2,
						Tween.TRANS_SINE,Tween.EASE_OUT)
					tween.interpolate_property(characterSprite, "position",
						Vector2(0, characterSprite.position.y - 64), characterSprite.position, 0.3,
						Tween.TRANS_SINE,Tween.EASE_IN, 0.3)
					tween.start() 
					state = STUNNED
					characterSprite.animationTree.active = false
					velocity = Vector2.ZERO
			elif $DamageAnimation.current_animation != "Flash":
				$interact/CollisionShape2D.set_deferred("disabled", true)
				chase_stop()
				var playerSeeing = false
				for object in global.persistPlayer.viewArea.get_overlapping_bodies():
					if object == self:
						playerSeeing = true
				drafted = true
				if playerSeeing:
					push_to_front_battle()
					if seeing:
						uiManager.start_battle(0)
					else:
						uiManager.start_battle(1)
				else:
					push_to_front_battle()
					uiManager.start_battle(2)


func _on_Hurtbox_area_entered(area):
	# not during cutscenes, or if battle already started!!
	if !global.persistPlayer.paused and !global.cutscene:
		if area.get_collision_layer_bit(1) == true or area.get_collision_layer_bit(3) == true or area.get_collision_layer_bit(7) == true:
			drafted = true
			#first strikes
			$AudioStreamPlayer.play()
			global.start_joy_vibration(0, 0.6, 0.6, 0.2)
			global.currentCamera.shake_camera(3, 0.1, global.persistPlayer.position.direction_to(position))
			var bash = load_skill_json("bash")
			var mod = global.party[0]["offense"] + global.party[0]["boosts"]["offense"]
			var defense = enemyData["defense"]
			var val = 0
			val = max(1, bash.damage + mod - (defense/2.0))
			# apply variance
			val = floor(val + (randf() * bash.variance) - bash.variance/2.0)
			val = int(round(val))
			if global.party[0].status.has(globaldata.ailments.Unconscious):
				val = int(round(val/4))
			startingHP -= val
			uiManager.create_flying_num(val, global_position)
			knockback = global.persistPlayer.direction * 120
			$DamageAnimation.play("Flash")
			yield($DamageAnimation,"animation_finished")
			$interact/CollisionShape2D.set_deferred("disabled", true)
			if startingHP <= 0:
				die(false)
			elif !global.cutscene:
				push_to_front_battle()
				uiManager.start_battle(0)
		elif area.get_collision_layer_bit(2) == true:
			#lloyd stun gun
			area.get_parent().create_spark("Explosion")
			area.get_parent().disappear()
			stun()


func _on_DamageAnimation_animation_finished(anim_name):
	if anim_name == "Stun":
		state = WANDER
		if eventRayCaster.get_collider() == global.persistPlayer:
			start_chase()
		characterSprite.animationTree.active = true

func stun():
	$DamageAnimation.play("Stun")
	state = STUNNED
	characterSprite.animationTree.active = false
	velocity = Vector2.ZERO

func flash(length = 1, interval = 0.08, delay = 0, stun = false):
	if stun:
		set_physics_process(false)
		state = STUNNED
		characterSprite.animationTree.active = false
		velocity = Vector2.ZERO
		$interact/CollisionShape2D.set_deferred("disabled", true)
	yield(get_tree().create_timer(delay),"timeout")
	for i in length / (interval * 2) :
		characterSprite.hide()
		yield(get_tree().create_timer(interval),"timeout")
		characterSprite.show()
		yield(get_tree().create_timer(interval),"timeout")
	if stun:
		state = WANDER
		set_physics_process(true)
		$interact/CollisionShape2D.set_deferred("disabled", false)
		if eventRayCaster.get_collider() == global.persistPlayer:
			start_chase()
		characterSprite.animationTree.active = true

func die(inBattle = true):
	if global.inBattle == inBattle:
		remove_battle()
		queue_free()
		emit_signal("enemy_erased")

func duplicate_sprite():
	return characterSprite.duplicate()

func set_spritesheet():
	var path = "res://Graphics/Character Sprites/Enemies/" + sprite + ".png"
	characterSprite.set_sprite(path)
	var animPath = ""
	if anim == "":
		animPath = "res://Data/Animations/BasicEnemy.json"
	else:
		animPath = "res://Data/Animations/" + anim + ".json"
	characterSprite.set_animation(animPath, connections)
	
	characterSprite.set_spritesheet()
	characterSprite.set_sprite_offset(Vector2(spriteOffset[0], spriteOffset[1]))
	vectorSpriteOffset = characterSprite.offset
#	if sprite != "" or not ResourceLoader.exists(path):
#		characterSprite.texture =  ResourceLoader.load(path)
#		if characterSprite.texture != null:
#
#			spriteOffset[1] = -characterSprite.texture.get_height()/ (characterSprite.vframes * 2) + offset
#			characterSprite.offset.y = spriteOffset[1]
#			emotes.position.y = -characterSprite.texture.get_height()/characterSprite.vframes - characterSprite.position.y
#	else:
#		characterSprite.texture = null

func Load_enemy_data(enemy_name):
	var path = "res://Data/Battlers/"+(enemy_name.replace(" ", ""))+".json"
	var enemy_file = File.new()
	enemy_file.open(path, File.READ)
	var data = enemy_file.get_as_text()
	enemy_file.close()
	return parse_json(data)

func load_skill_json(skillName: String) -> Dictionary:
	var file := File.new()
	#var json := "res://Data/BattleSkills/" + skillName + ".json"
	var skillData : Dictionary
	if skillName in globaldata.skills:
		skillData = globaldata.skills[skillName]
	else:
		skillData = globaldata.skills["bash"]
#	if file.file_exists(json):
#		file.open(json, File.READ)
#		if validate_json(file.get_as_text()) == "": # validate_json() returns empty string if valid.
#			skillData = parse_json(file.get_as_text())
#			file.close()
#		else:
#			file.close()
#			file.open("res://Data/BleSkills/yomama.json", File.READ)
#			skillData = parse_json(file.get_as_text())
#			file.close()
#			push_warning("SKILL \"" + skillName + "\" IS FORMATTED INCORRECTLY. ERRORS MAY OCCUR")
#	else:
#		file.open("res://Data/BattleSkills/yomama.json", File.READ)
#		skillData = parse_json(file.get_as_text())
#		file.close()
#		push_warning("SKILL \"" + skillName + "\" COULD NOT BE LOADED. ERRORS MAY OCCUR")
	return skillData

func _on_screen_entered():
	set_physics_process(true)
	add_battle()

func _on_screen_exited():
	remove_battle()
	set_physics_process(false)

func add_battle():
	if onScreenId == null:
		onScreenId = uiManager.onScreenEnemies.size()
		uiManager.onScreenEnemies.append([enemy, self])

func remove_battle():
	if onScreenId != null:
		if uiManager.onScreenEnemies.size() >= onScreenId + 1:
			uiManager.onScreenEnemies.remove(onScreenId)
		uiManager.update_enemy_ids()
		onScreenId = null

func push_to_front_battle():
	add_battle()
	if onScreenId != null:
		uiManager.onScreenEnemies.remove(onScreenId)
		uiManager.onScreenEnemies.push_front([enemy, self])
		onScreenId = 0
		

func activate():
	set_physics_process(true)
	show()
	emotes.show()
	startingHP = enemyData["hp"]
	velocity = Vector2.ZERO
	

func updateId(id):
	onScreenId = id

func _on_Enemy_tree_exiting():
	if !changingParents:
		die(false)

func load_enemy_data():
	if enemyData != null and enemyData.has("ov"):
		for i in enemyData["ov"]:
			set(i, enemyData["ov"][i])
		
