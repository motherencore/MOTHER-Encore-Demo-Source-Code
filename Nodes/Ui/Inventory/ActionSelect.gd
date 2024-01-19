extends NinePatchRect

signal back
signal swapmode (target_character)
signal sortmode
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, character, action)

enum ACTIONS {EQUIP=0, CHECK, USE, CONSUME, TRANSFORM, GIVE, SORT, DROP}
const base_actions = [
]


const arrow_move_offset_y = 15
var max_item_rows = 4

onready var arrow = $arrow
onready var arrow_init_pos = arrow.position

var item_side_on_screen = 1
var is_equipable = false
var active = false
var selected_item_nb = 0
var current_char = "ninten"
var current_item = -1
var current_item_name = ""

var waiting_drop_confirmation = false


var possible_actions = []

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
func Set_for_new_item(pos, item_name, item_side, curr_char, item_idx):
	selected_item_nb = 0
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
	possible_actions = base_actions.duplicate()
	
	if InventoryManager.Load_item_data(item_name).value != 0:
		possible_actions.push_front(ACTIONS.DROP)
		$MarginContainer/VBoxContainer/DropLabel.visible = true
	else:
		$MarginContainer/VBoxContainer/DropLabel.visible = false
	
	possible_actions.push_front(ACTIONS.SORT)
	
	if global.party.size()>1:
		possible_actions.push_front(ACTIONS.GIVE)
		$MarginContainer/VBoxContainer/GiveLabel.visible = true
	else:
		$MarginContainer/VBoxContainer/GiveLabel.visible = false
	
	_set_actions()
	max_item_rows = possible_actions.size()
	
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
					$MarginContainer/VBoxContainer/ActionTwoLabel.text = item_data["action_two"]["nametwo"][globaldata.language]
				else:
					$MarginContainer/VBoxContainer/ActionTwoLabel.text = item_data["action_two"]["name"][globaldata.language]
				$MarginContainer/VBoxContainer/ActionTwoLabel.visible = true
				_push_action(item_data["action_two"])
			else:
				$MarginContainer/VBoxContainer/ActionOneLabel.visible = false
		else:
			$MarginContainer/VBoxContainer/ActionTwoLabel.text = item_data["action_two"]["name"][globaldata.language]
			$MarginContainer/VBoxContainer/ActionTwoLabel.visible = true
			_push_action(item_data["action_two"])
	else:
		$MarginContainer/VBoxContainer/ActionTwoLabel.visible = false
	
	if item_data["action_one"] != null:
		if item_data["action_one"]["function"] == "equip":
			if is_equipable:
				if InventoryManager.Inventories[current_char][current_item].equiped == true:
					$MarginContainer/VBoxContainer/ActionOneLabel.text = item_data["action_one"]["nametwo"][globaldata.language]
				else:
					$MarginContainer/VBoxContainer/ActionOneLabel.text = item_data["action_one"]["name"][globaldata.language]
				$MarginContainer/VBoxContainer/ActionOneLabel.visible = true
				_push_action(item_data["action_one"])
			else:
				$MarginContainer/VBoxContainer/ActionOneLabel.visible = false
		else:
			$MarginContainer/VBoxContainer/ActionOneLabel.text = item_data["action_one"]["name"][globaldata.language]
			$MarginContainer/VBoxContainer/ActionOneLabel.visible = true
			_push_action(item_data["action_one"])
	else:
		$MarginContainer/VBoxContainer/ActionOneLabel.visible = false
	yield(get_tree(), "idle_frame")
	$arrow.set_cursor_to_front()
	


func _push_action(action):
	match action["function"]:
		"equip":
			possible_actions.push_front(ACTIONS.EQUIP)
		"consume":
			possible_actions.push_front(ACTIONS.CONSUME)
		"use":
			possible_actions.push_front(ACTIONS.USE)
		"transform":
			possible_actions.push_front(ACTIONS.TRANSFORM)
		

	
func _physics_process(_delta):
	if active:
		_inputs()

#to highlight the correct label with idx the selected item
func _highlight_label(idx):
	var actions = $MarginContainer/VBoxContainer.get_children()
	var to_highlight = idx
	for i in actions.size():
		if !actions[i].visible:
			to_highlight += 1
		if i == to_highlight:
			actions[i].highlight(1)
		else:
			actions[i].highlight(0)
	

func _inputs():
	var pos = arrow.position
	
	if Input.is_action_just_pressed("ui_up") and selected_item_nb != 0:
		selected_item_nb -=1
	elif Input.is_action_just_pressed("ui_down") and selected_item_nb != max_item_rows - 1:
		selected_item_nb +=1
			
	if(possible_actions[selected_item_nb] == ACTIONS.EQUIP):
		if InventoryManager.Inventories[current_char][current_item].equiped == false:
			emit_signal("show_statsbar", current_char)
		else:
			emit_signal("show_statsbar", current_char, true)
	else:
		emit_signal("hide_statsbar")
			
	
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
		visible = false
		active = false
		arrow.on = false
		arrow.play_sfx("back")
		emit_signal("hide_statsbar")
		emit_signal("back")
		return
		
	pos.y = arrow_init_pos.y +((selected_item_nb % max_item_rows)*arrow_move_offset_y)
	
	
	#arrow.position = pos
	_highlight_label(selected_item_nb)
	
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
	if selected_item_nb == 0:
		action = "action_one"
	elif selected_item_nb == 1:
		action = "action_two"
	match(possible_actions[selected_item_nb]):
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
			#consume an item to recover hp and pp and boost some stats
			$TargetCharaSelect.Show_target_chara_select(rect_position, current_char, current_item, action)
			
		ACTIONS.USE:
			#use an item to check something in front of you
			InventoryManager.useItem(current_char, current_item)
			visible = false
			active = false
			arrow.on = false
			emit_signal("show_dialogbox", InventoryManager.Load_item_data(current_item_name)[action]["text"][globaldata.language], current_char)
			
		ACTIONS.TRANSFORM:
			#transforms an item into another
			InventoryManager.transformItem(current_char, current_item)
			visible = false
			active = false
			arrow.on = false
			emit_signal("show_dialogbox", InventoryManager.Load_item_data(current_item_name)[action]["text"][globaldata.language])
		
		ACTIONS.GIVE:
			#summon targetCharaSelect
			$TargetCharaSelect.Show_target_chara_select(rect_position, current_char, current_item, "give")
		
		ACTIONS.SORT:
			#sort
			$SortTypeSelect.Show_confirmation_select(rect_position, "", current_char, null, null)
		
		ACTIONS.DROP:
			#drop
			$ConfirmationSelect.Show_confirmation_select(rect_position, "drop", "back", current_char, null, current_item)
	get_parent().updatePartyInfos()
