extends Control

signal back
signal swapmode (target_character)
signal sortmode
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, character, action)

enum ACTIONS {EQUIP=0, CHECK, USE, CONSUME, TRANSFORM, GIVE, SORT, DROP}

export (NodePath) onready var drop_label = get_node(drop_label) as Label
export (NodePath) onready var give_label = get_node(give_label) as Label
export (NodePath) onready var sort_label = get_node(sort_label) as Label
export (NodePath) onready var action_one_label = get_node(action_one_label) as Label
export (NodePath) onready var action_two_label = get_node(action_two_label) as Label

onready var arrow = $arrow
onready var arrow_init_pos = arrow.position

var item_side_on_screen = 1
var is_equipable = false
var active = false
var current_char = "ninten"
var current_item = -1
var current_item_name = ""

var waiting_drop_confirmation = false


var possible_actions

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
func set_for_new_item(pos, item_name, item_side, curr_char, item_idx):
	current_item = item_idx
	current_item_name = item_name
	current_char = curr_char
	item_side_on_screen = item_side
	rect_position = pos
#	rect_position.x = item_side_on_screen*pos.x
	
	if InventoryManager.Load_item_data(item_name)["usable"][current_char]:
		is_equipable = InventoryManager.doesItemHaveFunction(item_name, "equip")
	else:
		is_equipable = false
	possible_actions = {}
	
	if InventoryManager.Load_item_data(item_name).value != 0:
		possible_actions[drop_label.name] = ACTIONS.DROP
		drop_label.visible = true
	else:
		drop_label.visible = false
	
	possible_actions[sort_label.name] = ACTIONS.SORT
	
	if global.party.size()>1:
		possible_actions[give_label.name] = ACTIONS.GIVE
		give_label.visible = true
	else:
		give_label.visible = false
	
	_set_actions()
	
	arrow.cursor_index = 0
	arrow.set_cursor_from_index(0, false)
	visible = true
	active = true
	arrow.on = true

func _set_actions():
	var item_data = InventoryManager.Load_item_data(current_item_name)
	print(current_item_name)
	if item_data["action_two"] != null:
		if item_data["action_two"]["function"] == "equip":
			if is_equipable:
				if InventoryManager.Inventories[current_char][current_item].equiped == true:
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
			if is_equipable:
				if InventoryManager.Inventories[current_char][current_item].equiped == true:
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
	$arrow.set_cursor_to_front()
	


func _push_action(action, node):
	match action["function"]:
		"equip":
			possible_actions[node.name] = ACTIONS.EQUIP
		"consume":
			possible_actions[node.name] = ACTIONS.CONSUME
		"use":
			possible_actions[node.name] = ACTIONS.USE
		"transform":
			possible_actions[node.name] = ACTIONS.TRANSFORM

func _physics_process(_delta):
	if active:
		if (possible_actions[arrow.get_current_item().name] == ACTIONS.EQUIP):
			if InventoryManager.Inventories[current_char][current_item].equiped == false:
				emit_signal("show_statsbar", current_char)
			else:
				emit_signal("show_statsbar", current_char, true)
		else:
			emit_signal("hide_statsbar")
		
		
		if Input.is_action_just_pressed("ui_cancel"):
			visible = false
			active = false
			arrow.on = false
			arrow.play_sfx("back")
			emit_signal("hide_statsbar")
			emit_signal("back")
			return
		
	
func chain_with_equip():
	$TargetCharaSelect.chain_with_equip()


func _on_TargetCharaSelect_back(to_inventory):
	if to_inventory:
		visible = false
		active = false
		arrow.on = false
		emit_signal("back")
		return
	else:
		active = true
		arrow.on = true
		bounce()


func _on_ConfirmationSelect_back(accept, current_action, current_character, target_character, cur_item):
	if accept == true:
		match current_action:
			"drop":
				InventoryManager.dropItem(current_character,cur_item)
			"equip":
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
				InventoryManager.equipItem(target_character, cur_item)
				emit_signal("hide_statsbar")
			"equipgive": # give item and equip
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
				InventoryManager.giveItem(current_character,target_character, cur_item)
				InventoryManager.equipItem(target_character, InventoryManager.Inventories[target_character].size()-1)
				emit_signal("hide_statsbar")
			"swap":
				emit_signal("swapmode", target_character)
			"SortManual":
				emit_signal("sortmode")		

		
		$TargetCharaSelect.visible = false
		$TargetCharaSelect.active = false
		visible = false
		active = false
		arrow.on = false
		bounce()
		emit_signal("back")
		return
	else:
		match current_action:
			"equip": #answered no to equip after swap
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				visible = false
				active = false
				arrow.on = false
				emit_signal("hide_statsbar")
				emit_signal("back")
			"equipgive": #give item but don't equip
				InventoryManager.giveItem(current_character,target_character, cur_item)
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				visible = false
				active = false
				arrow.on = false
				emit_signal("hide_statsbar")
				emit_signal("back")
			"SortAuto":
				InventoryManager.sortAuto(current_character)
				visible = false
				active = false
				arrow.on = false
				emit_signal("back")
			"swap":
				$TargetCharaSelect.active = false
				$TargetCharaSelect.visible = false
				visible = false
				active = false
				arrow.on = false
				emit_signal("back")
			"drop":
				active = true
				arrow.on = true
			"back":
				active = true
				arrow.on = true

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
	active = false
	arrow.on = false
	var action = ""
	if arrow.get_current_item() == action_one_label:
		action = "action_one"
	elif arrow.get_current_item() == action_two_label:
		action = "action_two"
	var item_data = InventoryManager.Load_item_data(current_item_name)
	match(possible_actions[arrow.get_current_item().name]):
		ACTIONS.EQUIP:
			#equips an item
			if InventoryManager.Inventories[current_char][current_item].equiped == false:
				InventoryManager.equipItem(current_char, current_item)
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
			else:
				InventoryManager.unequip(current_char, InventoryManager.Inventories[current_char][current_item].ItemName)
				audioManager.play_sfx(load("res://Audio/Sound effects/EB/close.wav"), "menu")
			visible = false
			active = false
			arrow.on = false
			emit_signal("hide_statsbar")
			emit_signal("back")
		ACTIONS.CONSUME:
			# LOCALIZATION Code added: Using a different title for the target box depending on the action
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
			$TargetCharaSelect.show_target_chara_select(rect_position, current_char, current_item, action, targets_list, title)
			
		ACTIONS.USE:
			#use an item to check something in front of you
			InventoryManager.useItem(current_char, current_item)
			visible = false
			active = false
			arrow.on = false
			# LOCALIZATION Code change: Removed use of globaldata.language
			emit_signal("show_dialogbox", item_data[action]["text"], current_char)
			
		ACTIONS.TRANSFORM:
			#transforms an item into another
			InventoryManager.transformItem(current_char, current_item)
			visible = false
			active = false
			arrow.on = false
			# LOCALIZATION Code change: Removed use of globaldata.language
			emit_signal("show_dialogbox", item_data[action]["text"])
		
		ACTIONS.GIVE:
			#summon targetCharaSelect
			# LOCALIZATION Code added: Using a different title for the target box depending on the action
			# (give => to whom, use => on whom, eat => who)
			var targets_list = []
			for partyMem in global.party:
				if partyMem.name != current_char:
					targets_list.append(partyMem.name)

			$TargetCharaSelect.show_target_chara_select(rect_position, current_char, current_item, "give", targets_list, "INVENTORY_ACTION_GIVE_TARGET")
		
		ACTIONS.SORT:
			#sort
			$SortTypeSelect.Show_confirmation_select(rect_position, "", current_char, null, null)
		
		ACTIONS.DROP:
			#drop
			$ConfirmationSelect.Show_confirmation_select(rect_position, "drop", "back", current_char, null, current_item)
	get_parent().updatePartyInfos()


func _can_item_target(item_action, character):
	return !character.status.has(globaldata.ailments.Unconscious)\
		or item_action.has("targetUnconscious") and item_action["targetUnconscious"] == true

