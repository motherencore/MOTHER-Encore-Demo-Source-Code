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
onready var desc = $PSIMenu/Description/Desc

func _ready():
	$PSIMenu.hide()
	$PSIMenu/PSICharacterTab.show()
	desc.text = ""
#	psiBox.connect("next", self, "onWho")
	psiSelect.connect("selected", self, "onWho")
	psiSelect.connect("use", self, "use_skill")
	psiSelect.connect("moved", self, "_updateDescription")
	$PSIMenu/TargetCharacterMenu.connect("back", self, "psiSelectCancel")
	$PSIMenu/TargetCharacterMenu.connect("next", self, "psiSelectConfirmed")

func show_PSIMenu():
	active = true
	$AnimationPlayer.play("Open")
	updatePSIBox()
	updatePartyInfos()
	psiSelect.setActive(true)
	psiSelect.set_PP_visible(true)

func closePSIMenu():
	psiSelect.setActive(false)
	$PSIMenu/PSICharacterTab.active = false
	active = false
	$AnimationPlayer.play("Close")
	emit_signal("back")

func _input(event):
	if active:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
			Input.action_release("ui_cancel")
			Input.action_release("ui_toggle")
			closePSIMenu()
	elif descActive:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
			Input.action_release("ui_accept")
			Input.action_release("ui_cancel")
			Input.action_release("ui_toggle")
			descActive = false
			active = true
			psiSelectCancel()
			_updateDescription(skill)

func updatePSIBox():
	# kind of a hack, since im stealing this menu from battle system
	$PSIMenu/PSICharacterTab.InitFromCharacter(currentCharacter.name)
	psiSelect.setActive(false)
	psiSelect.user = currentCharacter
	psiSelect.updateSkills(currentCharacter.learnedSkills)
	psiSelect.setActive(true)
	if psiSelect.skills.empty():
		desc.text = ""
#	psiBox.exit()
#	psiBox.enter({"user": {"stats": currentCharacter}})

func use_skill(selectedSkill):
	Input.action_release("ui_accept")
	skill = selectedSkill
	
	match(skill.name):
			"Telepathy":
				#interact stuff with player
				uiManager.close_commands_menu()
				global.persistPlayer.use_telepathy()

func onWho(selectedSkill):
	Input.action_release("ui_accept")
#	skill = psiBox.action.skill
	skill = selectedSkill
	# get all current party member names
	var full_list = []
	for partyMem in global.party:
		full_list.append(partyMem.name)
	match(int(skill.targetType)):
		TargetType.SELF:
			$PSIMenu/TargetCharacterMenu.set_list([currentCharacter.name])
		TargetType.ALL_ALLIES:
			$PSIMenu/TargetCharacterMenu.set_list(["all"])
		_:
			$PSIMenu/TargetCharacterMenu.set_list(full_list)
	if currentCharacter.pp < skill.ppCost:
		desc.text = "Not enough pp!"
		descActive = true
	else:
#		$PSIMenu/TargetCharacterMenu.Show_target_chara_select(psiBox.cursor2.global_position, currentCharacter)
		$PSIMenu/TargetCharacterMenu.Show_target_chara_select(psiSelect.cursor.global_position, currentCharacter)
	active = false
#	psiBox.cursor2.on = false
	psiSelect.setActive(false)

func psiSelectCancel(someVar = null):
	for partyInfo in $PSIMenu/PartyInfoHBox.get_children():
		partyInfo.deselect()
	active = true
#	psiBox.cursor2.on = true
	psiSelect.setActive(true)

func psiSelectConfirmed():
	for partyInfo in $PSIMenu/PartyInfoHBox.get_children():
		partyInfo.deselect()
	# TODO: Check for if a character is either full hp or no status ailments
	# do skill stuff
	# first, handle pp:
	currentCharacter.pp -= skill.ppCost
	
	# Whos targeted?
	var targets = [$PSIMenu/TargetCharacterMenu.get_character()]
	if targets[0] == "all":
		targets = $PSIMenu/TargetCharacterMenu.other_characters_list
	
	for target in targets:
		for character in global.party:
			if character.name == target:
				target = character
				break
		match(skill.name):
			"Telepathy":
				#interact stuff with player
				uiManager.close_commands_menu()
				global.persistPlayer.use_telepathy()
			_:
				descActive = true
				if skill.statusHeals.empty():
					play_sfx("lifeup_a")
					var oldhp = target.hp
					var newhp = clamp(target.hp + skill.damage, 0, target.maxhp + target.boosts.maxhp)
					target.hp = newhp
					var diff = newhp - oldhp
					if newhp == target.maxhp + target.boosts.maxhp:
						desc.text = str(target.nickname, "'s HP was maxed out!")
					else:
						desc.text = str(target.nickname, " recovered ", diff, " HP!")
				else:
					play_sfx("healing_a")
					var toHeal = []
					for status in skill.statusHeals:
						var statusEnum = globaldata.status_name_to_enum(status)
						if target.status.has(statusEnum):
							toHeal.append(status.capitalize())
							target.status.erase(statusEnum)
					desc.text = target.nickname + " was healed of "
					if toHeal.size() == 1:
						desc.text += toHeal[0] + "!"
					else:
						desc.text += " all statuses!"
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
		if global.party[i].name == character or character == "all":
			$PSIMenu/PartyInfoHBox.get_child(i).select()

func _updateDescription(newSkill):
	desc.text = newSkill.description

func play_sfx(sfxName, channel = 0):
	if !sfx.has(sfxName):
		return
	audioManager.play_sfx(sfx[sfxName], "PSIMenu" + str(channel))
