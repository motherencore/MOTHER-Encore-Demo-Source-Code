extends NinePatchRect

const psiSkillLineTscn = preload("res://Nodes/Ui/PSISkillLine.tscn")

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
}

export(int) var linesPerPage = 3
enum PSIType {Overworld = -1, Both, Battle}
export(PSIType) var psiType = 1

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
	for i in linesPerPage:
		var line = psiSkillLineTscn.instance()
		lines.append(line)
		$MarginContainer/VBoxContainer.add_child(line)
	cursor.on = false
	cursor.hide()
	$PPCost.hide()
	cursor.connect("selected", self, "_cursorSelected")
	cursor.connect("moved", self, "_cursorMovedToSkill")

func _physics_process(delta):
	if _active:
		if Input.is_action_just_pressed("ui_down"):
			$Arrow.play_sfx("cursor1")
			setLineActive(index + 1)
		elif Input.is_action_just_pressed("ui_up"):
			$Arrow.play_sfx("cursor1")
			setLineActive(index - 1)

func setActive(active, reset = true):
	_active = active
	if skills.size() > 0:
		cursor.visible = active
		cursor.on = active

func set_PP_visible(enabled):
	$PPCost.visible = enabled

func reset():
	setLineActive(0)
	_onBoxSort()

func setLineActive(i):
	var diff = i - index
	if i + page >= skillsCondensed.size() or  i + page < 0:
		return
	elif i < 0:
		updatePage(-1)
	elif i >= lines.size():
		updatePage(+1)
	else:
		index = i
	# set cursor in place
	cursor.menu_parent = lines[index].box
	cursor.set_cursor_from_index(min(cursor.cursor_index, cursor.get_max() - 1))
	_cursorMovedToSkill(Vector2(i, 0))

func updateSkills(newSkills):
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
	skillsCondensed = condenseSkills()
	page = 0
	updatePage(0)
	setLineActive(0)
	if !lines[index].box.get_signal_connection_list("sort_children").empty():
		lines[index].box.disconnect("sort_children", self, "_onBoxSort")
	lines[index].box.connect("sort_children", self, "_onBoxSort", [], CONNECT_ONESHOT)
#	_onBoxSort()
	cursorTo0 = true

func updatePage(dir):
	page += dir
	
	for i in linesPerPage:
		var line = lines[i]
		if i + page >= skillsCondensed.size():
			line.hide()
		else:
			line.show()
			line.init(skillsCondensed[i + page][0])
			for skill in skillsCondensed[i + page]:
				line.addLevel(skill.level, _doesItDoAnything(skill))
	if page > 0:
		$UpArrow.show()
	else:
		$UpArrow.hide()
	if page + linesPerPage < skillsCondensed.size():
		$DownArrow.show()
	else:
		$DownArrow.hide()

func condenseSkills():
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

func updatePPCost(skill):
	if "ppCost" in skill:
		$PPCost/Label2.text = str(skill.ppCost)
	else:
		$PPCost/Label2.text = "0"

func _cursorSelected(i):
	for skill in skills:
		if skill.name == lines[index].name and "level" in skill and skill.level == i:
			if !_doesItDoAnything(skill):
				audioManager.play_sfx(soundEffects["cursor2"], "cursor")
				break
			audioManager.play_sfx(soundEffects["cursor2"], "cursor")
			if skill.name == "Telepathy":
				emit_signal("use", skill)
			else:
				emit_signal("selected", skill)
			break

func _onBoxSort():
	if cursorTo0:
		cursorTo0 = false
		cursor.set_cursor_from_index(0, false)

func _doesItDoAnything(skill):
	# check if we have enough pp
	if user and skill.ppCost <= user.pp:
		return true
	else:
		return false


func _cursorMovedToSkill(dir):
	for skill in skills:
		if skill.name == lines[index].name and "level" in skill and skill.level == cursor.cursor_index:
			if dir.x != 0:
				$Arrow.play_sfx("cursor1")
			updatePPCost(skill)
			emit_signal("moved", skill)
			break
