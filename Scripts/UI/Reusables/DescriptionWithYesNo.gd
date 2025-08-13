extends "res://Scripts/UI/Reusables/Description.gd"

onready var cursor = $arrow

var open : bool setget , _get_open

var _callback: FuncRef
var _cb_params: Array
var _cb_only_for_yes: bool

signal closed()

func _ready():
	cursor.connect("selected", self, "_on_selected")
	cursor.connect("cancel", self, "_on_cancel")
	self.hide()

func ask(question_str: String, item_id: String, callback: FuncRef, cb_params: Array, cb_only_for_yes := false):
	_set_text_with_item(question_str, item_id)
	_callback = callback
	_cb_params = cb_params
	_cb_only_for_yes = cb_only_for_yes
	self.show()
	cursor.on = true

func _get_open():
	return cursor.on

func _on_cancel():
	_on_answer(false)

func _on_selected(selection):
	_on_answer(selection == 0)

func _on_answer(answer_is_yes: bool):
	self.hide()
	cursor.on = false
	emit_signal("closed")

	if _callback != null:
		if _cb_only_for_yes:
			if answer_is_yes: 
				_callback.call_funcv(_cb_params)
		else:
			_cb_params.append(answer_is_yes)
			_callback.call_funcv(_cb_params)

