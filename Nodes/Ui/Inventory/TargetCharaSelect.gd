extends NinePatchRect

signal back (to_inventory)
signal chain_with_equip
signal show_statsbar (character, unequip)
signal hide_statsbar
signal show_dialogbox (dialog, character, action)

onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var ConfirmationSelect = $ConfirmationSelect

var current_character = "ninten"
var current_item = -1
var other_characters_list = []
var other_characters_nickname_list = []
var max_item_rows = 4

var active = false
var selected_item_nb = 0
var action = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
#clear the list before filling it again
func _empty_list():
	var labels = $MarginContainer/VBoxContainer.get_children()
	for label in labels:
		label.queue_free()
	

#process data to update the available character list	
func _update_character_list():
	var party = global.party
	var name_list = []
	other_characters_list.clear()
	other_characters_nickname_list.clear()
	#creating the character list by comparing the party with the full ordered list
	
	for character in party:
		name_list.append(character.name.to_lower())
		other_characters_nickname_list.append(character.nickname)
	#remove current character which is giving something
	
	other_characters_list = name_list
	max_item_rows = other_characters_list.size()
	
	
	_empty_list()
	
	yield(get_tree(), "idle_frame")
	
	#display the list as several labels
	for chara_name in other_characters_nickname_list:
		
		var label = item_label_template.instance()
		label.text = chara_name
		$MarginContainer/VBoxContainer.add_child(label)
	
	$arrow.on = true
	$arrow.set_cursor_from_index(0, false)
	$arrow.turn_on_highlight()
	
#used to make the box appear with the right parameters
func Show_target_chara_select(pos, cur_char, item_idx, action_type):
	selected_item_nb = 0
	current_item = item_idx
	current_character = cur_char
	_update_character_list()
	visible = true
	active = true
	action = action_type


#cb function to chain with equip
func _on_chain_with_equip():
	pass
#called by parent to chain swap or give with equip
func chain_with_equip():
	connect("chain_with_equip", self, "_on_chain_with_equip")
	emit_signal("chain_with_equip")
	

func _physics_process(_delta):
	if active:
		_inputs()


func _inputs():
	if Input.is_action_just_pressed("ui_up") and selected_item_nb != 0:
		selected_item_nb -=1
	elif Input.is_action_just_pressed("ui_down") and selected_item_nb != max_item_rows - 1:
		selected_item_nb +=1
			
	if InventoryManager.doesItemHaveFunction(InventoryManager.Inventories[current_character][current_item].ItemName, "equip"):
		if other_characters_list.has(selected_item_nb):
			if InventoryManager.Inventories[other_characters_list[selected_item_nb]][current_item].equiped == false:
				emit_signal("show_statsbar", other_characters_list[selected_item_nb])
			else:
				emit_signal("show_statsbar", other_characters_list[selected_item_nb], true)
		
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
		Input.action_release("ui_cancel")
		Input.action_release("ui_toggle")
		visible = false
		active = false
		$arrow.on = false
		emit_signal("hide_statsbar")
		emit_signal("back", false)
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		Input.action_release("ui_accept")
		$arrow.on = false
		bounce()
		var target = other_characters_list[selected_item_nb]
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
		
	
	#highlight item
	var items = $MarginContainer/VBoxContainer.get_children()
	for item_idx in items.size():
		if item_idx == selected_item_nb:
			items[selected_item_nb].highlight(1)
		else:
			items[item_idx].highlight(0)

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
		emit_signal("show_dialogbox", item_data[action]["text"][globaldata.language], target)
		audioManager.play_sfx(load("res://Audio/Sound effects/EB/eat.wav"), "menu")
	else:
		emit_signal("show_dialogbox", item_data[action]["textfail"][globaldata.language], target)

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



