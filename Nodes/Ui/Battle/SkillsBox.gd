extends BattleMenuBox

export (NodePath) var infoBox

const PAGE_SIZE = Vector2(2, 3)

onready var animationPlayer = $AnimationPlayer
onready var scrollbar = $Scrollbar

var _page_y_offset = 0
var _skill_list = []

var _recent_choice_pagination = {}
var _recent_choice_skill = {}
var _current_chara

func _ready():
	infoBox = get_node_or_null(infoBox)
	cursor.connect("failed_move", self, "_box_boundary_moved")
	scrollbar.nb_visible_rows = PAGE_SIZE.y
	global.connect("locale_changed", self, "_update_info_box")

func enter(reset = false, _action = null):
	.enter(reset, _action)
	animationPlayer.play("Open")
	scrollbar.on = true
	if reset:
		_skill_list.clear()
		for skillName in action.user.stats.learnedSkills:
			var skill = globaldata.skills[skillName]
			if skill.has("skillType") and skill.skillType == "skill":
				_skill_list.append(skill)
		_current_chara = action.user.stats.name
		_page_y_offset = _recent_choice_pagination.get(_current_chara, 0)
		scrollbar.position = _page_y_offset
		update_skills(_page_y_offset)
		cursor.set_cursor_from_index(_recent_choice_skill.get(_current_chara, 0), false)
	if infoBox != null and !_skill_list.empty():
		infoBox.activate()

func hide():
	if visible:
		animationPlayer.play("Close")
	.hide()
	scrollbar.on = false
	if infoBox != null:
		infoBox.deactivate()

func move(dir):
	if _skill_list.size() - 1 < cursor.cursor_index + _page_y_offset * PAGE_SIZE.x:
		cursor.cursor_index = _skill_list.size() - _page_y_offset * PAGE_SIZE.x - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !_skill_list.empty():
		var skillIdx = cursor.cursor_index + _page_y_offset * PAGE_SIZE.x
		# if we move to skill that doesn't exist, move back
		if skillIdx > _skill_list.size() - 1:
			cursor.set_cursor_from_index((int(_skill_list.size()) % int(PAGE_SIZE.x)) - 1, false)
		_update_info_box()
		_recent_choice_pagination[_current_chara] = _page_y_offset
		_recent_choice_skill[_current_chara] = cursor.cursor_index

func select(idx):
	if !_skill_list.empty():
		action.skill = _skill_list[idx + _page_y_offset * PAGE_SIZE.x]
		emit_signal("next")

func update_skills(yOffset):
	_page_y_offset = yOffset
	var skillsOnPage = _skill_list.slice(_page_y_offset * PAGE_SIZE.x, _page_y_offset * PAGE_SIZE.x + PAGE_SIZE.x * PAGE_SIZE.y)
	for skillLabel in $GridContainer.get_children():
		if skillsOnPage.empty():
			skillLabel.text = ""
		else:
			var skill = skillsOnPage.pop_front()
			skillLabel.text = skill.name
	
	move(0)
	
	scrollbar.nb_rows = ceil(_skill_list.size() / PAGE_SIZE.x)

func _box_boundary_moved(dir):
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * PAGE_SIZE.x) < 0:
			cursor.play_sfx("cursor1")
			if _page_y_offset > 0:
				update_skills(_page_y_offset - 1)
			else:
				if _skill_list.size() > PAGE_SIZE.x * PAGE_SIZE.y:
					update_skills(ceil(_skill_list.size() / PAGE_SIZE.x) - PAGE_SIZE.y)
				var xPos = posmod(cursor.cursor_index, int(PAGE_SIZE.x))
				var yPos = ceil((_skill_list.size() - xPos) / PAGE_SIZE.x) - 1
				cursor.set_cursor_from_index((yPos - _page_y_offset) * PAGE_SIZE.x + xPos, false)
		elif cursor.cursor_index + (dir.y * PAGE_SIZE.x) >= min(PAGE_SIZE.x * PAGE_SIZE.y, _skill_list.size() - _page_y_offset * PAGE_SIZE.x):
			cursor.play_sfx("cursor1")
			if (_page_y_offset + PAGE_SIZE.y) * PAGE_SIZE.x < _skill_list.size():
				update_skills(_page_y_offset + 1)
			else:
				update_skills(0)
				cursor.set_cursor_from_index(posmod(cursor.cursor_index, int(PAGE_SIZE.x)), false)
		scrollbar.position = _page_y_offset
	if dir.x != 0:
		cursor.play_sfx("cursor1")
		var xPos = posmod(int(cursor.cursor_index + dir.x), int(PAGE_SIZE.x))
		var yPos = floor(cursor.cursor_index / PAGE_SIZE.x)
		cursor.set_cursor_from_index(yPos * PAGE_SIZE.x + xPos, false)

func _update_info_box():
	if visible and infoBox != null:
		var description = _skill_list[cursor.cursor_index + _page_y_offset * PAGE_SIZE.x].description
		infoBox.update_info(tr(description))
