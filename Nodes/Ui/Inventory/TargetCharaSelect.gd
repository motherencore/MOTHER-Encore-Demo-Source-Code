extends NinePatchRect

signal back (to_inventory)
signal chain_with_equip
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, character, action)

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
			if InventoryManager.doesItemHaveFunction(item_name, "equip")\
			and InventoryManager.Load_item_data(item_name)["usable"][target]\
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
					if InventoryManager.doesItemHaveFunction(InventoryManager.Inventories[target][InventoryManager.Inventories[target].size()-1].ItemName, "equip"):
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
					if InventoryManager.doesItemHaveFunction(InventoryManager.Inventories[source][item].ItemName, "equip") and InventoryManager.Load_item_data(InventoryManager.Inventories[source][item].ItemName)["usable"][target] and source != target:
						#propose to equip on target
						active = false
						ConfirmationSelect.Show_confirmation_select(rect_position, "equipgive", "cancel", source, target, item)
						yield(ConfirmationSelect, "back")
						pass
					else: #give
						InventoryManager.giveItem(source, target, item)
						visible = false
						active = false
						emit_signal("hide_statsbar")
						emit_signal("back", true)
			else:
				visible = false
				active = false
				consume_item(source, item, target)
				emit_signal("back", true)
			

func consume_item(source, item, target):
	var current_item_name = InventoryManager.Inventories[source][item].ItemName
	var item_data = InventoryManager.Load_item_data(current_item_name)
	var useItem = false
	if item_data["HPrecover"] > 0 or item_data["PPrecover"] > 0:
		useItem = true
		if item_data.has("usable"):
			for chara in item_data["usable"]:
				print(chara)
				if !item_data["usable"][chara] and target == chara:
					useItem = false
	elif item_data.has("status_heals"):
		for status in item_data["status_heals"]:
			if InventoryManager.characterHasStatus(target, globaldata.status_name_to_enum(status)):
				useItem = true
	elif item_data.has("boost"):
		useItem = true
		if item_data.has("usable"):
			for chara in item_data["usable"]:
				print(chara)
				if !item_data["usable"][chara] and target == chara:
					useItem = false
	if useItem:
		InventoryManager.consumeItem(source, current_item, target)
		emit_signal("show_dialogbox", item_data[action]["text"], target)
		audioManager.play_sfx(load("res://Audio/Sound effects/EB/eat.wav"), "menu")
	else:
		emit_signal("show_dialogbox", item_data[action]["textfail"], target)

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


# LOCALIZATION Code added: The box changes size to fit content dynamically
func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.x = $MarginContainer.rect_size.x
	rect_size.y = $MarginContainer.rect_size.y
	ConfirmationSelect.rect_position.x = $MarginContainer.rect_size.x
