extends Control

export (String, "ui_focus_prev", "ui_focus_next") var key

onready var label = $MarginContainer/HBoxContainer/Label
onready var arrow = $MarginContainer/HBoxContainer/Arrow

func _ready():
	if key == "ui_focus_next":
		arrow.flip_h = false
		$MarginContainer/HBoxContainer.move_child(label, 0)
		$AnimationPlayer.play("Idle")
	elif key == "ui_focus_prev":
		arrow.flip_h = true
		$MarginContainer/HBoxContainer.move_child(label, 1)
		$AnimationPlayer.play_backwards("Idle")
	set_key_name()

func set_key_name():
	label.text = globaldata.get_key_name(key)

func _on_Indicator_visibility_changed():
	set_key_name()
