extends BattleMenuBox

export(NodePath) var nameBox

const _actions = ["Basic", "Skills", "PSI", "Items", "Defend", "Run"]
var _active_actions = ["Basic", "", "", "Items", "Defend", ""]
var _basic_action: Dictionary = globaldata.skills["attack"]
onready var _icons = $ActionIcons.get_children()

func _ready():
	nameBox = get_node_or_null(nameBox)

func enter(reset = false, _action = null):
	.enter(reset, _action)
	if reset:
		var i = 0
		for action in _active_actions:
			if action != "":
				break
			i += 1
		cursor.set_cursor_from_index(i, false)
	if nameBox != null:
		nameBox.show()
	_update_name_box()

func hide():
	.hide()
	cursor.on = false
	if nameBox != null:
		nameBox.hide()

func move(dir):
	var original = cursor.cursor_index
	var i = original
	# try to the right
	while _active_actions[i] == "":
		if dir.x > 0:
			if i == _actions.size() - 1:
				print("Outta bounds! wtf")
				i = 0
			else:
				i += 1
		# try to the left
		elif dir.x < 0:
			if i == 0:
				print("Outta bounds again! wtf")
				i = _active_actions.size() - 1
			else:
				i -= 1
	
	if i != original:
		cursor.set_cursor_from_index(i)
#		if i < original:
#			return
	#	play_sfx("cursor1")
	_update_name_box()

func select(i):
	emit_signal("next", _actions[i])

func add_action(action):
	var idx = _actions.find(action)
	if idx > -1:
		_active_actions[idx] = action
		_icons[idx].show()
		_icons[idx].modulate = Color.white
	else:
		print("Added Action %s doesn't exist :(" % action)

func reset_actions():
	for icon in _icons:
		icon.hide()
	for i in range(_active_actions.size()):
		_active_actions[i] = ""
	for action in ["Basic", "Defend", "Items"]:
		add_action(action)

func add_unselectable_actions(newActions):
	for action in newActions:
		var idx = _actions.find(action)
		if idx > -1:
			_active_actions[idx] = ""
			_icons[idx].modulate = Color.darkgray

func set_basic_action(action_id: String):
	_basic_action = globaldata.skills[action_id]
	_update_name_box()

func _update_name_box():
	var action_id = _active_actions[cursor.cursor_index]
	if nameBox != null:
		if action_id == "Basic":
			nameBox.get_child(0).text = _basic_action.name
		else:
			nameBox.get_child(0).text = "BATTLE_ACTION_" + action_id.to_upper()
