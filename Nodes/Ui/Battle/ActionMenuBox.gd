extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export(NodePath) var nameBox

const actions = ["Bash", "Skills", "PSI", "Items", "Defend", "Run"]
var activeActions = ["Bash", "", "", "Items", "Defend", ""]
onready var icons = $ActionIcons.get_children()

func _ready():
	nameBox = get_node_or_null(nameBox)

func enter(reset = false, _action = null):
	.enter(reset, _action)
	if reset:
		var i = 0
		for action in activeActions:
			if action != "":
				break
			i += 1
		cursor.set_cursor_from_index(i, false)
	if nameBox != null:
		nameBox.show()
		# LOCALIZATION Code change: Get the localized text for this action
		nameBox.get_child(0).text = _getActionName(activeActions[cursor.cursor_index])

func hide():
	.hide()
	if nameBox != null:
		nameBox.hide()

func move(dir):
	var original = cursor.cursor_index
	var i = original
	# try to the right
	while activeActions[i] == "":
		if dir.x > 0:
			if i == actions.size() - 1:
				print("Outta bounds! wtf")
				i = 0
			else:
				i += 1
		# try to the left
		elif dir.x < 0:
			if i == 0:
				print("Outta bounds again! wtf")
				i = activeActions.size() - 1
			else:
				i -= 1
	
	if i != original:
		cursor.set_cursor_from_index(i)
#		if i < original:
#			return
	#	play_sfx("cursor1")
	if nameBox != null:
		# LOCALIZATION Code change: Get the localized text for this action
		nameBox.get_child(0).text = _getActionName(activeActions[cursor.cursor_index])

func select(i):
	emit_signal("next", actions[i])

func addAction(action):
	var idx = actions.find(action)
	if idx > -1:
		activeActions[idx] = action
		icons[idx].show()
		icons[idx].modulate = Color.white
	else:
		print("Added Action ", action, " doesn't exist :(")

func addActions(newActions):
	for action in newActions:
		addAction(action)

func resetActions():
	for icon in icons:
		icon.hide()
	for i in range(activeActions.size()):
		activeActions[i] = ""
	addActions(["Bash", "Defend", "Items"])

func addUnselectableActions(newActions):
	for action in newActions:
		var idx = actions.find(action)
		if idx > -1:
			activeActions[idx] = ""
			icons[idx].modulate = Color.darkgray

# LOCALIZATION Code added: Use of csv keys for battle menu actions
func _getActionName(actionId):
	return "BATTLE_ACTION_" + actionId.to_upper()
