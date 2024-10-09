extends CanvasLayer

const partyInfoTscn = preload("res://Nodes/Ui/Battle/PartyInfoPlate.tscn")

enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

signal back

var sfx = {
	# psi skill sounds
	"lifeup_a": load("res://Audio/Sound effects/EB/heal 1.wav"),
	"healing_a": load("res://Audio/Sound effects/EB/heal.wav"),
}


var currentCharacter = globaldata.ninten
var active = false
var descActive = false
var skill = {}

onready var psiSelect = $PSIMenu/PSISelect
onready var desc_label = $PSIMenu/Description/Desc

func _ready():
	$PSIMenu.hide()
	$PSIMenu/PSICharacterTab.show()
	desc_label.text = ""
	psiSelect.connect("selected", self, "_on_who")
	psiSelect.connect("use", self, "_use_skill")
	psiSelect.connect("moved", self, "_updateDescription")
	$PSIMenu/TargetCharacterMenu.connect("back", self, "_on_psi_cancel")
	$PSIMenu/TargetCharacterMenu.connect("next", self, "_on_psi_target_confirmed")

func show_PSIMenu():
	active = true
	$AnimationPlayer.play("Open")
	updatePSIBox()
	updatePartyInfos()
	psiSelect.set_active(true)
	psiSelect.set_PP_visible(true)

func closePSIMenu():
	psiSelect.set_active(false)
	$PSIMenu/PSICharacterTab.active = false
	active = false
	$AnimationPlayer.play("Close")
	emit_signal("back")

func _input(event):
	if active:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			closePSIMenu()
	elif descActive:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_accept")
			Input.action_release("ui_cancel")
			descActive = false
			active = true
			_on_psi_cancel()
			_updateDescription(skill)

func updatePSIBox():
	# kind of a hack, since im stealing this menu from battle system
	$PSIMenu/PSICharacterTab.InitFromCharacter(currentCharacter.name)
	psiSelect.set_active(false)
	psiSelect.user = currentCharacter
	psiSelect.updateSkills(currentCharacter.learnedSkills)
	psiSelect.set_active(true)
	if psiSelect.skills.empty():
		desc_label.text = ""
#	psiBox.exit()
#	psiBox.enter({"user": {"stats": currentCharacter}})

func _use_skill(selectedSkill):
	Input.action_release("ui_accept")
	skill = selectedSkill
	
	# LOCALIZATION Use of csv key as an id, instead of the English name
	match (skill.name):
		"TELEPATHY":
			#interact stuff with player
			uiManager.close_commands_menu()
			global.persistPlayer.use_telepathy()

func _on_who(selectedSkill):
	Input.action_release("ui_accept")
#	skill = psiBox.action.skill
	skill = selectedSkill
	# get all current party member names
	var char_list = []
	match(int(skill.targetType)):
		TargetType.SELF:
			char_list = [currentCharacter.name]
		TargetType.ALL_ALLIES:
			char_list = ["all"]
		_:
			for party_mem in global.party:
				if _can_skill_target(party_mem):
					char_list.append(party_mem.name)
	if currentCharacter.pp < skill.ppCost:
		# LOCALIZATION Use of csv key for "Not enough pp!"
		desc_label.text = "PSI_PP_NOTENOUGH"
		descActive = true
	else:
		$PSIMenu/TargetCharacterMenu.show_target_chara_select(psiSelect.cursor.global_position, char_list)
	active = false
#	psiBox.cursor2.on = false
	psiSelect.set_active(false)

func _on_psi_cancel(someVar = null):
	for partyInfo in $PSIMenu/PartyInfoHBox.get_children():
		partyInfo.deselect()
	active = true
#	psiBox.cursor2.on = true
	psiSelect.set_active(true)

func _on_psi_target_confirmed(menu_target):
	for partyInfo in $PSIMenu/PartyInfoHBox.get_children():
		partyInfo.deselect()
	# TODO: Check for if a character is either full hp or no status ailments
	# do skill stuff
	# first, handle pp:
	currentCharacter.pp -= skill.ppCost

	psiSelect.refresh_selectable()
	
	# Whos targeted?
	var targets = []
	for character in global.party:
		if menu_target == character.name or\
		(menu_target == "all" and _can_skill_target(character)):
			targets.append(character)
	
	for target in targets:
		descActive = true
		if skill.statusHeals.empty():
			play_sfx("lifeup_a")
			var oldhp = target.hp
			var newhp = clamp(target.hp + skill.damage, 0, target.maxhp + target.boosts.maxhp)
			target.hp = newhp
			var diff = newhp - oldhp
			if newhp == target.maxhp + target.boosts.maxhp:
				desc_label.text = _format_text_with_target("PSI_HP_MAXEDOUT", target)
			else :
				desc_label.text = _format_text_with_target("PSI_HP_RECOVERED", target, diff)
		else :
			play_sfx("healing_a")
			var heals_performed = []
			for status in skill.statusHeals:
				var statusEnum = globaldata.status_name_to_enum(status)
				if target.status.has(statusEnum):
					heals_performed.append(statusEnum)
					target.status.erase(statusEnum)
					if target.has("statusCountup") and target.statusCountup.has(status):
						target.statusCountup[status] = 0
					if skill.statusAmountHealed > 0 and heals_performed.size() >= skill.statusAmountHealed:
						break
			if heals_performed.size() == 1:
				var status_text = tr("INLINE_AILMENT_" + globaldata.status_enum_to_name(heals_performed[0]).to_upper())
				desc_label.text = _format_text_with_target(tr("PSI_STATUS_HEALED").format([status_text]), target)
			else :
				desc_label.text = _format_text_with_target("PSI_STATUS_FULL", target)
		updatePartyInfos()

func updatePartyInfos(set=true):
	for i in $PSIMenu/PartyInfoHBox.get_child_count():
		var partyInfo = $PSIMenu/PartyInfoHBox.get_child(i)
		if i >= global.party.size():
			partyInfo.hide()
			continue
		partyInfo.show()
		partyInfo.pName = global.party[i].nickname
		partyInfo.get_node("Name").text = partyInfo.pName
		partyInfo.maxHP = global.party[i].maxhp + global.party[i].boosts.maxhp
		partyInfo.maxPP = global.party[i].maxpp + global.party[i].boosts.maxpp
		partyInfo.setHP(global.party[i].hp, set)
		partyInfo.setPP(global.party[i].pp, set)
		partyInfo.show_maxNum()

func _on_PSICharacterTab_character_changed(character):
	if active:
		for member in global.party:
			if member.name == character:
				currentCharacter = member
				updatePSIBox()

func _on_TargetCharacterMenu_show_statsbar(character):
	for partyInfo in $PSIMenu/PartyInfoHBox.get_children():
		partyInfo.deselect()
	for i in range(0, global.party.size()):
		if global.party[i].name == character or (character == "all" and _can_skill_target(global.party[i])):
			$PSIMenu/PartyInfoHBox.get_child(i).select()

func _updateDescription(newSkill):
	var font = desc_label.get_font("font")
	var desc = tr(newSkill.description)
	desc_label.autowrap = (font.get_string_size(desc).x > desc_label.get_parent_area_size().x)
	if desc_label.autowrap:
		var line_height = font.get_wordwrap_string_size(desc, desc_label.rect_size.x).y
		if line_height > font.get_height():
			psiSelect.linesPerPage = 3
		else:
			psiSelect.linesPerPage = 4
	else:
		psiSelect.linesPerPage = 4
	desc_label.text = desc

func _can_skill_target(character):
	return !character.status.has(globaldata.ailments.Unconscious)\
		or skill.has("targetUnconscious") and skill["targetUnconscious"] == true

func play_sfx(sfxName, channel = 0):
	if !sfx.has(sfxName):
		return
	audioManager.play_sfx(sfx[sfxName], "PSIMenu" + str(channel))

# Similar method in statsmenu.gd
func _format_text_with_target(text, target, value = 0):
	return tr(text).format({
		"target": target.nickname,
		"value": value
		}).format(
			globaldata.get_battler_articles(target), "{t_}"
		).format(
			globaldata.get_number_articles(value), "{v_}"
		)
