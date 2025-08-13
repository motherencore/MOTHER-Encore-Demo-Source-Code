extends CanvasLayer

onready var _party_info_view = uiManager.party_info_view

enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

signal back

var _sfx = {
	# psi skill sounds
	"lifeup_a": load("res://Audio/Sound effects/EB/heal 1.wav"),
	"healing_a": load("res://Audio/Sound effects/EB/heal.wav"),
}


var _current_character = globaldata.ninten
var active := false
var _desc_active := false
var _skill := {}
var _messages_stack := []

onready var _psi_select = $PSIMenu/PSISelect
onready var _desc_label = $PSIMenu/Description/Desc
onready var _character_tab = $PSIMenu/PSICharacterTab

func _ready():
	$PSIMenu.hide()
	_character_tab.show()
	_update_desc_label("")
	_psi_select.connect("selected", self, "_on_who")
	_psi_select.connect("use", self, "_use_skill")
	_psi_select.connect("no_pp", self, "_use_skill_no_pp")
	_psi_select.connect("moved", self, "_update_psi_description")
	$PSIMenu/TargetCharacterMenu.connect("back", self, "_on_psi_cancel")
	$PSIMenu/TargetCharacterMenu.connect("next", self, "_on_psi_target_confirmed")

func show_PSIMenu():
	active = true
	$AnimationPlayer.play("Open")
	updatePSIBox()
	_update_party_infos()
	_psi_select.set_active(true)
	_psi_select.set_PP_visible(true)

func closePSIMenu():
	_psi_select.set_active(false)
	_character_tab.active = false
	active = false
	$AnimationPlayer.play("Close")
	emit_signal("back")

func _input(event):
	if active:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			closePSIMenu()
	elif _desc_active:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			if _messages_stack.empty():
				Input.action_release("ui_accept")
				Input.action_release("ui_cancel")
				_desc_active = false
				active = true
				_on_psi_cancel()
				_update_psi_description(_skill)

func updatePSIBox():
	# kind of a hack, since im stealing this menu from battle system
	_character_tab.InitFromCharacter(_current_character.name)
	_psi_select.set_active(false)
	_psi_select.user = _current_character
	_psi_select.updateSkills(_current_character.learnedSkills)
	_psi_select.set_active(true)
	if _psi_select.skills.empty():
		_update_desc_label("")
#	psiBox.exit()
#	psiBox.enter({"user": {"stats": _current_character}})

func _use_skill(selectedSkill):
	_skill = selectedSkill

	Input.action_release("ui_accept")

	_current_character.pp -= _skill.ppCost
	_psi_select.refresh_selectable()

	# LOCALIZATION Use of csv key as an id, instead of the English name
	match _skill:
		globaldata.skills.telepathy:
			#interact stuff with player
			uiManager.close_commands_menu()
			global.persistPlayer.use_telepathy()
		globaldata.skills.teleportA:
			uiManager.close_commands_menu(false, true)
			global.persistPlayer.start_teleport(int(_skill.level))

func _use_skill_no_pp(selected_skill):
	_desc_active = true
	active = false
	_psi_select.set_active(false)
	_update_desc_label("PSI_PP_NOTENOUGH")

func _on_who(selected_skill: Dictionary):
	Input.action_release("ui_accept")
#	_skill = psiBox.action.skill
	_skill = selected_skill
	# get all current party member names
	var char_list = []
	match(int(_skill.targetType)):
		TargetType.SELF:
			char_list = [_current_character.name]
		TargetType.ALL_ALLIES:
			char_list = ["all"]
		_:
			for party_mem in global.party:
				if _can_skill_target(party_mem):
					char_list.append(party_mem.name)
	$PSIMenu/TargetCharacterMenu.show_target_chara_select(_psi_select.cursor.global_position, char_list)
	active = false
#	psiBox.cursor2.on = false
	_character_tab.active = false
	_psi_select.set_active(false)

func _on_psi_cancel(someVar = null):
	_party_info_view.deselect_all()
	active = true
#	psiBox.cursor2.on = true
	_character_tab.active = true
	_psi_select.set_active(true)

func _on_psi_target_confirmed(menu_target):
	_party_info_view.deselect_all()
	# TODO: Check for if a character is either full hp or no status ailments
	# do skill stuff
	# first, handle pp:
	_current_character.pp -= _skill.ppCost

	_psi_select.refresh_selectable()
	
	# Whos targeted?
	var targets = []
	for character in global.party:
		if menu_target == character.name or\
		(menu_target == "all" and _can_skill_target(character)):
			targets.append(character)
	
	for target in targets:
		_desc_active = true
		if _skill.statusHeals.empty():
			play_sfx("lifeup_a")
			var oldhp = target.hp
			var newhp = clamp(target.hp + _skill.damage, 0, target.maxhp + target.boosts.maxhp)
			target.hp = newhp
			var diff = newhp - oldhp
			if newhp == target.maxhp + target.boosts.maxhp:
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HP_MAX", target))
			else :
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HP_UP", target, null, "", diff))
		else :
			play_sfx("healing_a")
			var heals_performed = []
			for status in _skill.statusHeals:
				if StatusManager.has_status(target, status):
					heals_performed.append(status)
					StatusManager.remove_status(target, status)
					if _skill.statusAmountHealed > 0 and heals_performed.size() >= _skill.statusAmountHealed:
						break
			if heals_performed.size() == 1:
				_messages_stack.push_front(TextTools.format_text_with_context(StatusManager.get_status_message(heals_performed[0], "heal_overworld"), target))
			else :
				_messages_stack.push_front(TextTools.format_text_with_context("ACTION_RESULT_HEAL_ALL", target))
		_update_party_infos()

	_process_messages()


func _process_messages():
	if _messages_stack.empty():
		return
	var message = _messages_stack.pop_back()
	_update_desc_label(message)
	yield(get_tree().create_timer(0.5), "timeout")
	_process_messages()

func _update_party_infos(set := true):
	_party_info_view.update_party_infos(set)

func _on_PSICharacterTab_character_changed(character):
	if active:
		for member in global.party:
			if member.name == character:
				_current_character = member
				updatePSIBox()

func _on_TargetCharacterMenu_show_statsbar(character):
	if character == "all":
		_party_info_view.select_if(funcref(self, "_can_skill_target"))
	else:
		_party_info_view.select_one(character)

func _update_psi_description(newSkill):
	_update_desc_label(tr(newSkill.description))

func _update_desc_label(text):
	var font = _desc_label.get_font("font")
	_desc_label.autowrap = (font.get_string_size(text).x > _desc_label.get_parent_area_size().x)
	if _desc_label.autowrap:
		var line_height = font.get_wordwrap_string_size(text, _desc_label.rect_size.x).y
		if line_height > font.get_height():
			_psi_select.linesPerPage = 3
		else:
			_psi_select.linesPerPage = 4
	else:
		_psi_select.linesPerPage = 4
	_desc_label.text = text

func _can_skill_target(character):
	return !StatusManager.is_unconscious(character)\
		or _skill.has("targetUnconscious") and _skill["targetUnconscious"] == true

func play_sfx(sfxName, channel = 0):
	if !_sfx.has(sfxName):
		return
	audioManager.play_sfx(_sfx[sfxName], "PSIMenu" + str(channel))
