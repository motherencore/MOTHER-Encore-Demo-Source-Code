extends Control

class_name BattleMenuBox

onready var cursor = get_node_or_null("Arrow")

signal next()

var action

func _ready():
	if cursor != null:
		cursor.connect("selected", self, "select")
		cursor.connect("moved", self, "move")
		cursor.connect("failed_move", self, "fail_move")
	else:
		print("cursor is null!")

func enter(reset, _action = null):
	if _action != null:
		action = _action
	show()
	if cursor != null:
		cursor.on = true

func exit():
	hide()

func hide():
	.hide()
	if cursor != null:
		cursor.on = false

func fail_move(dir: Vector2):
	pass

func move(dir: Vector2):
	pass

func select(i: int):
	pass
