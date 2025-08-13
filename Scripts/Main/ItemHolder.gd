extends "res://Scripts/Main/FlaggableObject.gd"

export (String) var item = ""
export (String) var dialog = ""
export (String) var dialog_full = ""
export (String) var dialog_empty = ""
export (NodePath) onready var button_prompt

var player_turn = { 
	"y": true,
	"x": true
}

func _ready():
	reset_when_leaving_region = false
	if !Engine.is_editor_hint():
		_update_state()
		if dialog == "":
			dialog = "ItemDescriptions/itemcheck"
		if dialog_full == "":
			dialog_full = "ItemDescriptions/itemfull"

func interact():
	if not _get_flag_status():
		_check_item()
	else:
		_warn_empty()

# Overridden
func _check_item():
	_play_interact()
	global.item = InventoryManager.Load_item_data(item)
	if item and (InventoryManager.has_inventory_space() or InventoryManager.Load_item_data(item)["keyitem"]):
		_play_collect_item()
		InventoryManager.add_item_available(item)
		_set_flag_status()
		_update_state()
		global.set_dialog(dialog)
		uiManager.open_dialogue_box()
	elif !item:
		_play_revert()
		_warn_empty()
	else:
		_play_revert()
		global.set_dialog(dialog_full)
		uiManager.open_dialogue_box()

func _warn_empty():
	if (dialog_empty != ""):
		global.set_dialog("ItemDescriptions/presentempty") 
		uiManager.open_dialogue_box()

# Overridden
func _update_state():
	pass

# Overridden
func _play_interact():
	pass

# Overridden
func _play_collect_item():
	pass

# Overridden
func _play_revert():
	pass
