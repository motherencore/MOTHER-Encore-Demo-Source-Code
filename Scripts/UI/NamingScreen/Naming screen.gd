extends Control

const BLINK_DURATION := .3

const DONT_CARE_CHOICES := 7

const SPRITES_GAP := 320

const KEYBOARD_ROWS := 5

var _scenario_id := "intro"
var _embed_mode := false

var _scenario: Array
var _check_duplicates_in: Array
var _allow_cancel := false
var _input_results := []
var _is_highlight_played := false
var _current_keyboard_panel := 0
var _blacklisted_names = tr("BLACKLISTED_NAMES").split(",")
var _current_step := 0
var _input_text := ""
var _current_settings_panel = null
var _music_id

var _sound_effects := {
	"set_upper": load("res://Audio/Sound effects/M3/menu_open2.wav"),
	"set_lower": load("res://Audio/Sound effects/M3/menu_close2.wav"),
	"next": load("res://Audio/Sound effects/M3/menu_open.wav"),
	"prev": load("res://Audio/Sound effects/M3/menu_close.wav")
}

onready var _prompt_label := $CanvasLayer/NameBox/Label
onready var _input_label := $CanvasLayer/NameBox/name/Label
onready var _keyboard_arrow := $CanvasLayer/NamingBox/arrow
onready var _settings_arrow := $CanvasLayer/Settings/SettingsArrow
onready var _text_speed_arrow := $CanvasLayer/TextSpeed/TextSpeedArrow
onready var _flavors_arrow := $CanvasLayer/Flavors/FlavorsArrow
onready var _button_prompts_arrow := $CanvasLayer/ButtonPrompts/ButtonPromptsArrow
onready var _confirm_arrow := $CanvasLayer/ConfirmationRight/Surely/ConfirmationArrow
onready var _keyboard_area := $CanvasLayer/NamingBox/Grid
onready var _keyboard_grid_1 := $CanvasLayer/NamingBox/Grid/GridContainer
onready var _keyboard_grid_2 := $CanvasLayer/NamingBox/Grid/GridContainer2
onready var _keyboard_grid_3 := $CanvasLayer/NamingBox/Grid/GridContainer3
onready var _keyboard_grid_dont_care := $CanvasLayer/NamingBox/CommandGrid/GridContainer4
onready var _keyboard_grid_ok_back := $CanvasLayer/NamingBox/CommandGrid/GridContainer5
onready var _panel_switch_button := $CanvasLayer/NamingBox/PressButton/Label
onready var _flavors_menu := $CanvasLayer/Flavors
onready var _text_speed_menu := $CanvasLayer/TextSpeed
onready var _button_prompts_menu := $CanvasLayer/ButtonPrompts
onready var _char_anims := $CharAnims
onready var _menu_anims := $MenuAnims
onready var _tween := $Tween
onready var _actors_container := $Objects/Actors/ActorsSequence
onready var _actors_collection := $Toolbox/Actors
onready var _confirm_collection := $Toolbox/Confirm
onready var _keyboard_dont_care := $"CanvasLayer/NamingBox/CommandGrid/GridContainer4/Don't care"
onready var _keyboard_ok := $CanvasLayer/NamingBox/CommandGrid/GridContainer5/OK
onready var _keyboard_backspace := $CanvasLayer/NamingBox/CommandGrid/GridContainer5/Backspace

func init(scenario_id, embed_mode := false):
	_scenario_id = scenario_id
	_embed_mode = embed_mode

# Called when the node enters the scene tree for the first time.
func _ready():
	var naming_sequence = globaldata.namingSequences[_scenario_id]
	_scenario = naming_sequence.scenario
	_check_duplicates_in = naming_sequence.get("check_duplicates_in", [])
	_init_sprites()
		
	for step in _scenario:
		var target = step.get("target", "")
		if target in globaldata:
			var value = globaldata.get(step.target)
			if not value is String:
				value = value.nickname
			_input_results.append(value)
		else:
			_input_results.append("")
		
	_blacklisted_names.append("")

	_refresh_settings_menu()
	_current_settings_panel = _text_speed_menu
	global.persistPlayer.pause()
	
	if !_embed_mode:
		global.cutscene = true
		global.persistPlayer.hide()
	else:	
		$Background.hide()
		$CanvasLayer/NameBox/Mask.hide()

	if naming_sequence.has("bgm"):
		if _embed_mode:
			audioManager.pause_all_music()
		
		audioManager.add_audio_player()
		_music_id = audioManager.get_latest_audio_player_index()
		audioManager.play_music("", naming_sequence.bgm, _music_id)
		audioManager.set_audio_player_volume(_music_id, 8)

	_refresh_keys()

	global.connect("locale_changed", self, "_update_locale")
	
	_char_anims.play("Start")
	_set_new_step()

	yield(get_tree().create_timer(0.5), "timeout")
	_allow_cancel = naming_sequence.get("allow_cancel", true)

# LOCALIZATION Code added: View refresh when the locale changes
func _update_locale():
	_toggle_keyboard_panel(0)
	_refresh_keys()

func _set_next_step(restart = false):
	if !_tween.is_active():
		if not restart:
			if _scenario[_current_step].type == "naming":
				var error_msg = _check_for_errors(_input_text)			
				if error_msg:
					_prompt_label.text = error_msg
					$BlockName.play()
					if !_is_highlight_played:
						_highlight_color()
						yield(get_tree().create_timer(2), "timeout")
						_set_naming_prompt()
					return
				_input_results[_current_step] = _input_text
				$OkDesuka.play()
				_change_sprite(1)
			_current_step += 1
		else:
			_change_sprite(0, true)
			_menu_anims.play("Naming Open")
			_current_step = 0
		_play_char_anims()
		_set_new_step()

func _set_prev_step():
	if !_tween.is_active():
		if _scenario[_current_step].type == "naming":
			_input_results[_current_step] = _input_text

		_current_step -= 1

		if _current_step < 0:
			if _allow_cancel:
				_keyboard_arrow.on = false
				_finish(false)
			else:
				_current_step = 0
		else:
			audioManager.play_sfx(_sound_effects["prev"], "swish")
			if _scenario[_current_step].type == "naming":
				_change_sprite(-1)
			
			_play_char_anims(-1)
			_set_new_step()

func _set_new_step():
	_keyboard_arrow.on = false
	_confirm_arrow.on = false
	_settings_arrow.on = false
	if _current_step >= _scenario.size():
		_menu_anims.play("ConfirmationClose")
		_save_new_names()
		$OkDesuka.play()
		_finish(true)
	else:
		match (_scenario[_current_step].type):
			"naming":
				_keyboard_arrow.on = true
				_input_text = _input_results[_current_step]
				_reset_keyboard_cursor()
				_set_dots()
				_set_naming_prompt()
				_update_lr_prompts()
				_keyboard_dont_care.visible = _scenario[_current_step].has("dont_care")
			"settings":
				_settings_arrow.hide()
				_menu_anims.play("SettingsOpen")
				if _tween.is_active():
					yield(_tween, "tween_all_completed")
					_settings_arrow.set_cursor_from_index(0, false)
					_settings_arrow.on = true
					_settings_arrow.show()
				_on_SettingsArrow_moved(0)
			"confirm":
				_confirm_arrow.hide()
				_refresh_confirmation_view()
				_menu_anims.play("ConfirmationOpen")
				_hide_all_setting_panels()
				yield(_menu_anims, "animation_finished")
				_confirm_arrow.set_cursor_from_index(0, false)
				_confirm_arrow.on = true
				_confirm_arrow.show()

func _input(event):
	if _current_step in range (0,_scenario.size()):
		if _scenario[_current_step].type == "naming":
			if event.is_action_pressed("ui_cancel"):
				_backspace()
			if event.is_action_pressed("ui_scope"):
				_toggle_keyboard_panel()
			if event.is_action_pressed("ui_select"):
				if _scenario[_current_step].has("dont_care"):
					_keyboard_arrow.change_parent(_keyboard_grid_dont_care)
				else:
					_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
					_keyboard_arrow.set_cursor_from_index(_keyboard_arrow.get_last_available_idx())
			if event.is_action_pressed("ui_focus_next") and _can_do_next():
				_set_next_step()
			if event.is_action_pressed("ui_focus_prev") and _can_do_prev():
				_set_prev_step()	
		elif _scenario[_current_step].type == "confirm":
			if event.is_action_pressed("ui_cancel"):
				_restart_sequence()

func _init_sprites():
	for i in _scenario.size():
		var _sprite_name = _scenario[i].get("sprite")
		if _sprite_name:
			var _sprite = _actors_collection.get_node_or_null(_sprite_name)
			var _new_sprite
			if _sprite:
				_new_sprite = _actors_collection.get_node(_sprite_name).duplicate()
			else:
				_new_sprite = load("res://Nodes/Reusables/npc.tscn").instance()
				_new_sprite.sprite = _sprite_name
				_new_sprite.idle_animation = "Walk"
			_new_sprite.position.x = i * SPRITES_GAP
			_actors_container.add_child(_new_sprite)

func _highlight_color():
	_is_highlight_played = true
	for i in range(2):
		var temporal = _prompt_label.text
		if temporal != _prompt_label.text:
			break
		_prompt_label.modulate = Color(TextTools.DIALOG_HINT_COLOR)
		yield(get_tree().create_timer(BLINK_DURATION), "timeout")
		_prompt_label.modulate = Color(Color.white)
		yield(get_tree().create_timer(BLINK_DURATION), "timeout")
		if temporal != _prompt_label.text:
			break
	_is_highlight_played = false

func _reset_keyboard_cursor():
	_keyboard_arrow.change_parent(_keyboard_grid_1, false)
	_keyboard_arrow.cursor_index = 0
	_keyboard_arrow.set_cursor_from_index(0, true)

func _set_dots():
	_input_label.text = _input_text
	var max_characters = tr(_scenario[_current_step].longest_name).length()
	if len(_input_label.text) < max_characters:
		# LOCALIZATION Code change: To handle the Japanese full-width bullet character as well
		_input_label.text += tr("SYMBOL_BULLET_NAMING")
		for i in max_characters - len(_input_label.text):
			# LOCALIZATION Code change: To handle the Japanese full-width dot character as well
			_input_label.text += tr("SYMBOL_DOT")

func _set_naming_prompt():
	_prompt_label.text = _scenario[_current_step].prompt

func _play_char_anims(direction = 1):
	if _current_step - direction in range(0, _scenario.size()):
		_play_char_anim(_scenario[_current_step - direction].char_anims_leave)
	if _current_step in range(0, _scenario.size()):
		_play_char_anim(_scenario[_current_step].char_anims_enter)

func _play_char_anim(sequences):
	if sequences.empty():
		return
	_char_anims.play(sequences[0])
	for i in range(1,sequences.size()):
		yield(_char_anims, "animation_finished")
		_char_anims.play(sequences[i])

func _change_sprite(direction, reset = false):
	var final_val = _actors_container.position.x - (SPRITES_GAP * direction) if !reset else 0
	var duration = 1.0 if !reset else 1.5
	var trans_type = Tween.TRANS_QUART if !reset else Tween.TRANS_QUAD
	var ease_type = Tween.EASE_IN_OUT if !reset else Tween.EASE_OUT
	_tween.interpolate_property(_actors_container, "position:x", 
		_actors_container.position.x, final_val, duration, trans_type, ease_type)
	_tween.start()	

func _update_lr_prompts():
	$CanvasLayer/NameBox/Indicator.visible = _can_do_prev()
	$CanvasLayer/NameBox/Indicator2.visible = _can_do_next()

func _can_do_prev():
	return _scenario[_current_step].type == "naming" and _current_step > 0

func _can_do_next():
	return _scenario[_current_step].type == "naming" and _current_step < _scenario.size() - 1 and !_input_text.empty()

# LOCALIZATION Code change: Instead of switching to lower case, now the method refreshes the keys
# according to current keyboard panel: caps/small, but also hiragana/katakana/romaji, etc.
func _refresh_keys():
	var gridId = 0
	for parent in _keyboard_area.get_children():
		if parent is GridContainer && !parent in [_keyboard_grid_dont_care, _keyboard_grid_ok_back]:
			var letters = tr("KEYBOARD_PANEL%s_GRID%s" % [_current_keyboard_panel,gridId])
			# In case we need to set a different number of columns for different languages
			#parent.columns = len(letters) / KEYBOARD_ROWS
			for i in parent.get_child_count():
					var label = parent.get_child(i)
					var lowerLabel
					if label.get_child_count() == 0:
						lowerLabel = label.duplicate()
						label.add_child(lowerLabel)
						label.percent_visible = 0
						lowerLabel.rect_position = Vector2.ZERO
					else:
						lowerLabel = label.get_child(0)
					var letter = letters[i] if i < len(letters) else ""
					letter = letter.replace("_", "")
					lowerLabel.text = letter
					label.text = "A" if letter != "" else ""
			gridId += 1

	var next_current_keyboard_panel = fmod(_current_keyboard_panel + 1, _count_keyboard_panels())
	_panel_switch_button.text = "KEYBOARD_PANEL%s_NAME" % next_current_keyboard_panel

# LOCALIZATION Code change: Now switches to the next keyboard panel (caps/small, hiragana/katakana/romaji, etc.)
# Adapted so that we can have more than two panels
func _toggle_keyboard_panel(dir = 1):
	_current_keyboard_panel = int(fmod(_current_keyboard_panel + dir, _count_keyboard_panels()))
	_refresh_keys()
	if _keyboard_arrow.menu_parent.get_child(_keyboard_arrow.cursor_index).text == "":
		_reset_keyboard_cursor()
	if dir != 0:
		if _current_keyboard_panel == _count_keyboard_panels() - 1:
			audioManager.play_sfx(_sound_effects["set_lower"], "casing")
		else:
			audioManager.play_sfx(_sound_effects["set_upper"], "casing")

# LOCALIZATION Code added: Returns the number of keyboard panels, based on the csv keys
# (Too bad there’s no way to know if one csv entry is empty in a certain language)
func _count_keyboard_panels():
	var i = 0
	while tr("KEYBOARD_PANEL%s_GRID1" % i) != "KEYBOARD_PANEL%s_GRID1" % i:
		i += 1
	return i

# LOCALIZATION Code added: Appends new character to the current name,
# and also merges characters together in languages that require it (specifically Korean)
func _keyboard_char_addition(character):
	var hangul_addition = KoreanHangul.compose_addition(_input_text, character)
	if hangul_addition:
		_input_text = hangul_addition
		return true
	else:
		if len(_input_text) < tr(_scenario[_current_step].longest_name).length():
			_input_text += character
			return true

	return false

# LOCALIZATION Code added: Removes last character from the current name,
# and also remerges characters together in languages that require it (specifically Korean)
func _keyboard_char_removal():
	var hangul_removal = KoreanHangul.compose_removal(_input_text)
	if hangul_removal:
		_input_text = hangul_removal
	else:
		_input_text = _input_text.left(_input_text.length()-1)

func _backspace():
	if _input_text != "":
		# LOCALIZATION Code change: Calls the new method for character removal
		_keyboard_char_removal()
		_set_dots()
		_update_lr_prompts()
		_keyboard_arrow.play_sfx("back")
	else:
		_set_prev_step()

func _check_for_errors(name):
	var checkname = name.to_lower().strip_edges()
	# Checking for blacklisted names
	if checkname in _blacklisted_names:
		return "NAME_BLOCKED"
	# Checking for identical names from other steps
	for index in range(len(_input_results)):
		if index != _current_step and checkname == _input_results[index].to_lower().strip_edges():
			return "NAME_DUPLICATED"
	# Checking for identical names in previous naming scenarios
	for other_name_id in _check_duplicates_in:
		if other_name_id in globaldata:
			var other_name = globaldata.get(other_name_id)
			if not other_name is String:
				other_name = other_name.nickname
			if checkname == other_name.to_lower().strip_edges():
				return "NAME_DUPLICATED"

func _set_dont_care():
	var index = 0
	for i in DONT_CARE_CHOICES:
		if _input_text == tr(_scenario[_current_step].dont_care + str(i)):
			index = fmod(i + 1, DONT_CARE_CHOICES)
			break
	_input_text = tr(_scenario[_current_step].dont_care + str(index))
	_update_lr_prompts()
	_set_dots()

func _show_setting_panel(menu):
	_hide_all_setting_panels()
	_current_settings_panel = menu
	if _tween.is_active():
		yield(_tween, "tween_all_completed")
	if _current_settings_panel == menu:
		_tween.interpolate_property(menu, "rect_position:x",
			menu.rect_position.x, 184, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		_tween.start()
		if menu == _button_prompts_menu:
			_button_prompts_menu.refresh(false)

func _refresh_settings_menu():
	var speed_index = globaldata.TEXT_SPEEDS.find(globaldata.textSpeed)
	$CanvasLayer/Settings/VBoxContainer2/Speed.text = "MENU_" + globaldata.TEXT_SPEEDS_NAMES[speed_index]
	$CanvasLayer/Settings/VBoxContainer2/Flavor.text = "FLAVOR_" + globaldata.menuFlavor.to_upper()
	$CanvasLayer/Settings/VBoxContainer2/Prompts.text = "MENU_" + globaldata.buttonPrompts.to_upper()

func _refresh_settings_selections(index):
	match index:
		0:
			_text_speed_arrow.set_cursor_from_index(globaldata.TEXT_SPEEDS.find(globaldata.textSpeed), false)
		1:
			_flavors_arrow.set_cursor_from_index(globaldata.FLAVORS.find(globaldata.menuFlavor), false)
		2:
			_button_prompts_arrow.set_cursor_from_index(globaldata.BUTTON_PROMPTS.find(globaldata.buttonPrompts), false)
			_button_prompts_menu.refresh(false)

func _hide_all_setting_panels():
	_current_settings_panel = null
	_tween.stop_all()
	for i in [_text_speed_menu, _flavors_menu, _button_prompts_menu]:
		_tween.interpolate_property(i, "rect_position:x",
			i.rect_position.x, 328, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
	_tween.start()

func _refresh_confirmation_view():
	for i in _input_results.size():
		if _scenario[i].type == "naming":
			var res_node = find_node("Confirm%s" % i)
			res_node.get_node("Label").text = _input_results[i]
			var image_node = _confirm_collection.get_node(_scenario[i].sprite).duplicate()
			res_node.add_child(image_node)

func _restart_sequence():
	_set_next_step(true)

func _save_new_names():
	for i in _scenario.size():
		if _scenario[i].has("target"):
			var target = _scenario[i].target
			if target in globaldata:
				if globaldata.get(target) is String:
					globaldata.set(target, _input_results[i])
				else:
					globaldata.get(target).nickname = _input_results[i]

func _finish(completed):
	if _embed_mode:
		#audioManager.music_fadeout(_music_id) # doesn’t sound great
		audioManager.stop_audio_player(_music_id)
		audioManager.resume_all_music()
		uiManager.remove_ui(self)
		if is_instance_valid(uiManager.dialogueBox):
			uiManager.dialogueBox.call_deferred("next_phrase")
		else:
			global.persistPlayer.unpause()
		queue_free()
	else:
		global.cutscene = false
		if completed:
			$Objects/Door2.enter()
		else:
			audioManager.stop_all_music()
			$Objects/Door.enter()

func _on_arrow_selected(cursor_index):
	match _keyboard_arrow.get_current_item():
		_keyboard_dont_care:
			_set_dont_care()
			_keyboard_arrow.play_sfx("cursor2")
		_keyboard_backspace:
			_backspace()
		_keyboard_ok:
			if _input_text != "":
				_set_next_step()
		_:
			var character = ""
			if _keyboard_arrow.menu_parent.get_child(cursor_index).percent_visible == 1:
				character = tr(_keyboard_arrow.menu_parent.get_child(cursor_index).text)
			else :
				character = tr(_keyboard_arrow.menu_parent.get_child(cursor_index).get_child(0).text)
			
			var has_text_changed = _keyboard_char_addition(character)
			if has_text_changed:
				_set_dots()
				_update_lr_prompts()
				_keyboard_arrow.play_sfx("cursor2")

func _on_arrow_failed_move(dir):
	var index = 0
	match _keyboard_arrow.menu_parent:
		_keyboard_grid_1:
			match dir:
				Vector2(-1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_3)
					_keyboard_arrow.set_cursor_from_index(_keyboard_arrow.cursor_index + _keyboard_grid_3.columns - 1)
				Vector2(1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_2)
				Vector2(0, -1):
					_keyboard_arrow.change_parent(_keyboard_grid_dont_care) \
					or _keyboard_arrow.set_cursor_from_index(_keyboard_grid_1.get_child_count() - _keyboard_grid_1.columns + (_keyboard_arrow.cursor_index % _keyboard_grid_1.columns), true, true)
				Vector2(0, 1):
					_keyboard_arrow.change_parent(_keyboard_grid_dont_care) or _keyboard_arrow.set_cursor_from_index(_keyboard_arrow.cursor_index % _keyboard_grid_1.columns, true, true)
		_keyboard_grid_2:
			match dir:
				Vector2(-1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_1)
				Vector2(1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_3)
				Vector2(0, -1):
					if _keyboard_arrow.cursor_index % _keyboard_grid_2.columns >= _keyboard_grid_2.columns/2:
						_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
						_keyboard_arrow.set_cursor_from_index(0)
					else:
						_keyboard_arrow.change_parent(_keyboard_grid_dont_care) \
						or _keyboard_arrow.set_cursor_from_index(_keyboard_grid_2.get_child_count() - _keyboard_grid_2.columns + (_keyboard_arrow.cursor_index % _keyboard_grid_2.columns), true, true)
				Vector2(0, 1):
					if _keyboard_arrow.cursor_index % _keyboard_grid_2.columns >= _keyboard_grid_2.columns/2:
						_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
					else:
						_keyboard_arrow.change_parent(_keyboard_grid_dont_care) \
						or _keyboard_arrow.set_cursor_from_index(_keyboard_arrow.cursor_index % _keyboard_grid_2.columns, true, true)
		_keyboard_grid_3:
			match dir:
				Vector2(-1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_2)
				Vector2(1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_1)
					_keyboard_arrow.set_cursor_from_index(_keyboard_arrow.cursor_index - _keyboard_grid_1.columns + 1)
				Vector2(0, -1):
					_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
				Vector2(0, 1):
					_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
		_keyboard_grid_dont_care:
			match dir:
				Vector2(-1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
					_keyboard_arrow.set_cursor_from_index(_keyboard_arrow.cursor_index + _keyboard_grid_ok_back.columns - 1)
				Vector2(1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_ok_back)
				Vector2(0, -1):
					_keyboard_arrow.change_parent(_keyboard_grid_1)
				Vector2(0, 1):
					_keyboard_arrow.change_parent(_keyboard_grid_1)
					_keyboard_arrow.set_cursor_from_index(0)
		_keyboard_grid_ok_back:
			match dir:
				Vector2(-1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_dont_care) or _keyboard_arrow.set_cursor_from_index(_keyboard_arrow.get_last_available_idx(), true, true)
				Vector2(1, 0):
					_keyboard_arrow.change_parent(_keyboard_grid_dont_care) or _keyboard_arrow.set_cursor_from_index(_keyboard_arrow.get_first_available_idx(), true, true)
				Vector2(0, -1):
					_keyboard_arrow.change_parent(_keyboard_grid_3)
				Vector2(0, 1):
					_keyboard_arrow.change_parent(_keyboard_grid_3)
					if _keyboard_arrow.cursor_index == 0:
						_keyboard_arrow.set_cursor_from_index(0)
					else:
						_keyboard_arrow.set_cursor_from_index(_keyboard_grid_3.columns - 1)

func _on_SettingsArrow_moved(dir):
	match _settings_arrow.cursor_index:
		0:
			_show_setting_panel(_text_speed_menu)
		1:
			_show_setting_panel(_flavors_menu)
		2:
			_show_setting_panel(_button_prompts_menu)
		3:
			_hide_all_setting_panels()

func _on_SettingsArrow_selected(cursor_index):
	_settings_arrow.on = false
	if _tween.is_active():
		yield(_tween, "tween_all_completed")
		if _tween.is_active():
			yield(_tween, "tween_all_completed")
	match _settings_arrow.cursor_index:
		0:
			_text_speed_arrow.on = true
			_text_speed_arrow.show()
		1:
			_flavors_arrow.on = true
			_flavors_arrow.show()
		2:
			_button_prompts_arrow.on = true
			_button_prompts_arrow.show()
			_button_prompts_menu.refresh(false)
		3:
			_set_next_step()
			return
	
	_refresh_settings_selections(_settings_arrow.cursor_index)

func _on_SettingsArrow_cancel():
	_hide_all_setting_panels()
	_settings_arrow.on = false # TODO move to set_prev_step
	_keyboard_arrow.on = true
	_keyboard_arrow.hide()
	_keyboard_arrow.set_cursor_from_index(0, false)
	_menu_anims.play("SettingsClose")
	if _tween.is_active():
		yield(_tween, "tween_all_completed")
	_set_prev_step()

func _on_TextSpeedArrow_selected(cursor_index):
	_settings_arrow.on = true
	_text_speed_arrow.on = false
	_text_speed_arrow.hide()
	globaldata.textSpeed = globaldata.TEXT_SPEEDS[cursor_index]
	_refresh_settings_menu()

func _on_TextSpeedArrow_cancel():
	_settings_arrow.on = true
	_text_speed_arrow.on = false
	_text_speed_arrow.hide()
	_text_speed_arrow.get_current_item().percent_visible = 1

func _on_FlavorsArrow_selected(cursor_index):
	_settings_arrow.on = true
	_flavors_arrow.on = false
	_flavors_arrow.hide()
	globaldata.menuFlavor = globaldata.FLAVORS[cursor_index]
	_refresh_settings_menu()

func _on_FlavorsArrow_cancel():
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	_settings_arrow.on = true
	_flavors_arrow.on = false
	_flavors_arrow.hide()

func _on_ButtonPromptsArrow_selected(cursor_index):
	_settings_arrow.on = true
	_button_prompts_arrow.on = false
	_button_prompts_arrow.hide()
	globaldata.buttonPrompts = globaldata.BUTTON_PROMPTS[cursor_index]
	_refresh_settings_menu()

func _on_ButtonPromptsArrow_cancel():
	_settings_arrow.on = true
	_button_prompts_arrow.on = false
	_button_prompts_arrow.hide()
	_refresh_settings_selections(2)

func _on_ConfirmationArrow_selected(cursor_index):
	_confirm_arrow.on = false
	match cursor_index:
		0:
			_set_next_step()
		1:
			_restart_sequence()

func _on_ConfirmationArrow_cancel():
	_restart_sequence()
