extends "res://Scripts/UI/Reusables/Description.gd"

var active : bool setget , _get_active

var _is_active := false
var _is_timeout := false
var _callback: FuncRef
var _timer: Timer
var _warning_msg: String

signal closed_warning()

func _ready():
	_timer = Timer.new()
	add_child(_timer)

func _set_text_with_item(text, item_id):
	if _is_active:
		_kill_warning()
	._set_text_with_item(text, item_id)

# Override
func _update():
	._update()
	if _is_active:
		_text_label.bbcode_text = TextTools.add_line_breaks(_warning_msg, _text_label)

func warn(text, timeout = 0, callback = null):
	_is_active = true
	_warning_msg = text
	_callback = callback
	_update()
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
	_update()
	if _timer:
		_timer.stop()
