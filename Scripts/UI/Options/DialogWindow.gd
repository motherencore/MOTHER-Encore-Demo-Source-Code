extends PanelContainer

signal closed_from_input(input)
signal closed_from_answer(answer)
signal closed_from_timeout()

export (NodePath) onready var label_view
export (NodePath) onready var time_bar_container_view
export (NodePath) onready var options_view
export (NodePath) onready var time_bar_view
export (NodePath) onready var cursor = get_node(cursor) as Cursor
export (NodePath) onready var tween = get_node(tween) as Tween
export (Array, String) var allowed_input_types = ["InputEventKey", "InputEventJoypadButton", "InputEventJoypadMotion"]

export (String) var text setget _set_text
export (bool) var show_time_bar = false setget _set_show_time_bar
export (bool) var show_options = false setget _set_show_options

var _callback: FuncRef
var _registered_input: InputEvent
var _is_closing: bool = false

func _ready():
	tween.connect("tween_all_completed", self, "_on_timed_out")
	global.connect("locale_changed", self, "_on_locale_changed")
	get_node(time_bar_container_view).visible = show_time_bar

func _set_text(value):
	text = value
	get_node(label_view).text = value

func _set_show_time_bar(value):
	show_time_bar = value
	if is_instance_valid(get_node(time_bar_container_view)):
		get_node(time_bar_container_view).visible = value

func _set_show_options(value):
	show_options = value
	if is_instance_valid(get_node(options_view)):
		get_node(options_view).visible = value
		cursor.visible = value
		cursor.on = value
		yield(get_tree().create_timer(.01), "timeout")
		cursor.set_cursor_from_index(0, false)

func _on_locale_changed():
	yield(get_tree(), "idle_frame")
	cursor.set_cursor_from_index(0, false)

func start(with_text, duration = 0):
	_set_text(with_text)
	_set_show_time_bar(false)
	_set_show_options(false)
	show()

func start_with_options(with_text, callback = null):
	_set_text(with_text)
	_callback = callback
	_set_show_time_bar(false)
	_set_show_options(true)
	show()

func start_with_timer(duration = 0, with_show_time_bar = show_time_bar, with_text = text):
	_set_text(with_text)
	_set_show_time_bar(with_show_time_bar)
	_set_show_options(false)
	show()
	if duration > 0:
		tween.interpolate_property(get_node(time_bar_view), "anchor_right", 1, 0, duration)
		tween.start()

func _input(event):
	if visible:
		if event.is_pressed():
			get_tree().set_input_as_handled()
			if show_options:
				if event.is_action_pressed("ui_accept"):
					var answer = cursor.cursor_index == 0
					if !answer:
						cursor.play_sfx("cursor2")
					emit_signal("closed_from_answer", answer)
					if _callback:
						_callback.call_funcv([answer])
					finish()

				if event.is_action_pressed("ui_cancel"):
					cursor.play_sfx("cursor1")
					emit_signal("closed_from_answer", false)
					if _callback:
						_callback.call_funcv([false])
					finish()
			else:
				if event.get_class() in allowed_input_types and event.device == 0 and globaldata.is_key_allowed(event):
					tween.stop_all()
					_registered_input = event
					# We need to defer the window closing until the key is released or it will cause problem if we reaffect the action
					_is_closing = true

func _physics_process(delta):
	if _is_closing and _is_input_released(_registered_input):
		finish()
		emit_signal("closed_from_input", _registered_input)
		_is_closing = false

func _is_input_released(input):
	if input is InputEventKey:
		return !Input.is_key_pressed(input.scancode) and !Input.is_physical_key_pressed(input.physical_scancode)
	elif input is InputEventJoypadButton:
		return !Input.is_joy_button_pressed(input.device, input.button_index)
	elif input is InputEventJoypadMotion:
		return Input.get_joy_axis(input.device, input.axis) == 0

func _on_timed_out():
	finish()
	emit_signal("closed_from_timeout")

func finish():
	_set_show_time_bar(false)
	_set_show_options(false)
	tween.stop_all()
	hide()
