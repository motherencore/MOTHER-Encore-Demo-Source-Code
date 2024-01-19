extends Node2D

export var flag = ""
export var New_parent : NodePath
export var called_object : NodePath
export var call_object_function = ""
export var object_function_disappear_flag = ""

onready var animationPlayer = $AnimationPlayer
onready var sprite = $Sprite
onready var visibilityNotifier = $VisibilityNotifier2D
onready var newParent = get_node_or_null(New_parent)
onready var calledObject = get_node_or_null(called_object)


func _ready():
	visibilityNotifier.connect("screen_entered", self, "show")
	visibilityNotifier.connect("screen_exited", self, "hide")
	hide()
	
	#make bush appear only when the flag is true
	if globaldata.flags.has(flag):
		if !globaldata.flags[flag]:
			animationPlayer.play("Hidden")
		else:
			animationPlayer.play("Idle")
	else:
		animationPlayer.play("Idle")
	
	if New_parent == null:
		newParent = get_parent()

func grow():
	Input.start_joy_vibration(0, 0.5, 0.7, 0.8)
	animationPlayer.play("Grow")
	yield(animationPlayer, "animation_finished")
	animationPlayer.play("Idle")

func interact():
	if visible:
		if globaldata.flags["bat"]:
			global.set_dialog("Reusable/easytobreak", null) 
		else:
			global.set_dialog("Reusable/hardtobreak", null) 
		uiManager.open_dialogue_box()

func _on_Hitbox_area_entered(area):
	var Roots = sprite.duplicate()
	Roots.frame = 1
	newParent.add_child(Roots)
	Roots.position = sprite.global_position
	global.persistPlayer.hit_stop(0.09, 0.5, false, 0.35, "Bat")
	animationPlayer.play("Break")
	$AudioStreamPlayer.play()
	$interact/ButtonPrompt.enabled = false
	$interact/ButtonPrompt.hide_button()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Break" and globaldata.flags.has(object_function_disappear_flag):
		if calledObject != null and call_object_function != "" and !globaldata.flags[object_function_disappear_flag]:
			calledObject.call_deferred(call_object_function)
		queue_free()
