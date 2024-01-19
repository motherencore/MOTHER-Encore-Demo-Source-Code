extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var infoBox

const skillList = {
	"Offense": [],
	"Recovery": [],
	"Assist": []
}

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav")
}

var categories = ["Offense", "Recovery", "Assist"]
var infoOnScreen = true
var infoScreenPosition

func _ready():
	infoBox = get_node_or_null(infoBox)
	if infoBox:
		infoScreenPosition = infoBox.rect_position 
	$PSISelect.connect("selected", self, "selectSkill")
	$PSISelect.connect("moved", self, "updateInfoBox")

func _input(event):
	if visible and $PSISelect._active:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
			Input.action_release("ui_cancel")
			Input.action_release("ui_toggle")
			get_tree().set_input_as_handled()
			audioManager.play_sfx(soundEffects["back"], "BattleSfx")
			
			$PSISelect.setActive(false)
			$PSISelect.set_PP_visible(false)
			cursor.on = true
			if infoBox != null:
				infoBox.hide()
		if event.is_action_pressed("ui_ctrl") and infoBox:
			if infoOnScreen:
				# go off screen
				$Tween.stop_all()
				$Tween.remove_all()
				$Tween.interpolate_property(infoBox, "rect_position:y", \
					infoScreenPosition.y, infoScreenPosition.y + 60, 0.25, \
					Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
				$Tween.start()
			else:
				#go on screen
				$Tween.stop_all()
				$Tween.remove_all()
				$Tween.interpolate_property(infoBox, "rect_position:y", \
					infoBox.rect_position.y, infoScreenPosition.y, 0.25, \
					Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
				$Tween.start()
			infoOnScreen = !infoOnScreen

func enter(reset = false, _action = null):
	.enter(reset, _action)
	if reset:
		# set user here so psi select knows when the user doesn't have enough pp
		$PSISelect.user = action.user.stats
		updatePSI(action.user.stats.learnedSkills)
		if skillList.Offense.size() > 0:
			cursor.set_cursor_from_index(0, false)
		elif skillList.Recovery.size() > 0:
			cursor.set_cursor_from_index(1, false)
		elif skillList.Assist.size() > 0:
			cursor.set_cursor_from_index(2, false)
		else:
			cursor.set_cursor_from_index(0, false)
		updateSkillsBox()
		$PSISelect.setActive(false)
		$PSISelect.set_PP_visible(false)
	else:
		$PSISelect.setActive(true, false)
		$PSISelect.set_PP_visible(true)
		cursor.on = false

func exit():
	.exit()
	$PSISelect.reset()

func hide():
	.hide()
	if infoBox != null:
		infoBox.hide()

func move(dir):
	updateSkillsBox()

func select(idx):
	# first, check if there's even a skill here lmao
	if skillList[categories[cursor.cursor_index]].empty():
		return
	cursor.on = false
	$PSISelect.setActive(true, false)
	$PSISelect.set_PP_visible(true)
	if infoBox != null:
		infoBox.show()

func updatePSI(skills):
	#clear skills
	skillList["Offense"].clear()
	skillList["Recovery"].clear()
	skillList["Assist"].clear()
	for skillName in skills:
		var skill = globaldata.skills[skillName]
		if skill.has("category"):
			if skill.useCases > -1: # -1 is field only
				skillList[skill.category].append(skillName)
	if skillList["Offense"].empty():
		$VBox/Label1.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label1.set_self_modulate(Color.white)
	if skillList["Recovery"].empty():
		$VBox/Label2.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label2.set_self_modulate(Color.white)
	if skillList["Assist"].empty():
		$VBox/Label3.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label3.set_self_modulate(Color.white)

func updateSkillsBox():
	var category = categories[cursor.cursor_index]
	$PSISelect.updateSkills(skillList[category])

func selectSkill(skill):
	$PSISelect.setActive(false, false)
	$PSISelect.set_PP_visible(false)
	action.skill = skill
	emit_signal("next")

func updateInfoBox(skill):
	if infoBox != null:
		var category = categories[cursor.cursor_index]
		infoBox.get_child(0).text = skill.description


func _on_Arrow_moved_direction(dir):
	move(dir)
