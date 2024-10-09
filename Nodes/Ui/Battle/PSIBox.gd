extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var info_box

onready var animation_player = $AnimationPlayer

const CAT_OFFENSE = "Offense"
const CAT_RECOVERY = "Recovery"
const CAT_ASSIST = "Assist"

const skill_list = {
	CAT_OFFENSE: [],
	CAT_RECOVERY: [],
	CAT_ASSIST: []
}

var sound_effects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav")
}

var categories = [CAT_OFFENSE, CAT_RECOVERY, CAT_ASSIST]

var recent_choice_cat = {}
var recent_choice_pagination = {}
var recent_choice_psi = {}
var current_chara

func _ready():
	info_box = get_node_or_null(info_box)
	$PSISelect.connect("selected", self, "selectSkill")
	$PSISelect.connect("moved", self, "_on_cursor_moved_to_psi")

func _input(event):
	if visible and $PSISelect._active:
		if Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			get_tree().set_input_as_handled()
			audioManager.play_sfx(sound_effects["back"], "BattleSfx")
			
			$PSISelect.set_active(false)
			$PSISelect.set_PP_visible(false)
			cursor.on = true
			if info_box != null and info_box.infoOnScreen:
				info_box.deactivate()
				#info_box.hide()

func enter(reset = false, _action = null):
	.enter(reset, _action)
	animation_player.play("Open")
	if reset:
		# set user here so psi select knows when the user doesn't have enough pp
		$PSISelect.user = action.user.stats
		current_chara = action.user.stats.name
		updatePSI(action.user.stats.learnedSkills)
		
		yield(get_tree(), "idle_frame")
		
		#Default on Recovery first for quick access to Lifeup (YOU'RE WELCOME)
		var cur_idx = 0
		if recent_choice_cat.has(current_chara):
			cur_idx = recent_choice_cat[current_chara]
		else:
			for i in [CAT_RECOVERY, CAT_OFFENSE, CAT_ASSIST]:
				if skill_list[i].size() > 0:
					cur_idx = categories.find(i)
					break
		cursor.set_cursor_from_index(cur_idx, false)
		
		updateSkillsBox()
		$PSISelect.set_active(false)
		$PSISelect.set_PP_visible(false, false)
		if info_box != null:
			info_box.deactivate()
	else:
		$PSISelect.set_active(true, false)
		$PSISelect.set_PP_visible(true)
		info_box.activate()
		cursor.on = false

func exit():
	.exit()
	$PSISelect.reset()

func hide():
	if visible:
		animation_player.play("Close")
	.hide()
	if info_box != null:
		info_box.deactivate()
		#info_box.hide()

func move(dir):
	recent_choice_cat[current_chara] = cursor.cursor_index
	updateSkillsBox()

func select(idx):
	# first, check if there's even a skill here lmao
	if skill_list[categories[cursor.cursor_index]].empty():
		return
	cursor.on = false
	if recent_choice_psi.has(current_chara) and recent_choice_psi[current_chara].category == categories[cursor.cursor_index]:
		$PSISelect.set_cursor_to_skill(recent_choice_psi[current_chara])
	else:
		$PSISelect.set_cursor_to_skill(null)
	
	$PSISelect.set_active(true, false)
	$PSISelect.set_PP_visible(true)
	if info_box != null:
		info_box.activate()

func updatePSI(skills):
	#clear skills
	for i in skill_list:
		skill_list[i].clear()
	for skillName in skills:
		var skill = globaldata.skills[skillName]
		if skill.has("category"):
			if skill.useCases > -1: # -1 is field only
				skill_list[skill.category].append(skillName)
	if skill_list[CAT_OFFENSE].empty():
		$VBox/Label1.hide()
		#$VBox/Label1.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label1.show()
		#$VBox/Label1.set_self_modulate(Color.white)
	if skill_list[CAT_RECOVERY].empty():
		$VBox/Label2.hide()
		#$VBox/Label2.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label2.show()
		#$VBox/Label2.set_self_modulate(Color.white)
	if skill_list[CAT_ASSIST].empty():
		$VBox/Label3.hide()
		#$VBox/Label3.set_self_modulate(Color("bfb4cd"))
	else:
		$VBox/Label3.show()
		#$VBox/Label3.set_self_modulate(Color.white)

func updateSkillsBox():
	var psi_select_page = 0
	if recent_choice_pagination.has(current_chara) and recent_choice_psi[current_chara].category == categories[cursor.cursor_index]:
		psi_select_page = recent_choice_pagination[current_chara]
	var category = categories[cursor.cursor_index]
	$PSISelect.updateSkills(skill_list[category], psi_select_page)

func selectSkill(skill):
	$PSISelect.set_active(false, false)
	$PSISelect.set_PP_visible(false)
	if info_box != null:
		info_box.deactivate()
	action.skill = skill
	emit_signal("next")

func _on_cursor_moved_to_psi(skill):
	if $PSISelect.is_active():
		recent_choice_pagination[current_chara] = $PSISelect.page
		recent_choice_psi[current_chara] = skill
	if info_box != null:
		var category = categories[cursor.cursor_index]
		info_box.update_info(tr(skill.description))

# useless?
#func _on_Arrow_moved_direction(dir):
#	move(dir)
