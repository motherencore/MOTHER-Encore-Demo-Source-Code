extends "res://Scripts/UI/Reusables/Description.gd"

onready var cursor = $arrow

var open : bool setget , _get_open

var _callback: FuncRef
var _cbParams: Array
var _cbOnlyForYes: bool

signal closed()

func _ready():
	cursor.connect("selected", self, "_on_selected")
	cursor.connect("cancel", self, "_on_cancel")
	self.hide()

func ask(questionStr, itemId, callback, cbParams, cbOnlyForYes = false):
	setTextWithItem(questionStr, itemId)
	_callback = callback
	_cbParams = cbParams
	_cbOnlyForYes = cbOnlyForYes
	self.show()
	cursor.on = true

func _get_open():
	return cursor.on

func _on_cancel():
	_on_answer(false)

func _on_selected(selection):
	_on_answer(selection == 0)

func _on_answer(answerIsYes):
	self.hide()
	cursor.on = false
	emit_signal("closed")

	if _callback != null:
		if _cbOnlyForYes:
			if answerIsYes: 
				_callback.call_funcv(_cbParams)
		else:
			_cbParams.append(answerIsYes)
			_callback.call_funcv(_cbParams)

