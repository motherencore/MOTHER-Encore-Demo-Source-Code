tool

extends Node2D

export (String, "Objects", "NPCs") var type = "Objects"
export (String, "ui_accept") var key = "ui_accept"
export var offset = Vector2.ZERO
export var enabled = true
var hidden = false

func _ready():
	reset_scale()
	if !Engine.is_editor_hint():
		hide()
		hidden = true
		set_process(false)
		set_key_name()
		global.persistPlayer.connect("event_detector_entered", self, "check_show")
		global.persistPlayer.connect("event_detector_exited", self, "check_hide")
	global.connect("inputs_changed", self, "set_key_name")
	global.connect("locale_changed", self, "set_key_name")

func _process(delta):
	position = offset
	if get_parent().get("scale") != null:
		reset_scale()

func check_show(object):
	if object == get_parent():
		show_button()

func check_hide(object):
	if object == get_parent():
		hide_button()

func reset_scale():
	position = offset
	position.x = position.x / get_parent().scale.x
	position.y = position.y / get_parent().scale.y
	scale.x = 1.0 / get_parent().scale.x
	scale.y = 1.0 / get_parent().scale.y

func set_key_name():
	$HBoxContainer/Label.text = TextTools.get_key_name(key)

func show_button(ignoreConditions = false, quick = false):
	var canShow = false
	
	if type == globaldata.buttonPrompts or globaldata.buttonPrompts == "Both":
		canShow = true
	
	if hidden and ((enabled and canShow and !global.persistPlayer.paused) or ignoreConditions):
		hidden = false
		reset_scale()
		set_key_name()
		if !quick:
			#print("show")
			$AnimationPlayer.play("Show")
		else:
			show()
			$AnimationPlayer.play("Float")

func hide_button(quick = false):
	if !hidden:
		hidden = true
		if !quick:
			#print("hide")
			$AnimationPlayer.play("Hide")
		else:
			$AnimationPlayer.stop()
			hide()

func press_button():
	if visible:
		hidden = true
		$AnimationPlayer.play("Press")
		yield($AnimationPlayer,"animation_finished")
		emit_signal("hide")


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Show" and visible:
		$AnimationPlayer.play("Float")
