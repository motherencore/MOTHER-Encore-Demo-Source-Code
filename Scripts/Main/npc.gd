extends KinematicBody2D

export (String) var sprite #The npc's sprite
export (String) var dialog #The normal spoken dialogue of the npc
export (String) var thoughts #The dialog spoken when using telepathy
export var appear_flag = ""
export var disappear_flag = ""
export (Array, PoolStringArray) var event_dialog
export (Array, PoolStringArray) var event_thoughts
export (Array, PoolStringArray) var event_positions
export var player_turn = { 
	"y": true, #Make "x" true if you want the player to turn left/right to face npc
	"x": true #Make "y" true if you want the player to turn up/down to face npc
}  #Putting both to true will apply both effects
export var no_problem_thoughts = false #say no problem here if read thoughts
export (bool) var automaticShadow
export (bool) var no_shadow #Turn this on to remove the npc's shadow.
export (bool) var no_collision #Turn this on to remove the npc's collisions.
export var sprite_offset = Vector2.ZERO #The offset of the sprite
export var initial_dir = Vector2.ZERO #The direction the npc is facing originally
export (String, "Idle", "Walk", "Talk") var idle_animation = "Idle" #the animation to play when idle
export var staring = false #If the npc will turn to look at the player if they get close enough
export var wander = false #If the npc walks around in the overworld
export var speed = 64 #The speed at which the npc walks
export var walk_frequency = 2 #The amount of time inbetween each set of walk
onready var main = $main
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var emotes = $main/emotes
onready var animationState = animationTree.get("parameters/playback")
var party_member = false
var pause = false
var startPos = null
var newPos = null
var talking = false
var player = null
var inputVector = Vector2.ZERO
var velocity = Vector2.ZERO
var looking = false



func _ready():
	check_flags()
	set_dialog()
	set_thoughts()
	set_event_positions()
	set_spritesheet()
	set_start_pos()
	animationTree.active = true
	animationState.travel(idle_animation)
	newPos = global_position
	if initial_dir == Vector2.ZERO:
		inputVector = Vector2(0,1)
		initial_dir = inputVector
	else:
		inputVector = initial_dir
	if automaticShadow:
		var size = float($Shadow.texture.get_width())/5
		$Shadow.scale.x = $Shadow.scale.x + float(size/10)
	if no_shadow and has_node("Shadow"):
		$Shadow.visible = false
	elif has_node("Shadow"):
		$Shadow.visible = true
	if no_collision:
		$CollisionShape2D.disabled = true

func _physics_process(_delta):
	blend_position(inputVector)
	var old_Pos = position
	if wander and newPos != null and !pause and !global.persistPlayer.paused and !global.inBattle and !global.queuedBattle:
		var difference = max(ceil(abs(speed / int(Engine.get_frames_per_second()))), 1)
		if !talking and (abs(newPos.x - position.x) > difference or abs(newPos.y - position.y) > difference) and !looking:
			inputVector = position.direction_to(newPos)
			velocity = move_and_slide(inputVector * speed)
			if (abs(old_Pos.x - position.x) > 0.5 or abs(old_Pos.y - position.y) > 0.5):
				animationState.travel("Walk")
			else:
				animationState.travel(idle_animation)
				global_position = round_vector(global_position)
		else:
			animationState.travel(idle_animation)
			global_position = round_vector(global_position)
	else:
		animationState.travel(idle_animation)
	if looking and !talking and (abs(old_Pos.x - position.x) < 1 or abs(old_Pos.y - position.y) < 1):
		inputVector = global_position.direction_to(global.persistPlayer.global_position)
	if uiManager.uiStack.size() == 0:
		talking = false
		pause = false
	else:
		if talking == true and animationTree.get("parameters/Talk/blend_position") != null:
			animationState.travel("Talk")
		else:
			animationState.travel("Idle")

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func interact():
	set_dialog()
	global.talker = self
	pause = true
	newPos = position
	inputVector = global_position.direction_to(global.persistPlayer.global_position)
	animationTree.set("parameters/Talk/blend_position", inputVector)
	global.set_dialog(dialog, self) 
	uiManager.open_dialogue_box()
	global.persistPlayer.pause()

func telepathy():
	set_thoughts()
	pause = true
	newPos = position
	inputVector = global_position.direction_to(global.persistPlayer.global_position)
	animationTree.set("parameters/" + idle_animation + "/blend_position", inputVector)
	global.set_dialog(thoughts, null) 
	uiManager.open_dialogue_box()
	uiManager.set_telepathy_effect(true, self)
	global.persistPlayer.pause()
	

func duplicate_sprite():
	return $main.duplicate()

func blend_position(vector2):
	vector2 = round_vector(vector2)
	if vector2 != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", vector2)
		animationTree.set("parameters/Walk/blend_position", vector2)
		animationTree.set("parameters/Talk/blend_position", vector2)

func set_spritesheet():
	if sprite != "null":
		if !"Npcs" in sprite:
			party_member = true
		var sprite_path = "res://Graphics/Character Sprites/" + sprite + "/main.png"
		if (sprite != "" or " ") and ResourceLoader.exists(sprite_path):
			$main.texture = load(sprite_path)
			if $main.texture != null:
				animationTree.active = false
				if party_member:
					$main.offset.y = -$main.texture.get_height()/40 + 14
					$main.offset += sprite_offset
					$main.hframes = 10
					$main.vframes = 20
					$interact/ButtonPrompt.offset.y =  -$main.texture.get_height()/40 + 4
					animationPlayer = $PartyMemberAnim
					animationTree = $PartyMemberTree
				elif "4dir" in sprite:
					$main.offset.y = -$main.texture.get_height()/8 + 13
					$main.offset += sprite_offset
					$main.hframes = 5
					$main.vframes = 4
					$interact/ButtonPrompt.offset.y =  -$main.texture.get_height()/8 + 4
					animationPlayer = $AnimationPlayer
					animationTree = $AnimationTree
				animationTree.active = true
				animationState = animationTree.get("parameters/playback")
			if no_shadow:
				$Shadow.visible = false
			else:
				$Shadow.visible = true
			show()
		else:
			hide()

func get_sprite_texture():
	return $main.texture

func set_start_pos():
	startPos = global_position

func set_dialog():
	for flags in event_dialog:
		var flag = flags[0]
		var newdialog = flags[1]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					dialog = newdialog

func set_thoughts():
	for flags in event_thoughts:
		var flag = flags[0]
		var newthought = flags[1]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					thoughts = newthought

func set_event_positions():
	for flags in event_positions:
		var flag = flags[0]
		var newpositionx = flags[1]
		var newpositiony = flags[2]
		if flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag]:
					global_position = Vector2(float(newpositionx), float(newpositiony))

func check_flags():
	if appear_flag != "":
		if globaldata.flags.has(appear_flag):
			if globaldata.flags[appear_flag]:
				show()
			else:
				hide()
	if disappear_flag != "":
		if globaldata.flags.has(disappear_flag):
			if globaldata.flags[disappear_flag]:
				hide()
	if !visible:
		queue_free()


func _on_ViewArea_body_entered(body):
	if body == global.persistPlayer and staring:
		looking = true


func _on_ViewArea_body_exited(body):
	if body == global.persistPlayer and staring:
		looking = false
		if !wander:
			get_tree().create_timer(1).connect("timeout", self, "return_to_init_dir")

func return_to_init_dir():
	if !looking:
		inputVector = initial_dir

func _on_Timer_timeout():
	if self != null:
		if wander and startPos != null and looking == false and pause == false:
			move()
		$WanderRadius/Timer.wait_time = rand_range(walk_frequency - 0.5,walk_frequency + 0.5)

func move():
	var oldPos = position
	
	var x = position.x
	var y = position.y
	
	if randi()%2 == 1: 
		x = rand_range(startPos.x - $WanderRadius/CollisionShape2D2.shape.radius/2, startPos.x + $WanderRadius/CollisionShape2D2.shape.radius/2)
	else:
		y = rand_range(startPos.y - $WanderRadius/CollisionShape2D2.shape.radius/2, startPos.y + $WanderRadius/CollisionShape2D2.shape.radius/2)
	var travelPos = Vector2(round(x),round(y))
	$RayCast2D.enabled = true
	$RayCast2D.set_cast_to(travelPos - position)
	var ample_distance_x = abs(travelPos.x - oldPos.x)
	var ample_distance_y = abs(travelPos.y - oldPos.y)
	if (ample_distance_x > 8 or ample_distance_y > 8):
		if $RayCast2D.get_collider() == null:
			newPos = travelPos
			inputVector = oldPos.direction_to(newPos)
	else:
		move()

func _on_VisibilityNotifier2D_screen_entered():
	if !global.cutscene:
		set_process(true)
		set_spritesheet()
		show()
		if wander:
			$WanderRadius/Timer.wait_time = rand_range(0.1,walk_frequency)
			$WanderRadius/Timer.start()

func _on_VisibilityNotifier2D_screen_exited():
	if !global.cutscene:
		set_process(false)
		hide()
		if wander:
			$WanderRadius/Timer.stop()

func _on_npc_tree_exiting():
	if !self in global.persistArray:
		$WanderRadius/Timer.stop()
