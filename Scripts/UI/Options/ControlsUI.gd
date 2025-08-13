extends PanelContainer

const Indicator = preload("res://Scripts/UI/Indicator.gd")
const DialogWindow = preload("res://Scripts/UI/Options/DialogWindow.gd")
const OptionsSwitch = preload("res://Scripts/UI/Options/OptionsSwitch.gd")

onready var tab_images = [
	preload("res://Graphics/UI/Options/controls_kbd.png"),
	preload("res://Graphics/UI/Options/controls_pad.png"),
]
onready var tab_images_on = [
	preload("res://Graphics/UI/Options/controls_kbd_hl.png"),
	preload("res://Graphics/UI/Options/controls_pad_hl.png"),
]

export (Array, NodePath) onready var tabs
export (NodePath) onready var scroll_view = get_node(scroll_view) as ScrollContainer
export (NodePath) onready var scroll_bar_view = get_node(scroll_bar_view) as EncoreScrollBar
export (Array, Array, NodePath) var control_node_paths
export (Array, NodePath) var keyboard_only_divs
export (Array, NodePath) var gamepad_only_divs
export (NodePath) onready var rumble_view = get_node(rumble_view) as Control
export (NodePath) onready var rumble_switch = get_node(rumble_switch) as OptionsSwitch
export (NodePath) onready var button_style_view = get_node(button_style_view) as Control
export (NodePath) onready var button_style_switch = get_node(button_style_switch) as OptionsSwitch
export (NodePath) onready var reset_default_view = get_node(reset_default_view) as Control
export (NodePath) onready var capture_box = get_node(capture_box) as DialogWindow
export (NodePath) onready var alert_dialog = get_node(alert_dialog) as DialogWindow
export (NodePath) onready var cursor_div = get_node(cursor_div) as Container
export (NodePath) onready var cursor = get_node(cursor) as Cursor

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"swap": load("res://Audio/Sound effects/M3/menu_open.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"restricted": load("res://Audio/Sound effects/M3/bump.wav"),
	"applied": load("res://Audio/Sound effects/M3/equip.wav"),
	"timeout": load("res://Audio/Sound effects/EB/dodge.wav"),
	"clear": load("res://Audio/Sound effects/EB/close.wav")
}

const SCROLL_MARGIN = 18
const NB_ALT_INPUTS = 2
const CAPTURE_DURATION = 2.5

# First item is for keyboard, second subarray for gamepad
#const INPUT_TYPES = [["InputEventKey"], ["InputEventJoypadButton", "InputEventJoypadMotion"]]
const INPUT_TYPES = [["InputEventKey"], ["InputEventJoypadButton"]]
const REMAPPABLE_ACTIONS = [["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "ui_toggle", "ui_scope", "ui_focus_prev", "ui_focus_next", "ui_select", "ui_fullscreen", "ui_winsize"], ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_cancel", "ui_toggle", "ui_scope", "ui_focus_prev", "ui_focus_next", "ui_select"]]
const CLONE_ACTIONS = [{"ui_up": ["ui_key_up"], "ui_down": ["ui_key_down"], "ui_left": ["ui_key_left"], "ui_right": ["ui_key_right"]}, {"ui_up": ["ui_dpad_up"], "ui_down": ["ui_dpad_down"], "ui_left": ["ui_dpad_left"], "ui_right": ["ui_kdpadright"]}]


signal exited()

var _current_tab = global.device
var _is_active = false
var _play_nav_sound = true

func _ready():
	get_viewport().connect("gui_focus_changed", self, "_on_focus_changed")
	global.connect("locale_changed", self, "_update_labels")
	capture_box.connect("closed_from_input", self, "_back_from_capture")
	capture_box.connect("closed_from_timeout", self, "_back_from_capture")
	alert_dialog.connect("closed_from_input", self, "_back_from_error_msg")
	alert_dialog.connect("closed_from_timeout", self, "_back_from_error_msg")
	scroll_view.rect_clip_content = true
	cursor.on = false
	cursor.playing = true

func activate():
	self.show()
	_is_active = true
	_set_focus_to(Vector2.ZERO)
	_set_current_tab(_current_tab)
	_update_scroll_bar()

func _update_scroll_bar():
	scroll_bar_view.update_from_scroll_view(scroll_view)

func _input(event):
	if _is_active:
		if event.is_action_pressed("ui_cancel"):
			get_tree().set_input_as_handled()
			_is_active = false
			self.hide()
			emit_signal("exited")
			audioManager.play_sfx(soundEffects["back"], "cursor")
		elif event.is_action_pressed("ui_accept"):
			get_tree().set_input_as_handled()
			var pos = _get_focused_input_pos()
			if pos != null:
				audioManager.play_sfx(soundEffects["cursor2"], "cursor")
				if pos.y < REMAPPABLE_ACTIONS[_current_tab].size():
					_is_active = false
					capture_box.start_with_timer(CAPTURE_DURATION, true)
				else:
					var focused = get_focus_owner()
					if focused == reset_default_view:
						_is_active = false
						cursor.playing = false
						var callback = funcref(self, "_back_from_confirm_reset")
						alert_dialog.start_with_options("CONTROLS_DEFAULT_CONFIRM", callback)
					else:
						_toggle_options(focused)
		elif event.is_action_pressed("ui_focus_prev"):
			get_tree().set_input_as_handled()
			audioManager.play_sfx(soundEffects["swap"], "menu")
			_set_current_tab(posmod(_current_tab - 1, INPUT_TYPES.size()))
		elif event.is_action_pressed("ui_focus_next"):
			get_tree().set_input_as_handled()
			audioManager.play_sfx(soundEffects["swap"], "menu")
			_set_current_tab(posmod(_current_tab + 1, INPUT_TYPES.size()))

func _physics_process(_delta):
	if _is_active:
		var input = controlsManager.get_controls_vector(true)
		if input != Vector2.ZERO:
			var pos = _get_focused_input_pos()
			if input.y == 0 and pos.y >= REMAPPABLE_ACTIONS[_current_tab].size():
				audioManager.play_sfx(soundEffects["cursor2"], "cursor")
				_toggle_options(get_focus_owner(), sign(input.x))
			else:
				_move_focus_by(input.x, input.y)

func _toggle_options(option_view, direction = 1):
	match option_view:
		rumble_view:
			globaldata.rumble = !globaldata.rumble
			global.start_joy_vibration(0, 0.4, 0.3, 0.3)
		button_style_view:
			globaldata.buttonsStyle = posmod(globaldata.buttonsStyle + direction, globaldata.BtnStyles.size())
			global.emit_signal("inputs_changed")
	_update_labels()

func _scroll_to(value):
	scroll_view.scroll_vertical = value
	_update_scroll_bar()

func _scroll_by(value):
	scroll_view.scroll_vertical += value
	_update_scroll_bar()

func _update_labels():
	for i in REMAPPABLE_ACTIONS[_current_tab].size():
		var action_id = REMAPPABLE_ACTIONS[_current_tab][i]
		var events = InputMap.get_action_list(action_id)
		for j in control_node_paths[i].size():
			var label = get_node(control_node_paths[i][j]).get_child(0) as Label
			var event_index = _index_of_event_in_current_mode(events, j)
			if event_index == -1:
				label.text = ""
			else:
				var event = events[event_index]
				label.text = TextTools.get_key_name_from_event(event)
	rumble_switch.text = "OPTIONS_ON" if globaldata.rumble else "OPTIONS_OFF"
	button_style_switch.text = "CONTROLS_BUTTON_STYLE_" + globaldata.BtnStyles.keys()[globaldata.buttonsStyle].to_upper()

func _set_current_tab(value):
	_current_tab = value
	_update_labels()
	_update_tab_textures()
	capture_box.allowed_input_types = INPUT_TYPES[_current_tab]
	_init_tab_content()
	# Fixing stupid inconsistent behavior from Godot
	yield(get_tree().create_timer(.01), "timeout")
	_update_scroll_bar()
	_scroll_into_view(get_focus_owner())
	_update_cursor()

func _init_tab_content():
	var divs_to_show; var divs_to_hide
	match _current_tab:
		global.KEYBOARD:
			capture_box.text = "CONTROLS_PRESS_KEY"
			divs_to_show = keyboard_only_divs
			divs_to_hide = gamepad_only_divs
		global.GAMEPAD:
			capture_box.text = "CONTROLS_PRESS_BUTTON"
			divs_to_show = gamepad_only_divs
			divs_to_hide = keyboard_only_divs
	
	for div_path in divs_to_show:
		(get_node(div_path) as Control).show()
	
	var focused_node = get_focus_owner()
	var focused_node_pos = _get_focused_input_pos()

	for div_path in divs_to_hide:
		(get_node(div_path) as Control).hide()
	
	# Find another node to focus if the current focus is about to be hidden
	while !focused_node.is_visible_in_tree():
		focused_node_pos += Vector2(0, 1)
		focused_node_pos.x = min(focused_node_pos.x, control_node_paths[focused_node_pos.y].size() - 1)
		focused_node = get_node(control_node_paths[focused_node_pos.y][focused_node_pos.x])
	
	_set_focus_to(focused_node_pos)

func _set_focus_to(node_pos: Vector2):
	_play_nav_sound = false
	var node = get_node(control_node_paths[node_pos.y][node_pos.x]) as Control
	node.grab_focus()
	_play_nav_sound = true

# Moves focus manually because Godot only handles it for ui_left/right/top/bottom default actions...
func _move_focus_by(x, y):
	if x == 0 and y == 0:
		return
	var pos = _get_focused_input_pos()
	pos.y = posmod(pos.y + y, control_node_paths.size())
	pos.x = posmod(pos.x + x, control_node_paths[pos.y].size())
	var node = get_node(control_node_paths[pos.y][pos.x]) as Control
	if node:
		if !node.is_visible_in_tree():
			_move_focus_by(x + sign(x), y + sign(y))
		else:
			node.grab_focus()

func _update_tab_textures():
	for i in tabs.size():
		(get_node(tabs[i]) as TextureRect).texture = tab_images[i] if i != _current_tab else tab_images_on[i]

func _get_focused_input_pos():
	var focused_node_path = get_path_to(get_focus_owner())
	for i in control_node_paths.size():
		var j = control_node_paths[i].find(focused_node_path)
		if j != -1:
			return Vector2(j, i)

func _on_focus_changed(control):
	if _is_active:
		if _play_nav_sound:
			audioManager.play_sfx(soundEffects["cursor1"], "cursor")
		_scroll_into_view(control)
		_update_cursor(true)
		rumble_switch.highlighted = (control == rumble_view)
		button_style_switch.highlighted = (control == button_style_view)

func _update_cursor(animate = false):
	var current_node = get_focus_owner()
	if cursor_div.is_a_parent_of(current_node):
		var was_visible = cursor.visible
		cursor.show()
		yield(get_tree(), "idle_frame")
		cursor.set_cursor_from_index(current_node.get_position_in_parent(), animate and was_visible)
	else:
		cursor.hide()

func _scroll_into_view(control):
	var control_top = control.rect_global_position.y
	var control_bottom = control_top + control.rect_size.y
	var scroll_view_top = scroll_view.rect_global_position.y
	var scroll_view_bottom = scroll_view_top + scroll_view.rect_size.y
	if control_top < scroll_view_top + SCROLL_MARGIN:
		_scroll_by(control_top - scroll_view_top - SCROLL_MARGIN)
	if control_bottom > scroll_view_bottom - SCROLL_MARGIN:
		_scroll_by(control_bottom - scroll_view_bottom + SCROLL_MARGIN)

func _reassign_listed_input(event_to_register: InputEvent, pos: Vector2, check_duplicates = true):
	var action_id = REMAPPABLE_ACTIONS[_current_tab][pos.y]
	var result = _reassign_input(event_to_register, action_id, int(pos.x), check_duplicates)
	if result:
		global.emit_signal("inputs_changed")
		_update_labels()
	return result

func _reassign_input(event_to_register: InputEvent, action_id: String, xPos: int, check_duplicates = true):
	if event_to_register is InputEvent:
		event_to_register.device = 0
	if event_to_register is InputEventKey:
		if event_to_register.scancode and event_to_register.physical_scancode:
			event_to_register.physical_scancode = 0

	var events_list = InputMap.get_action_list(action_id)

	var event_to_override = _insert_input_event_to_list(events_list, xPos, event_to_register)

	# Finding duplicates
	if check_duplicates:
		for i in REMAPPABLE_ACTIONS[_current_tab].size():
			var a_id = REMAPPABLE_ACTIONS[_current_tab][i]
			if a_id != action_id:
				var e_list = InputMap.get_action_list(a_id)
				for j in NB_ALT_INPUTS:
					var e_idx = _index_of_event_in_current_mode(e_list, j)
					if e_idx != -1 and _are_inputs_identical(event_to_register, e_list[e_idx]):
						# We’ve found a duplicate

						# But first, we must make sure we won’t remove an event that is the only one in its row...
						if event_to_override == null and _count_events_for_current_mode(e_list) <= 1:
							return false

						_insert_input_event_to_list(e_list, j, event_to_override)
						InputMap.action_erase_events(a_id)
						for event in e_list:
							InputMap.action_add_event(a_id, event)

	# Rebuilding the list of events for this action
	InputMap.action_erase_events(action_id)
	for event in events_list:
		InputMap.action_add_event(action_id, event)

	# Clone actions need to be reassigned too
	if action_id in CLONE_ACTIONS[_current_tab]:
		for clone_action in CLONE_ACTIONS[_current_tab][action_id]:
			_reassign_input(event_to_register, clone_action, xPos, false)

	return true

func _back_from_capture(input_event = null):
	_is_active = true

	if input_event != null:
		var result = _reassign_listed_input(input_event, _get_focused_input_pos())
		
		if !result:
			_is_active = false
			audioManager.play_sfx(soundEffects["restricted"], "cursor")
			alert_dialog.start("CONTROLS_PRESS_DUPLICATE_KEY" if _current_tab == global.KEYBOARD else "CONTROLS_PRESS_DUPLICATE_BUTTON")
		else:
			cursor.playing = true
			audioManager.play_sfx(soundEffects["applied"], "cursor")
	elif input_event == null:
		audioManager.play_sfx(soundEffects["timeout"], "cursor")
		if _get_focused_input_pos().x > 0:
			_reassign_listed_input(null, _get_focused_input_pos())

func _back_from_error_msg(useless_input = null):
	audioManager.play_sfx(soundEffects["cursor1"], "cursor")
	_is_active = true
	cursor.playing = true

func _back_from_confirm_reset(answer):
	_is_active = true
	cursor.playing = true
	if answer:
		audioManager.play_sfx(soundEffects["clear"], "cursor")
		InputMap.load_from_globals()
		global.emit_signal("inputs_changed")
		_update_labels()

func _insert_input_event_to_list(events_list, xPos, event):
	# Is the same event already listed in this action
	var duplicate_idx_in_same_action = -1
	for i in NB_ALT_INPUTS:
		if i != xPos:
			var check_idx = _index_of_event_in_current_mode(events_list, i)
			if check_idx != -1 and _are_inputs_identical(event, events_list[check_idx]):
				duplicate_idx_in_same_action = check_idx

	# What’s currently at this position?
	var event_index = _index_of_event_in_current_mode(events_list, xPos)
	var event_to_override
	if event_index != -1: # There is already something
		event_to_override = events_list[event_index]
		if event != null:
			events_list[event_index] = event
			if duplicate_idx_in_same_action != -1:
				events_list[duplicate_idx_in_same_action] = event_to_override
		else:
			events_list.remove(event_index)
	else: # Didn’t find any existing event => adding a new one
		if event != null:
			if duplicate_idx_in_same_action != -1:
				events_list.remove(duplicate_idx_in_same_action)
			events_list.append(event)		

	return event_to_override

func _index_of_event_in_current_mode(events_list, xPos):
	var events_counter = 0
	for i in events_list.size():
		if events_list[i].get_class() in INPUT_TYPES[_current_tab]:
			if xPos == events_counter:
				return i
			else:
				events_counter += 1
	return -1

func _count_events_for_current_mode(events_list):
	var events_counter = 0
	for i in events_list.size():
		if events_list[i].get_class() in INPUT_TYPES[_current_tab]:
			events_counter += 1
	return events_counter

func _are_inputs_identical(event1, event2):
	if event1 == null or event2 == null or event1.get_class() != event2.get_class():
		return false
	else:
		match event1.get_class():
			"InputEventKey":
				return event1.scancode == event2.scancode\
					or (event1.physical_scancode != 0 and event1.physical_scancode == event2.physical_scancode)
			"InputEventJoypadButton":
				return event1.button_index == event2.button_index
			"InputEventJoypadMotion":
				return (event1.axis == event2.axis) and (sign(event1.axis_value) == sign(event2.axis_value))
			_:
				return false
