extends Control

signal back
signal exit
signal action_selected
signal swap_mode_selected (target_character)
signal sort_mode_selected
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, chara_name, value, stat, item)

enum ACTIONS {EQUIP=0, CHECK, USE, CONSUME, TRANSFORM, GIVE, SORT, DROP}

export (NodePath) onready var drop_label = get_node(drop_label) as Label
export (NodePath) onready var give_label = get_node(give_label) as Label
export (NodePath) onready var sort_label = get_node(sort_label) as Label
export (NodePath) onready var action_one_label = get_node(action_one_label) as Label
export (NodePath) onready var action_two_label = get_node(action_two_label) as Label

onready var _arrow = $arrow

var _item_side_on_screen = 1
var _is_equipable = false
var _active = false
var _current_char = "ninten"
var _current_item_idx = -1
var _current_item_name = ""

var _possible_actions

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
func set_for_new_item(pos, item_name, item_side, curr_char, item_idx):
	_current_item_idx = item_idx
	_current_item_name = item_name
	_current_char = curr_char
	_item_side_on_screen = item_side
	rect_position = pos
#	rect_position.x = _item_side_on_screen*pos.x

	var is_key_item = InventoryManager.Load_item_data(item_name).get("keyitem", false)
	
	if !is_key_item and InventoryManager.is_usable_by(_current_char, item_name):
		_is_equipable = InventoryManager.is_equippable(item_name)
	else:
		_is_equipable = false
	_possible_actions = {}
	
	if !is_key_item and InventoryManager.Load_item_data(item_name).value != 0:
		_possible_actions[drop_label.name] = ACTIONS.DROP
		drop_label.visible = true
	else:
		drop_label.visible = false
	
	_possible_actions[sort_label.name] = ACTIONS.SORT
	
	if !is_key_item and global.party.size() > 1:
		_possible_actions[give_label.name] = ACTIONS.GIVE
		give_label.visible = true
	else:
		give_label.visible = false
	
	_set_actions()
	
	_arrow.cursor_index = 0
	_arrow.set_cursor_from_index(0, false)
	visible = true
	_active = true
	_arrow.on = true

func _set_actions():
	var item_data = InventoryManager.Load_item_data(_current_item_name)
	if item_data["action_two"] != null:
		if item_data["action_two"]["function"] == "equip":
			if _is_equipable:
				if InventoryManager.Inventories[_current_char][_current_item_idx].equiped == true:
					action_two_label.text = item_data["action_two"]["nametwo"]
				else:
					action_two_label.text = item_data["action_two"]["name"]
				action_two_label.visible = true
				_push_action(item_data["action_two"], action_two_label)
			else:
				action_one_label.visible = false
		else:
			action_two_label.text = item_data["action_two"]["name"]
			action_two_label.visible = true
			_push_action(item_data["action_two"], action_two_label)
	else:
		action_two_label.visible = false
	
	if item_data["action_one"] != null:
		if item_data["action_one"]["function"] == "equip":
			if _is_equipable:
				if InventoryManager.Inventories[_current_char][_current_item_idx].equiped == true:
					action_one_label.text = item_data["action_one"]["nametwo"]
				else:
					action_one_label.text = item_data["action_one"]["name"]
				action_one_label.visible = true
				_push_action(item_data["action_one"], action_one_label)
			else:
				action_one_label.visible = false
		else:
			action_one_label.text = item_data["action_one"]["name"]
			action_one_label.visible = true
			_push_action(item_data["action_one"], action_one_label)
	else:
		action_one_label.visible = false
	yield(get_tree(), "idle_frame")
	_arrow.set_cursor_to_front()
	


func _push_action(action, node):
	match action["function"]:
		"equip":
			_possible_actions[node.name] = ACTIONS.EQUIP
		"consume":
			_possible_actions[node.name] = ACTIONS.CONSUME
		"use":
			_possible_actions[node.name] = ACTIONS.USE
		"transform":
			_possible_actions[node.name] = ACTIONS.TRANSFORM

func _physics_process(_delta):
	if _active:
		if (_possible_actions[_arrow.get_current_item().name] == ACTIONS.EQUIP):
			if InventoryManager.Inventories[_current_char][_current_item_idx].equiped == false:
				emit_signal("show_statsbar", _current_char)
			else:
				emit_signal("show_statsbar", _current_char, true)
		else:
			emit_signal("hide_statsbar")
		
		
		if Input.is_action_just_pressed("ui_cancel"):
			_arrow.play_sfx("back")
			emit_signal("hide_statsbar")
			_close()
	
func chain_with_equip():
	$TargetCharaSelect.chain_with_equip()

func _on_TargetCharaSelect_back(to_inventory):
	if to_inventory:
		_close()
	else:
		_back_from_submenu()

func _back_from_submenu():
	_active = true
	_arrow.on = true
	bounce()

func _close():
	visible = false
	_active = false
	_arrow.on = false
	emit_signal("back")

func _on_ConfirmationSelect_back(accept, current_action, current_character, target_character, cur_item):
	if accept == true:
		match current_action:
			"drop":
				InventoryManager.dropItem(current_character,cur_item)
			"equip":
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
				InventoryManager.equip_item(target_character, cur_item)
				emit_signal("hide_statsbar")
			"equipgive": # give item and equip
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
				InventoryManager.give_item(current_character,target_character, cur_item)
				InventoryManager.equip_item(target_character, InventoryManager.Inventories[target_character].size()-1)
				emit_signal("hide_statsbar")
			"swap":
				emit_signal("swap_mode_selected", target_character)
			"SortManual":
				emit_signal("sort_mode_selected")		

		
		$TargetCharaSelect.visible = false
		$TargetCharaSelect.active = false
		_close()
	else:
		match current_action:
			"equip": #answered no to equip after swap
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				emit_signal("hide_statsbar")
				_close()
			"equipgive": #give item but don't equip
				InventoryManager.give_item(current_character,target_character, cur_item)
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				emit_signal("hide_statsbar")
				_close()
			"SortAuto":
				InventoryManager.sort_auto(current_character)
				_close()
			"swap":
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				_close()
			"drop":
				_back_from_submenu()
			"back":
				_back_from_submenu()

func bounce():
	$Tween.interpolate_property(self, "rect_position",
		rect_position - Vector2(0, 2), rect_position, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
	$Tween.start()

func _on_ActionSelect_visibility_changed():
	bounce()

func _on_ConfirmationSelect_visibility_changed():
	bounce()

func _on_SortTypeSelect_visibility_changed():
	bounce()


func _on_arrow_selected(cursor_index):
	Input.action_release("ui_accept")
	bounce()
	_active = false
	_arrow.on = false
	var action = ""
	if _arrow.get_current_item() == action_one_label:
		action = "action_one"
	elif _arrow.get_current_item() == action_two_label:
		action = "action_two"
	var item_data = InventoryManager.Load_item_data(_current_item_name)
	match(_possible_actions[_arrow.get_current_item().name]):
		ACTIONS.EQUIP:
			#equips an item
			if InventoryManager.Inventories[_current_char][_current_item_idx].equiped == false:
				InventoryManager.equip_item(_current_char, _current_item_idx)
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
			else:
				InventoryManager.unequip(_current_char, InventoryManager.Inventories[_current_char][_current_item_idx].ItemName)
				audioManager.play_sfx(load("res://Audio/Sound effects/EB/close.wav"), "menu")
			_close()
			emit_signal("hide_statsbar")
		ACTIONS.CONSUME:
			# (give => to whom, use => on whom, eat => who)
			var title = "INVENTORY_ACTION_TARGET"
			var action_name = item_data[action]["name"]
			if action_name == "INVENTORY_ACTION_USE":
				title = action_name + "_TARGET"
			#consume an item to recover hp and pp and boost some stats
			var targets_list = []
			for party_mem in global.party:
				if _can_item_target(item_data[action], party_mem):
					targets_list.append(party_mem.name)
			$TargetCharaSelect.show_target_chara_select(rect_position, _current_char, _current_item_idx, action, targets_list, title)
			
		ACTIONS.USE:
			var sub_view = null
			match item_data:
				globaldata.items.Ocarina:
					emit_signal("exit")
					uiManager.open_ocarina_screen()
				globaldata.items.Ruler:
					emit_signal("exit")
					global.receiver = globaldata.get(_current_char)
					global.set_dialog("ItemDescriptions/ruler")
					uiManager.open_dialogue_box()
			if sub_view:
				sub_view.connect("back", self, "_close")
			
		ACTIONS.TRANSFORM:
			#transforms an item into another
			InventoryManager.transform_item(_current_char, _current_item_idx)
			_close()
			emit_signal("show_dialogbox", "ACTION_RESULT_TRANSFORM_%s" % _current_item_name.to_upper())
		
		ACTIONS.GIVE:
			#summon targetCharaSelect
			# (give => to whom, use => on whom, eat => who)
			var targets_list = []
			for partyMem in global.party:
				if partyMem.name != _current_char:
					targets_list.append(partyMem.name)

			$TargetCharaSelect.show_target_chara_select(rect_position, _current_char, _current_item_idx, "give", targets_list, "INVENTORY_ACTION_GIVE_TARGET")
		
		ACTIONS.SORT:
			#sort
			$SortTypeSelect.Show_confirmation_select(rect_position, "", _current_char, null, null)
		
		ACTIONS.DROP:
			#drop
			$ConfirmationSelect.Show_confirmation_select(rect_position, "drop", "back", _current_char, null, _current_item_idx)
	
	emit_signal("action_selected")


func _can_item_target(item_action, character) -> bool:
	return !StatusManager.is_unconscious(character)\
		or item_action.has("targetUnconscious") and item_action["targetUnconscious"] == true

