extends Control

const LEVEL_NAMES = "αβγΩ"

var _skill_name: String = ""
var _levels: Dictionary # key = level, value = selectable
var _box: HBoxContainer
var _name_label: Label
var _cursor

func init(skill, cursor):
	_box = $HBox
	_name_label = $Name
	_levels = {}
	_cursor = cursor

	name = skill.name
	_skill_name = skill.name
	_name_label.text = skill.name
	_name_label.modulate = Color.darkgray
	
	#reset levels
	for i in _box.get_child_count():
		var node = _box.get_child(i)
		node.text = ""
		node.hide()
	
	if !"level" in skill:
		addLevel(0)
	else:
		addLevel(skill.level, false)

func addLevel(level: int, selectable: bool = true):
	_levels[level] = selectable
	_refresh_nodes()

func addLevels(levels: Array):
	for level in levels:
		_levels[level] = true
	_refresh_nodes()

func _refresh_nodes():
	var level_values = _levels.keys()
	level_values.sort()
	for i in level_values.size():
		var node = _box.get_child(i)
		if i < level_values.size():
			node.show()
		node.text = LEVEL_NAMES[level_values[i]]
		var selectable = _levels[level_values[i]]
		if selectable:
			node.modulate = Color.white
			_name_label.modulate = Color.white
		else:
			node.modulate = Color.darkgray

	if is_inside_tree():
		force_update_transform()

func get_hbox():
	return _box

func get_skill_name():
	return _skill_name

func get_selected_level():
	var level_values = _levels.keys()
	level_values.sort()
	if _cursor and _cursor.cursor_index < _levels.size():
		return level_values[_cursor.cursor_index]
	else:
		return -1
