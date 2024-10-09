extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var infoBox

onready var animationPlayer = $AnimationPlayer
onready var scrollbar = $Scrollbar

const pageSize = Vector2(2, 3)
var pageYOffset = 0
var skillList = []

var recent_choice_pagination = {}
var recent_choice_skill = {}
var current_chara

func _ready():
	infoBox = get_node_or_null(infoBox)
	cursor.connect("failed_move", self, "skillBoxBoundaryMoved")
	scrollbar.nb_visible_rows = pageSize.y

func enter(reset = false, _action = null):
	.enter(reset, _action)
	animationPlayer.play("Open")
	scrollbar.on = true
	if reset:
		skillList.clear()
		for skillName in action.user.stats.learnedSkills:
			var skill = globaldata.skills[skillName]
			if !skill.has("category"):
				skillList.append(skill)
		current_chara = action.user.stats.name
		pageYOffset = recent_choice_pagination.get(current_chara, 0)
		scrollbar.position = pageYOffset
		updateSkills(pageYOffset)
		cursor.set_cursor_from_index(recent_choice_skill.get(current_chara, 0), false)
	if infoBox != null and !skillList.empty():
		infoBox.activate()

func hide():
	if visible:
		animationPlayer.play("Close")
	.hide()
	scrollbar.on = false
	if infoBox != null:
		infoBox.deactivate()

func move(dir):
	if skillList.size() - 1 < cursor.cursor_index + pageYOffset * pageSize.x:
		cursor.cursor_index = skillList.size() - pageYOffset * pageSize.x - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !skillList.empty():
		var skillIdx = cursor.cursor_index + pageYOffset * pageSize.x
		# if we move to skill that doesn't exist, move back
		if skillIdx > skillList.size() - 1:
			cursor.set_cursor_from_index((int(skillList.size()) % int(pageSize.x)) - 1, false)
		var description = skillList[cursor.cursor_index + pageYOffset * pageSize.x].description
		infoBox.update_info(tr(description))
		recent_choice_pagination[current_chara] = pageYOffset
		recent_choice_skill[current_chara] = cursor.cursor_index

func select(idx):
	if !skillList.empty():
		action.skill = skillList[idx + pageYOffset * pageSize.x]
		emit_signal("next")

func updateSkills(yOffset):
	pageYOffset = yOffset
	var skillsOnPage = skillList.slice(pageYOffset * pageSize.x, pageYOffset * pageSize.x + pageSize.x * pageSize.y)
	for skillLabel in $GridContainer.get_children():
		if skillsOnPage.empty():
			skillLabel.text = ""
		else:
			var skill = skillsOnPage.pop_front()
			skillLabel.text = skill.name
	
	move(0)
	
	scrollbar.nb_rows = ceil(skillList.size() / pageSize.x)

func skillBoxBoundaryMoved(dir):
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * pageSize.x) < 0:
			cursor.play_sfx("cursor1")
			if pageYOffset > 0:
				updateSkills(pageYOffset - 1)
			else:
				if skillList.size() > pageSize.x * pageSize.y:
					updateSkills(ceil(skillList.size() / pageSize.x) - pageSize.y)
				var xPos = posmod(cursor.cursor_index, int(pageSize.x))
				var yPos = ceil((skillList.size() - xPos) / pageSize.x) - 1
				cursor.set_cursor_from_index((yPos - pageYOffset) * pageSize.x + xPos, false)
		elif cursor.cursor_index + (dir.y * pageSize.x) >= min(pageSize.x * pageSize.y, skillList.size() - pageYOffset * pageSize.x):
			cursor.play_sfx("cursor1")
			if (pageYOffset + pageSize.y) * pageSize.x < skillList.size():
				updateSkills(pageYOffset + 1)
			else:
				updateSkills(0)
				cursor.set_cursor_from_index(posmod(cursor.cursor_index, int(pageSize.x)), false)
		scrollbar.position = pageYOffset
	if dir.x != 0:
		cursor.play_sfx("cursor1")
		var xPos = posmod(int(cursor.cursor_index + dir.x), int(pageSize.x))
		var yPos = floor(cursor.cursor_index / pageSize.x)
		cursor.set_cursor_from_index(yPos * pageSize.x + xPos, false)

