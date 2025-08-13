class_name AbstractDialogueBox
extends Node

const SPEED_UP_FROM_PRESS_A := 3
const SPEED_UP_FROM_PRESS_B := 1000

onready var _dialogue_box_node: Node
onready var _dialogue_label: RichTextLabel
onready var _bullet_label: RichTextLabel
onready var _cursor_down_sprite: AnimatedSprite

var _speed_multiplier_from_input := 1
var _speed_multiplier_from_tags := 1
var _bullet_string := "[right]%s[/right]" % tr("SYMBOL_BULLET_MAIN") # Diamond-shaped bullet in Japanese

var _dialog := {}
var _curr_phrase := {}
var _phrase_num := 0
var _segment_num := 0
var _stopped := false
var _finished := true
var _auto_advance := false
var _t := 0.0

func _physics_process(delta):
	_advance_printing(delta)

# Overridden
func start_from_scripted_dialog(dialog := {}, is_battle_msg := false):
	_show_box(true)
	_bullet_label.visible = !is_battle_msg
	if dialog:
		_dialog = dialog
	
	_dialogue_label.visible_characters = 0
	_handle_phrase()
	yield(self, "done")

# Overridden
func _show_box(show, sfx = true):
	if show:
		_dialogue_box_node.show()
		set_process_input(true)
		set_physics_process(true)
	if !show:
		set_process_input(false)
		set_physics_process(false)
		_dialogue_box_node.hide()

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
		var btn_next = event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")
		var btn_cancel = event.is_action_pressed("ui_cancel")
		_action_press(btn_next, btn_cancel)

# Overridden
func _action_press(btn_next := false, btn_cancel := false):
	if !_finished and !_stopped:
		if btn_cancel:
			_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_B
		else:
			_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_A
	elif btn_next:
		if _finished:
			next_phrase()
		elif _stopped:
			_stopped = false

# Overridden
func _handle_phrase():
	pass

func _print_dialogue_segment(is_first_segment: bool):
	var with_bullet := false
	if is_first_segment:
		_segment_num = 0
	else:
		_segment_num += 1
	var curr_segment = _curr_phrase["text"].split("\n")[_segment_num]
	if curr_segment.begins_with(TextTools.CHAR_BULLET):
		with_bullet = true
		curr_segment = curr_segment.substr(1)
	_dialogue_label.bbcode_text += "\n" + curr_segment
	_update_bullets(curr_segment, with_bullet)

# Overridden
func next_phrase():
	if _curr_phrase.has("goto"):
		_phrase_num = str2var(_curr_phrase["goto"])
		_handle_phrase()
	else:
		_end_dialogue()

# Overridden
func _advance_printing(delta):
	if !_finished and !_stopped:
		_t += delta
		_cursor_down_sprite.hide()
		while _t > _get_text_speed() and !_finished and !_stopped:
			_dialogue_label.visible_characters += 1
			if _dialogue_label.visible_characters > len(_get_no_br_dialog_content()):
				if _has_remaining_segments():
					_print_dialogue_segment(false)
				else:
					_finish_phrase()
			var last_visible_char = _get_last_visible_char()
			if $AudioStreamPlayer.stream != null and last_visible_char != TextTools.CHAR_DELAY:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85, 1.0))
				$AudioStreamPlayer.play()
			_t -= _get_text_speed()
			match last_visible_char:
				TextTools.CHAR_WAIT: _stop_phrase()
				TextTools.CHAR_PRINTING_FASTER: _speed_multiplier_from_tags *= 2
				TextTools.CHAR_PRINTING_NORMAL: _speed_multiplier_from_tags = 1
	else:
		_speed_multiplier_from_tags = 1

	if _dialogue_label.visible_characters >= len(_get_no_br_dialog_content()):
		$AudioStreamPlayer.stop()

func _get_no_br_dialog_content() -> String:
	return _dialogue_label.text.replace("\n", "")

func _get_last_visible_char() -> String:
	var spaceless_text = _get_no_br_dialog_content()
	if spaceless_text == "":
		return ""
	return spaceless_text[min(_dialogue_label.visible_characters, spaceless_text.length()) - 1]

func _get_text_speed() -> float:
	return globaldata.textSpeed / _speed_multiplier_from_input / _speed_multiplier_from_tags

func _stop_phrase():
	_stopped = true
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1
	_cursor_down_sprite.show()

# Overridden
func _finish_phrase():
	pass

# Overridden
func _end_dialogue():
	pass

func _has_remaining_segments() -> bool:
	return _curr_phrase.has("text") && _segment_num < _curr_phrase["text"].count("\n")

func _update_bullets(line, add_bullet = false):
	_bullet_label.bbcode_text += "\n"
	if add_bullet:
		_bullet_label.bbcode_text += _bullet_string
	line = TextTools.strip_bbcode(line)
	var font = _dialogue_label.get_font("normal_font")
	var lineSize = font.get_wordwrap_string_size(line, _dialogue_label.rect_size.x)
	if lineSize.y > font.get_height():
		_bullet_label.bbcode_text += "\n".repeat(int(floor(lineSize.y/font.get_height()) - 1))
