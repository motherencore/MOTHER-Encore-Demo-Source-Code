extends NinePatchRect

const psiSkillLineTscn = preload("res://Nodes/Ui/PSISkillLine.tscn")

enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
}

export(int) var linesPerPage = 3 setget _set_lines_per_page
enum PSIType {Overworld = -1, Both, Battle}
export(PSIType) var psiType = 1

onready var animationPlayer = $PP/AnimationPlayer
onready var scroll_bar = $Scrollbar

var skills = []
var skillsCondensed = []
var lines = []
var _active = false
var index = 0
var page = 0
onready var cursor = $Arrow
var cursorTo0 = false
var user

signal moved
signal selected
signal use

func _ready():
	_build_node_list()
	cursor.on = false
	cursor.hide()
	cursor.connect("selected", self, "_cursor_selected")
	cursor.connect("moved", self, "_cursor_moved_to_skill")
	global.connect("locale_changed", self, "_cursor_moved_to_skill")

func _set_lines_per_page(value):
	if linesPerPage != value:
		linesPerPage = value
		_build_node_list()
		if index >= linesPerPage:
			_update_page(+1)
			_set_line_active(index - 1, false)
		elif page + linesPerPage > lines.size():
			_update_page(-1)
			_set_line_active(index + 1, false)
		else:
			_update_page(0)

func _build_node_list():
	var child_count = $MarginContainer/VBoxContainer.get_child_count()
	for i in range(child_count, linesPerPage):
		var line = psiSkillLineTscn.instance()
		lines.append(line)
		$MarginContainer/VBoxContainer.add_child(line)
	for i in child_count:
		$MarginContainer/VBoxContainer.get_child(i).visible = (i < linesPerPage)

func set_active(active, reset = true):
	_active = active
	if skills.size() > 0:
		cursor.visible = active
		cursor.on = active

func is_active():
	return _active

func set_PP_visible(enabled, animated = true):
	if animated:
		if enabled and !$PP/PPCost.visible:
			animationPlayer.play("ShowPP")
		elif !enabled and $PP/PPCost.visible:
			animationPlayer.play("HidePP")
	else:
		$PP/PPCost.visible = enabled

func reset():
	_set_line_active(0, false)
	_on_box_sort()

func _set_line_active(i, play_sfx=true):
	if i >= 0 and i < linesPerPage and i < skillsCondensed.size(): # no scroll, no loop
		index = i
	else:
		if i + page >= skillsCondensed.size(): # loop up
			i = 0
			index = 0
			_update_page(+1)
		elif i + page < 0: # loop down
			i = min(skillsCondensed.size(), linesPerPage) - 1
			index = i
			_update_page(-1)
		elif i < 0: # scroll up (no loop)
			_update_page(-1)
		elif i >= lines.size(): # scroll down (no loop)
			_update_page(+1)
	
	# set cursor in place
	cursor.menu_parent = lines[index].box
	cursor.set_cursor_from_index(min(cursor.cursor_index, cursor.get_last_available_idx()))
	if play_sfx:
		cursor.play_sfx("cursor1")
	_cursor_moved_to_skill(Vector2(i, 0))

func updateSkills(newSkills, new_page = 0):
	#clear out skills and add new skills
	skills.clear()
	for skill in newSkills:
		skill = globaldata.skills[skill]
		if skill.skillType == "psi":
			match(psiType):
				PSIType.Overworld:
					if (skill.useCases <= 0):
						skills.append(skill)
				PSIType.Battle:
					if (skill.useCases >= 0):
						skills.append(skill)
				_:
					skills.append(skill)
	skillsCondensed = _condense_skills()
	page = new_page
	_update_page(0)
	_set_line_active(0, false)
	if !lines[index].box.get_signal_connection_list("sort_children").empty():
		lines[index].box.disconnect("sort_children", self, "_on_box_sort")
	lines[index].box.connect("sort_children", self, "_on_box_sort", [], CONNECT_ONESHOT)
#	_on_box_sort()
	cursorTo0 = true

func refresh_selectable():
	_update_page(0)

func set_cursor_to_skill(skill):
	if skill != null:
		for i in skillsCondensed.size():
			if skill.name == skillsCondensed[i][0].name:
				_set_line_active(i - page, false)
				for j in skillsCondensed[i].size():
					if skill.level == skillsCondensed[i][j].level:
						cursor.set_cursor_from_index(j, false)
						return
				cursor.set_cursor_from_index(0, false)
				return
		_update_pp_cost(skill)
	_set_line_active(0, false)
	cursor.set_cursor_from_index(0, false) #(cursor.cursor_index)


func _update_page(dir):
	page += dir

	var maxPage = skillsCondensed.size() - linesPerPage
	if maxPage <= 0:
		page = 0
	else:
		page = posmod(page, maxPage + 1)
	
	for i in linesPerPage:
		var line = lines[i]
		if i + page >= skillsCondensed.size():
			line.hide()
		else:
			line.show()
			line.init(skillsCondensed[i + page][0])
			for skill in skillsCondensed[i + page]:
				line.addLevel(skill.level, _does_it_do_anything(skill))
	
	if scroll_bar:
		scroll_bar.nb_rows = skillsCondensed.size()
		scroll_bar.nb_visible_rows = linesPerPage
		scroll_bar.position = page

func _condense_skills():
	var condensedArray = []
	# For each new KIND of skill (e.g. Lifeup), put into skillBase
	for skill in skills:
		var newSkill = true
		# If this skill is already in, add this other level to the same array
		for skillBase in condensedArray:
			if skillBase[0].name == skill.name:
				skillBase.append(skill)
				newSkill = false
		if newSkill:
			condensedArray.append([skill])
	
	return condensedArray


func _update_pp_cost(skill):
	if "ppCost" in skill:
		$PP/PPCost/Label2.text = str(skill.ppCost)
	else:
		$PP/PPCost/Label2.text = "0"

func _cursor_selected(i):
	for skill in skills:
		if skill.name == lines[index].skillName and "level" in skill and skill.level == i:
			if !_does_it_do_anything(skill):
				break
			if skill.targetType == TargetType.SELF:
				emit_signal("use", skill)
			else:
				emit_signal("selected", skill)
			break

func _on_box_sort():
	if cursorTo0:
		cursorTo0 = false
		cursor.set_cursor_from_index(0, false)

func _does_it_do_anything(skill):
	# check if we have enough pp
	if user and skill.ppCost <= user.pp:
		return true
	else:
		return false


func _cursor_moved_to_skill(dir = 0):
	for skill in skills:
		if skill.name == lines[index].skillName and "level" in skill and skill.level == cursor.cursor_index:
			_update_pp_cost(skill)
			emit_signal("moved", skill)
			break


func _on_Arrow_failed_move(dir):
	if _active:
		if dir.y > 0:
			_set_line_active(index + 1)
		elif dir.y < 0:
			_set_line_active(index - 1)
