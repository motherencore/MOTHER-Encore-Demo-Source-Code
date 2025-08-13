extends Control

onready var tween = $CanvasLayer/Tween
onready var fade = $CanvasLayer/Fade
onready var door = $Objects/DoorToTitle

func _init():
	if OS.has_feature("dialogue_tester"):
		global.goto_scene("res://Maps/Testing/DialogueTester.tscn")

func _ready():
	global.persistPlayer.pause()
	tween.interpolate_property(fade, "modulate",
		fade.modulate, Color.transparent, 3,
		Tween.TRANS_QUART, Tween.EASE_IN_OUT)
	tween.start()

func _input(event):
	if (event is InputEventKey or event is InputEventJoypadButton) and event.pressed:
		if OS.is_debug_build():
			for action in InputMap.get_actions():
				if (event is InputEventKey and event.is_action_pressed(action) and
					(action in ["ui_load", "ui_translate", "ui_F12"] or event.alt)):
					return
		door.enter()
