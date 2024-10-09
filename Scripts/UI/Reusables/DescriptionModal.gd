extends "res://Scripts/UI/Reusables/Description.gd"

var _description_text

var active : bool setget , _get_active

var _is_active = false
var _is_timeout = false
var _callback: FuncRef
var _timer: Timer

signal closed_warning()

func _ready():
	_timer = Timer.new()
	add_child(_timer)

func setTextWithItem(text, itemId):
	_description_text = text
	.setTextWithItem(text, itemId)
	_kill_warning()

func warn(text, timeout = 0, callback = null):
	_is_active = true
	DescText.bbcode_text = text
	_callback = callback
	if timeout > 0:
		_is_timeout = true
		_timer.connect("timeout", self, "_on_finished")

		_timer.start(timeout)

func _get_active():
	return _is_active

func _input(event):
	if _is_active and !_is_timeout and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_tree().set_input_as_handled()
		get_tree().set_input_as_handled()
		_on_finished()

func _on_finished():
	if _is_active:
		_kill_warning()
		emit_signal("closed_warning")
		if _callback != null:
			_callback.call_funcv([])

func _kill_warning():
	_is_active = false
	_is_timeout = false
	_callback = null
	DescText.bbcode_text = _description_text
	if _timer:
		_timer.stop()
