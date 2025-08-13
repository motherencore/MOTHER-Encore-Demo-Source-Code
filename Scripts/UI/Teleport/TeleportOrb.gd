extends Node2D

signal entered
signal left

export (NodePath) onready var _anim = get_node(_anim) as AnimationPlayer

func play_enter_animation():
	_anim.play("OrbEnter")

func play_leave_animation():
	_anim.play("OrbLeave")

func connect_signal(signal_id, receiver, method):
	self.connect(signal_id, receiver, method)

func disonnect_signal(signal_id, receiver, method):
	self.disconnect(signal_id, receiver, method)

func _on_anim_entered():
	emit_signal("entered");

func _on_anim_left():
	emit_signal("left");
