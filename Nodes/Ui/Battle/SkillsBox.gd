extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var infoBox

const pageSize = Vector2(2, 3)
var pageYOffset = 0
var skillList = []

func _ready():
	infoBox = get_node_or_null(infoBox)
	cursor.connect("failed_move", self, "skillBoxBoundaryMoved")

func enter(reset = false, _action = null):
	.enter(reset, _action)
	if reset:
		skillList.clear()
		for skillName in action.user.stats.learnedSkills:
			var skill = globaldata.skills[skillName]
			if !skill.has("category"):
				skillList.append(skill)
		cursor.set_cursor_from_index(0, false)
		updateSkills()
		if infoBox != null and !skillList.empty():
			infoBox.show()

func hide():
	.hide()
	if infoBox != null:
		infoBox.hide()

func move(dir):
	if !skillList.empty():
		var skillIdx = cursor.cursor_index + pageYOffset * pageSize.x
		# if we move to skill that doesn't exist, move back
		if skillIdx > skillList.size() - 1:
			cursor.set_cursor_from_index((int(skillList.size()) % int(pageSize.length())) - 1, false)
		updateInfoBox()

func select(idx):
	if !skillList.empty():
		action.skill = skillList[idx + pageYOffset * pageSize.x]
		emit_signal("next")

func updateSkills(offset = 0):
	pageYOffset += offset
	var skillsOnPage = skillList.slice(pageYOffset * pageSize.x, pageYOffset * pageSize.x + pageSize.x * pageSize.y)
	for skillLabel in $GridContainer.get_children():
		if skillsOnPage.empty():
			skillLabel.text = ""
		else:
			var skill = skillsOnPage.pop_front()
			skillLabel.text = skill.name
	
	if pageYOffset > 0:
		$UpArrow.show()
	else:
		$UpArrow.hide()
	if (pageYOffset + pageSize.y) * pageSize.x < skillList.size():
		$DownArrow.show()
	else:
		$DownArrow.hide()
	move(0)

func skillBoxBoundaryMoved(dir):
	var idx = cursor.cursor_index + pageYOffset * pageSize.x
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * pageSize.x) < 0:
			if pageYOffset > 0:
				updateSkills(-1)
		elif cursor.cursor_index + (dir.y * pageSize.x) > pageSize.length():
			if (pageYOffset + pageSize.y) * pageSize.x < skillList.size():
				updateSkills(1)

func updateInfoBox():
	if infoBox != null:
		infoBox.get_child(0).text = skillList[cursor.cursor_index + pageYOffset * pageSize.x].description
