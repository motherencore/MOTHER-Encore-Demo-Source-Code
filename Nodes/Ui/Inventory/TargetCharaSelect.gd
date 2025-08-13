extends NinePatchRect

signal back (to_inventory)
signal chain_with_equip
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, chara_name, value, stat, item)

onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var ConfirmationSelect = $ConfirmationSelect

onready var arrow = $arrow

var current_character = "ninten"
var current_item = -1
var _char_list = [] # list of names

var active = false
var action = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
#clear the list before filling it again
func _empty_list():
	var labels = $MarginContainer/VBoxContainer.get_children()
	if labels.empty():
		yield(get_tree(), "idle_frame") # to always return an object
	else:
		for label in labels:
			label.queue_free()
		for label in labels:
			yield(label, "tree_exited")
	

#process data to update the available character list	
func _update_character_list():
	var nickname_list = []
	#creating the character list by comparing the party with the full ordered list
	
	for char_name in _char_list:
		for party_member in global.party:
			if party_member.name == char_name:
				nickname_list.append(party_member.nickname)
	
	yield(_empty_list(), "completed")
	
	#display the list as several labels
	for chara_name in nickname_list:
		var label = item_label_template.instance()
		label.text = chara_name
		$MarginContainer/VBoxContainer.add_child(label)

	arrow.on = true
	arrow.set_cursor_from_index(0, false)

	yield($MarginContainer/VBoxContainer, "draw")
	
	_bg_resize()

	
#used to make the box appear with the right parameters
# LOCALIZATION Code change: Added title parameter, to differentiate "Who"/"To whom"
func show_target_chara_select(pos, cur_char, item_idx, action_type, char_list, title = "INVENTORY_ACTION_TARGET"):
	current_item = item_idx
	current_character = cur_char
	visible = true
	active = true
	_char_list = char_list
	_update_character_list()
	action = action_type
	$ToWhomLabel.text = title


#cb function to chain with equip
func _on_chain_with_equip():
	pass
#called by parent to chain swap or give with equip
func chain_with_equip():
	connect("chain_with_equip", self, "_on_chain_with_equip")
	emit_signal("chain_with_equip")

func _physics_process(_delta):
	if active:
		if arrow.cursor_index < _char_list.size():
			var target = _char_list[arrow.cursor_index]
			var item_name = InventoryManager.Inventories[current_character][current_item].ItemName
			if InventoryManager.is_equippable_by(target, item_name)\
					and arrow.cursor_index < _char_list.size():
				emit_signal("show_statsbar", target)
		
		if Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			visible = false
			active = false
			arrow.on = false
			emit_signal("hide_statsbar")
			emit_signal("back", false)
			return
			
		if Input.is_action_just_pressed("ui_accept"):
			Input.action_release("ui_accept")
			arrow.on = false
			bounce()
			var target = _char_list[arrow.cursor_index]
			var source = current_character
			var item = current_item
			if action == "give":
				if InventoryManager.isInventoryFull(target):
					#propose to switch an item
					active = false
					ConfirmationSelect.Show_confirmation_select(rect_position, "swap", "back", source, target, item)
					yield(self, "chain_with_equip")
					var last_target_item_name = InventoryManager.Inventories[target][InventoryManager.Inventories[target].size()-1].ItemName
					if InventoryManager.is_equippable(last_target_item_name):
						visible = true
						#propose to equip on target
						active = false
						ConfirmationSelect.Show_confirmation_select(rect_position, "equip", "swap", source, target, InventoryManager.Inventories[target].size()-1)
						yield(ConfirmationSelect, "back")
					else:
						emit_signal("back", true)
						emit_signal("hide_statsbar")
						
				else:
					#test if item is equipable
					if InventoryManager.is_equippable_by(target, InventoryManager.Inventories[source][item].ItemName) and source != target:
						#propose to equip on target
						active = false
						ConfirmationSelect.Show_confirmation_select(rect_position, "equipgive", "cancel", source, target, item)
						yield(ConfirmationSelect, "back")
						pass
					else: #give
						InventoryManager.give_item(source, target, item)
						visible = false
						active = false
						emit_signal("hide_statsbar")
						emit_signal("back", true)
			else:
				visible = false
				active = false
				consume_item(source, item, target)
				emit_signal("back", true)
			

func consume_item(source, item_idx, target):
	var item_name: String = InventoryManager.Inventories[source][item_idx].ItemName
	var item_data: Dictionary = InventoryManager.Load_item_data(item_name)
	
	var actions_performed := {}

	if item_data.get("usable", {}).get(target, false):
		actions_performed = InventoryManager.consume_item(source, item_idx, target)
	
	var success := false

	if actions_performed.size() == 0:
		emit_signal("show_dialogbox", item_data[action]["textfail"], target, 0, null, item_data)
	else:
		for key in actions_performed:
			var message = "ACTION_RESULT_%s" % InventoryManager.ItemActions.keys()[key]
			var action_details = actions_performed[key]
			match key:
				InventoryManager.ItemActions.HP_UP, InventoryManager.ItemActions.PP_UP,\
				InventoryManager.ItemActions.HP_MAX, InventoryManager.ItemActions.PP_MAX:
					success = true
					emit_signal("show_dialogbox", message, target, action_details)
				InventoryManager.ItemActions.STAT_UP:
					success = true
					var stats = action_details
					for stat in stats:
						emit_signal("show_dialogbox", message, target, stats[stat], stat)
				InventoryManager.ItemActions.HEAL:
					success = true
					if action_details.size() > 1:
						emit_signal("show_dialogbox", "ACTION_RESULT_HEAL_ALL", target)
					else:
						emit_signal("show_dialogbox", StatusManager.get_status_message(action_details[0], "heal_overworld"), target)
				InventoryManager.ItemActions.HEAL_FAIL:
					if action_details.size() > 1:
						emit_signal("show_dialogbox", "ACTION_RESULT_HEAL_NONE", target)
					else:
						emit_signal("show_dialogbox", StatusManager.get_status_message(action_details[0], "heal_overworld_fail"), target)

	if success:	
		audioManager.play_sfx(load("res://Audio/Sound effects/EB/eat.wav"), "menu")


func _on_ConfirmationSelect_back(accept, current_action, _current_character, _target_character, _current_item):
	if accept == false:
		if current_action == "cancel":
			active = true
			bounce()
		else:
			active = false
			hide()

func bounce():
	$Tween.interpolate_property(self, "rect_position",
		rect_position - Vector2(0, 2), rect_position, 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
	$Tween.start()


func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	_bg_resize()

func _bg_resize():
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.x = $MarginContainer.rect_size.x
	rect_size.y = $MarginContainer.rect_size.y
	ConfirmationSelect.rect_position.x = $MarginContainer.rect_size.x
