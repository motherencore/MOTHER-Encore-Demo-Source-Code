extends Control

export (String, "ui_focus_prev", "ui_focus_next") var key
export (int) var size_before_growing = 44

onready var anim = $AnimationPlayer
onready var hbox = $AnimContainer/HBoxContainer
onready var label = $AnimContainer/HBoxContainer/Label
onready var arrow = $AnimContainer/HBoxContainer/Arrow

func _ready():
	hbox.margin_left = - size_before_growing / 2 + 1
	hbox.margin_right = size_before_growing / 2

	global.connect("inputs_changed", self, "_on_inputs_changed")
	global.connect("locale_changed", self, "_on_inputs_changed")
	if key == "ui_focus_next":
		arrow.flip_h = false
		hbox.move_child(label, 0)
		if self.grow_horizontal in [Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_END]:
			hbox.grow_horizontal = Control.GROW_DIRECTION_END
		else:
			hbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		anim.play("Idle")
	elif key == "ui_focus_prev":
		arrow.flip_h = true
		hbox.move_child(label, 1)
		if self.grow_horizontal in [Control.GROW_DIRECTION_BOTH, Control.GROW_DIRECTION_BEGIN]:
			hbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		else:
			grow_horizontal = Control.GROW_DIRECTION_END
		anim.play_backwards("Idle")
	set_key_name()

func set_key_name():
	label.text = globaldata.get_key_name(key)

func _on_Indicator_visibility_changed():
	set_key_name()

func _on_inputs_changed():
	set_key_name()
