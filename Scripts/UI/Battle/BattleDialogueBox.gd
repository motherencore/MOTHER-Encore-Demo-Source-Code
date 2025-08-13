extends AbstractDialogueBox

signal done

const AUTO_ADVANCE_DELAY := 1.25

var _method_target = self

var _is_cutscene := false
var _is_waiting_between_phrases := false

func _ready():
	_dialogue_box_node = self
	_dialogue_label = $ClipBox/HBoxContainer/Dialogue
	_bullet_label = $ClipBox/HBoxContainer/DippinDots
	_cursor_down_sprite = $Cursor_Down
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_show_box(false, false)

func start_from_string(dialog_string: String):
	yield(start_from_array([dialog_string]), "completed")

func start_from_array(dialog_array: Array):
	var dialog := {}
	for i in dialog_array.size():
		dialog[str(i)] = {"text": TextTools.add_line_breaks(dialog_array[i], _dialogue_label)}
		if i < dialog_array.size() - 1:
			dialog[str(i)].goto = str(i + 1)
	yield(start_from_scripted_dialog(dialog), "completed")

func append(dialog_string: String, sfx := ""):
	var new_entry := {"text": TextTools.add_line_breaks(dialog_string, _dialogue_label)}
	if sfx:
		new_entry["soundeffect"] = sfx
	var latest_idx := -1
	for idx in _dialog.keys():
		if int(idx) > latest_idx:
			latest_idx = int(idx)
	if latest_idx > -1:
		_dialog[str(latest_idx)]["goto"] = str(latest_idx + 1)
	_dialog[str(latest_idx + 1)] = new_entry

func start_from_appended():
	if _dialog:
		yield(start_from_scripted_dialog(_dialog), "completed")
	else:
		call_deferred("_end_dialogue")
		yield(self, "done")

# Override
func start_from_scripted_dialog(dialog := {}, is_battle_msg := true):
	_is_cutscene = !is_battle_msg
	$AnimationPlayer.play("RESET")
	yield(.start_from_scripted_dialog(dialog, is_battle_msg), "completed")

# Override
func _handle_phrase():
	$Arrow.position = Vector2(104,43)
	_curr_phrase = _dialog[str(_phrase_num)]
	
	_finished = false
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1

	if _phrase_num == 0:
		_dialogue_label.remove_line(1)
		_bullet_label.remove_line(1)

	if _curr_phrase["text"] != "":
		if _is_cutscene:
				_curr_phrase["text"] = TextTools.replace_text(_curr_phrase["text"])
		_curr_phrase["text"] = TextTools.add_line_breaks(_curr_phrase["text"], _dialogue_label)
		_print_dialogue_segment(true)
	
	# Parse Commands
	if _curr_phrase.has("commands"):
		for command in _curr_phrase["commands"]:
			if _method_target.has_method(command.method):
				_method_target.call(command.method, command.param)
	
	if _curr_phrase.has("font"):
		if _curr_phrase["font"] == "EBZ":
			_dialogue_label.add_font_override("font",load("res://Fonts/saturn.tres"))
			_bullet_label.add_font_override("font",load("res://Fonts/saturn.tres"))
	
	if _curr_phrase.has("soundeffect"):
		if !_curr_phrase["soundeffect"].begins_with("res://"):
			_curr_phrase["soundeffect"] = "res://Audio/Sound effects/" + _curr_phrase["soundeffect"]
		$SoundEffect.stream = load(_curr_phrase["soundeffect"])
		$SoundEffect.play()
	
	if _curr_phrase.get("sound", null):
		if !_curr_phrase["sound"].begins_with("res://"):
			_curr_phrase["sound"] = "res://Audio/Sound effects/text/" + _curr_phrase["sound"]
		$AudioStreamPlayer.stream = load(_curr_phrase["sound"] + ".mp3")
	else:
		$AudioStreamPlayer.stream = null

func _finish_phrase():
	_t = 0
	_finished = true
	_cursor_down_sprite.show()
	if _auto_advance:
		_is_waiting_between_phrases = true
		yield(get_tree().create_timer(AUTO_ADVANCE_DELAY), "timeout")
		_is_waiting_between_phrases = false
		next_phrase()

func did_finish() -> bool:
	return _finished

# Override
func _action_press(btn_next := false, btn_cancel := false):
	if !_is_waiting_between_phrases:
		._action_press(btn_next, btn_cancel)

func _reset():
	_dialog = {}
	_finished = true
	_t = 0
	_phrase_num = 0
	_segment_num = 0
	_curr_phrase = {}
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_method_target = self

# Override
func _end_dialogue():
	get_tree().set_input_as_handled()
	_show_box(false)
	_reset()
	emit_signal("done")

func play_win():
	$ClipBox/HBoxContainer.hide()
	_dialogue_box_node.show()
	$AnimationPlayer.play("YouWin")
