extends PanelContainer

const CharSelect = preload("res://Nodes/Ui/Inventory/InventorySelect.gd")
const Scrollbar = preload("res://Scripts/UI/Reusables/Scrollbar.gd")
const PSISkillLine = preload("res://Scripts/UI/PSISkillLine.gd")
const Cursor = preload("res://Scripts/UI/cursor.gd")

export (NodePath) onready var char_select_view = get_node(char_select_view) as CharSelect
export (NodePath) onready var tab_view = get_node(tab_view) as Node
export (NodePath) onready var scroll_view = get_node(scroll_view) as Control
export (NodePath) onready var scroll_bar_view = get_node(scroll_bar_view) as Scrollbar
export (NodePath) onready var grid_view = get_node(grid_view) as GridContainer
export (NodePath) onready var description_label = get_node(description_label) as RichTextLabel
export (NodePath) onready var pp_cost_view = get_node(pp_cost_view) as Node
export (NodePath) onready var pp_cost_label = get_node(pp_cost_label) as Label
export (NodePath) onready var tabs_cursor = get_node(tabs_cursor) as Cursor
export (NodePath) onready var grid_cursor = get_node(grid_cursor) as Cursor
export (NodePath) onready var skill_template = get_node(skill_template) as Label
export (NodePath) onready var psi_template = get_node(psi_template) as PSISkillLine

signal exited()

enum TABS {FIELD, BATTLE, PSI}

var _is_active = false
var _listed_skills = []

var current_character = globaldata.ninten setget _set_character

func _ready():
	char_select_view.show()
	char_select_view.active = true
	global.connect("locale_changed", self, "_update_description")
	char_select_view.connect("character_changed", self, "_on_character_changed")
	tabs_cursor.connect("moved", self, "_on_tabs_cursor_move")
	tabs_cursor.connect("selected", self, "_on_tabs_cursor_selected")
	grid_cursor.connect("moved", self, "_on_grid_cursor_move")
	grid_cursor.connect("failed_move", self, "_on_grid_cursor_failed_move")
	grid_cursor.connect("cancel", self, "_on_grid_cursor_cancel")

func _set_character(val):
	current_character = val
	char_select_view.InitFromCharacter(current_character.name)
	if _is_active:
		_on_character_changed(current_character.name)

func activate():
	_is_active = true
	tabs_cursor.on = true
	grid_cursor.on = false
	yield(get_tree(), "idle_frame")
	tabs_cursor.set_cursor_from_index(0)
	show()
	_update_grid()

func _deactivate():
	_is_active = false
	tabs_cursor.on = false
	grid_cursor.on = false
	hide()

func _input(event):
	if _is_active:
		if event.is_action_pressed("ui_cancel"):
			if !grid_cursor.on:
				get_tree().set_input_as_handled()
				_deactivate()
				emit_signal("exited")
				tabs_cursor.play_sfx("back")

func _on_character_changed(character):
	for member in global.party:
		if member.name == character:
			current_character = member
			_update_tabs()
			_update_grid()
			return

func _on_tabs_cursor_move(dir):
	_update_grid(true)

func _on_tabs_cursor_selected(index):
	if grid_view.get_child_count() > 0:
		tabs_cursor.play_sfx("cursor2")
		tabs_cursor.on = false
		grid_cursor.on = true
		grid_cursor.show()
		_update_scroll()
		_update_description()

func _on_grid_cursor_move(dir):
	_update_scroll()
	_update_description()

func _on_grid_cursor_failed_move(dir):
	if tabs_cursor.cursor_index == TABS.PSI and grid_view.get_child_count() > 0:
		if dir.y != 0:
			var index_in_levels = grid_cursor.cursor_index
			var index_in_list = _get_psi_list_index()
			index_in_list = posmod(index_in_list + dir.y, grid_view.get_child_count())
			grid_cursor.menu_parent = grid_view.get_child(index_in_list).box
			grid_cursor.set_cursor_from_index(index_in_levels)
			grid_cursor.play_sfx("cursor1")
			_update_scroll()
			_update_description()

func _on_grid_cursor_cancel():
	get_tree().set_input_as_handled()
	tabs_cursor.on = true
	grid_cursor.on = false
	grid_cursor.hide()
	_update_description()

func _update_tabs():
	if current_character.maxpp == 0:
		tab_view.get_child(TABS.PSI).add_color_override("font_color", Color.darkgray)
	else:
		tab_view.get_child(TABS.PSI).add_color_override("font_color", Color.white)

func _update_grid(change_tab = false):
	_fill_skill_data()

	for old_item in grid_view.get_children():
		grid_view.remove_child(old_item)
		old_item.queue_free()

	grid_view.columns = 1 if tabs_cursor.cursor_index == TABS.PSI else 2

	for skill in _listed_skills:
		if tabs_cursor.cursor_index == TABS.PSI:
			var new_item = psi_template.duplicate()
			new_item.init(skill[0])
			for level in skill:
				new_item.addLevel(level)
			grid_view.add_child(new_item)
		else:
			var new_item = skill_template.duplicate()
			new_item.text = skill.name
			grid_view.add_child(new_item)

	grid_cursor.visible = !_listed_skills.empty() and grid_cursor.on

	if tabs_cursor.cursor_index != TABS.PSI or _listed_skills.empty():
		grid_cursor.menu_parent = grid_view
	else:
		grid_cursor.menu_parent = grid_view.get_children()[0].box

	if change_tab:
		grid_cursor.cursor_index = 0
	else:
		grid_cursor.cursor_index = clamp(grid_cursor.cursor_index, 0, grid_cursor.get_last_available_idx())

	scroll_view.rect_min_size.y = 68 if tabs_cursor.cursor_index == TABS.FIELD else 82

	yield(get_tree(), "idle_frame")
	_update_scroll()
	_update_description()

func _fill_skill_data():
	_listed_skills = []

	match tabs_cursor.cursor_index:
		TABS.FIELD:
			for skill_id in globaldata.fieldSkills:
				var skill = globaldata.fieldSkills[skill_id]
				if skill.usable[current_character.name] and (skill.flag == "" or globaldata.flags[skill.flag]):
					_listed_skills.append(skill)
		TABS.BATTLE:
			for skill_id in current_character.learnedSkills:
				var skill = globaldata.skills.get(skill_id)
				if skill != null and skill.skillType != "psi":
					_listed_skills.append(skill)
		TABS.PSI:
			var skill_dict = {}
			for skill_id in current_character.learnedSkills:
				var skill = globaldata.skills.get(skill_id)
				if skill != null and skill.skillType == "psi":
					if !skill.name in skill_dict:
						skill_dict[skill.name] = {}
					var level = int(skill.level) if "level" in skill else 0
					skill_dict[skill.name][level] = skill
			_listed_skills = skill_dict.values()

func _update_scroll():
	var selected_item = grid_cursor.get_current_item()
	if selected_item:
		selected_item.grab_focus()
		yield(get_tree(), "idle_frame")
		grid_cursor.set_cursor_from_index(grid_cursor.cursor_index)
	scroll_bar_view.update_from_scroll_view(scroll_view)	

func _update_description():
	if grid_cursor.on and grid_cursor.cursor_index != -1 and grid_cursor.cursor_index <= grid_cursor.get_last_available_idx():
		var skill
		if tabs_cursor.cursor_index == TABS.PSI:
			skill = _listed_skills[_get_psi_list_index()][grid_cursor.cursor_index]
		else:
			skill = _listed_skills[grid_cursor.cursor_index]
		if skill:
			description_label.bbcode_text = globaldata.replaceText(skill.description)
			if "skillType" in skill and skill.skillType == "psi":
				if !pp_cost_view.visible:
					pp_cost_view.get_node("AnimationPlayer").play("ShowPP")
				pp_cost_label.text = str(skill.ppCost)
			else:
				if pp_cost_view.visible:
					pp_cost_view.get_node("AnimationPlayer").play("HidePP")
			return

	description_label.text = ""
	if pp_cost_view.visible:
		pp_cost_view.get_node("AnimationPlayer").play("HidePP")
	
func _get_psi_list_index():
	return grid_view.get_children().find(grid_cursor.menu_parent.get_parent())
