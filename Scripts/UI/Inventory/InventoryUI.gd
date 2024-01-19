extends CanvasLayer

signal back
signal exit

const partyInfoTscn = preload("res://Nodes/Ui/Battle/PartyInfoPlate.tscn")

#external paths and references
onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")
onready var SelectPanel = $InventorySelect
onready var StatsBar = $StatsBar
onready var DialogBox = $DialogBox
onready var ActionSelect = $ActionSelect
onready var arrow = $Inventory/ColorRect
onready var itemsGrid = $Inventory/CenterContainer/Items/GridContainer 
onready var arrow_init_pos = arrow.rect_position


const max_item_collumns = 2
const offset_list_threshold = 5
const arrow_move_offset_x = 123
const arrow_move_offset_y = 12
const MAX_SUBMENU_POSITION = 60

var active = false setget _setActive
func _setActive(val):
	active = val
	SelectPanel.active = val

var current_character = "ninten"
var current_inventory = []
var selected_item_nb = 0
var item_to_hl = 0
var idx_x = 1
var idx_y = 1
var item_collumns = max_item_collumns
var item_rows = max_item_rows
var max_item_rows = 8
var offset_list = false
var is_inventory_empty = false
var blink = false
var swapmode = false
var swap_source = ""
var swap_source_item = ""
var swap_target = ""
var sort_mode = false
var sort_source_idx = 0


	
func Show_inventory(party_member):
	current_character = party_member["name"].to_lower()
	SelectPanel.InitFromCharacter(current_character)
	_update_inventory(current_character, true)
	updatePartyInfos()
	active = true
	$AnimationPlayer.play("Open")
	$Inventory.visible = true
	SelectPanel.visible = true
	$Inventory/DescriptionPanel.visible = globaldata.description
	offset_list = $Inventory/DescriptionPanel.visible
	
	
func _update_inventory(character, reset_select):
	current_inventory = InventoryManager.getInventory(character)
	if reset_select:
		selected_item_nb = 0
		idx_x = 1
		idx_y = 1
	_update_list()
	
	
func _ready():
	$Inventory.visible = false
	_update_list()
	
func _physics_process(_delta):
	if active:
		_inputs()
		if !swapmode:
			_update_description()
			_update_portraits()
		

#empty list before updating
func _empty_list():
	for item in itemsGrid.get_children():
		item.queue_free()
			
		
#Update the list 	
func _update_list():
	var item_cnt = 0
	_empty_list()
	if current_inventory == []: #empty inventory
#		var item_label = item_label_template.instance()
#		item_label.text = ""
#		itemsGrid.add_child(item_label)
		is_inventory_empty = true
	else:
		is_inventory_empty = false
		for item in current_inventory:
			var item_in_row = item_cnt / max_item_collumns
			var selected_item_in_row = selected_item_nb / max_item_collumns
			if ((item_in_row > (selected_item_in_row - offset_list_threshold)) and offset_list) or !offset_list:
				var item_label = item_label_template.instance()
				item_label.rect_min_size.x = 109
				var item_data = InventoryManager.Load_item_data(item.ItemName) 
				item_label.text = item_data["name"][globaldata.language]
				item_label.show_equiped(item.equiped)
				itemsGrid.add_child(item_label)
			item_cnt+=1
			
	if offset_list:
		var selected_item_in_row = selected_item_nb / max_item_collumns
		if (item_cnt / max_item_collumns > offset_list_threshold ) and (selected_item_in_row - offset_list_threshold < 2):
			$Inventory/DescriptionPanel/cursor_down.visible = true
		else:
			$Inventory/DescriptionPanel/cursor_down.visible = false
			
		if selected_item_in_row + 1 > offset_list_threshold:
			$Inventory/DescriptionPanel/cursor_up.visible = true
		else:
			$Inventory/DescriptionPanel/cursor_up.visible = false
	else:
		$Inventory/DescriptionPanel/cursor_up.visible = false
		$Inventory/DescriptionPanel/cursor_down.visible = false
	
	
func _update_description():
	#get the name of the selected items
	if !is_inventory_empty:
		var selected_item_name = current_inventory[selected_item_nb].ItemName
		var item = InventoryManager.Load_item_data(selected_item_name)
		$Inventory/DescriptionPanel/ColorRect/HBoxContainer/CenterContainer2/Desc.text = globaldata.replaceText(item["description"][globaldata.language])
		var path := str("res://Graphics/Objects/Items/" + current_inventory[selected_item_nb].ItemName + ".png")
		if ResourceLoader.exists(path) == true :
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer/CenterContainer/TextureRect/Item.texture =  ResourceLoader.load(path)
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer.alignment = BoxContainer.ALIGN_BEGIN
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer/CenterContainer.visible = true
		else:
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer/CenterContainer/TextureRect/Item.texture = null
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer.alignment = BoxContainer.ALIGN_CENTER
			$Inventory/DescriptionPanel/ColorRect/HBoxContainer/CenterContainer.visible = false
	else:
		$Inventory/DescriptionPanel.visible = false
		offset_list = $Inventory/DescriptionPanel.visible
		_update_inventory(current_character, false)

func _update_portraits():
	#update portrait modifiers
	#for each character, check if:
	for character in global.party:
		var is_suitable = false
		var is_equiped = false
		var is_better = false
		var is_lower = false
		#	- item is suitable for the character
		var chara_nam = character["name"].to_lower()
		if chara_nam in ["flyingman", "eve", "canarychick"]:
			return
		if !(chara_nam in InventoryManager.no_inventory_characters):
			if current_inventory.empty() != true:
				var current_item_name = current_inventory[selected_item_nb].ItemName
				var current_item_data = InventoryManager.Load_item_data(current_item_name)
				
				if InventoryManager.doesItemHaveFunction(current_item_name, "equip"):
					is_suitable = current_item_data["usable"][chara_nam]
					var current_item_slot = current_item_data["slot"]
					#- item is equiped
					is_equiped = (InventoryManager.Get_global_data(chara_nam)["equipment"][current_item_slot] == current_item_name)
					
					#if not equiped, check if stats boost
					if !is_equiped:
						var res = InventoryManager.is_the_item_better(InventoryManager.Get_global_data(chara_nam), current_item_name)
						match res:
							1:
								is_better = true
								is_lower = false
							-1:
								is_better = false
								is_lower = true
							0:
								is_better = false
								is_lower = false
					else:
						#already equiped, no stats boost
						is_better = false
						is_lower = false
				else:
					#not equipable
					is_equiped = false
				
				# then update the modifiers
				SelectPanel.Update_portrait_modifiers(chara_nam, is_suitable, is_equiped, is_better, is_lower)

func updatePartyInfos(set=true):
	for i in $PartyInfoHBox.get_child_count():
		var partyInfo = $PartyInfoHBox.get_child(i)
		if i >= global.party.size():
			partyInfo.hide()
			continue
		partyInfo.show()
		partyInfo.pName = global.party[i].nickname
		partyInfo.get_node("Name").text = partyInfo.pName
		partyInfo.maxHP = global.party[i].maxhp + global.party[i].boosts.maxhp
		partyInfo.maxPP = global.party[i].maxpp + global.party[i].boosts.maxpp
		partyInfo.setHP(global.party[i].hp, set)
		partyInfo.setPP(global.party[i].pp, set)
		partyInfo.show_maxNum()

func _inputs():
	var pos = arrow.rect_position
	var update_flag = false
	
	#check for inputs for selecting items in the inventory
	if !is_inventory_empty:
		if Input.is_action_just_pressed("ui_up"):
			$Inventory/ColorRect/Arrow.play_sfx("cursor1")
			idx_y -=1
			update_flag = true
		elif Input.is_action_just_pressed("ui_down"):
			$Inventory/ColorRect/Arrow.play_sfx("cursor1")
			idx_y +=1
			update_flag = true
		elif Input.is_action_just_pressed("ui_left"):
			$Inventory/ColorRect/Arrow.play_sfx("cursor1")
			idx_x -=1 
			if idx_x < 1:
				idx_x = max_item_collumns
			update_flag = true
		elif Input.is_action_just_pressed("ui_right"):
			$Inventory/ColorRect/Arrow.play_sfx("cursor1")
			idx_x +=1 
			if idx_x > max_item_collumns:
				idx_x = 1
			update_flag = true
			
				
		if current_inventory.size() == 1:
			idx_x = 1
			
		#calculate new max items in the current collumn for this inventory
		max_item_rows = ((current_inventory.size()/2)+((1-idx_x)*(current_inventory.size()%2)))+(current_inventory.size()%2)
		
		#check for vertical boundaries with newly calculated max
		if idx_y < 1:
			idx_y = max_item_rows
		if idx_y > max_item_rows:
			idx_y = 1
		
		#calculate the item selected according to the xy coordinates
		selected_item_nb = 2*(idx_y-1)+(idx_x-1)
		selected_item_nb = clamp(selected_item_nb, 0, current_inventory.size()-1)
		if offset_list and (idx_y > offset_list_threshold):
			item_to_hl = 2*(offset_list_threshold-1)+(idx_x-1)
		else:
			item_to_hl = selected_item_nb
			
		#don't update if no changes
		if update_flag == true:
			_update_list()
			update_flag = false

		#item selected and validated, show actions box at the right place
		if Input.is_action_just_pressed(("ui_accept")):
			Input.action_release("ui_accept")
			$Inventory/ColorRect/Arrow.play_sfx("cursor2")
			var item = current_inventory[selected_item_nb].ItemName
			var item_data = InventoryManager.Load_item_data(item)
			var side = ""
			if !swapmode:
				if sort_mode:
					var target_idx = selected_item_nb
					InventoryManager.switchItems(current_character, sort_source_idx, target_idx)
					_update_inventory(current_character,false)
					sort_mode = false
					SelectPanel.active = true
					
				else:
					if selected_item_nb%2 == 1:
						side = -1.5#"right"
					else:
						side = 1#"left"
					var submenu_position = $Inventory/ColorRect/Arrow/Position2D.global_position
					if submenu_position.y > arrow_init_pos.y+ 9 + (offset_list_threshold * arrow_move_offset_y):
						submenu_position.y = arrow_init_pos.y+ 9 + (offset_list_threshold * arrow_move_offset_y)
					submenu_position.x = submenu_position.x + 25*side
					submenu_position.y = min(MAX_SUBMENU_POSITION, submenu_position.y)
					if current_character != "key":
						ActionSelect.Set_for_new_item(submenu_position, item, side, current_character,selected_item_nb)
						active = false
						SelectPanel.active = false
			else:
				#sound here?
				InventoryManager.swapBetweenCharacters(swap_source, swap_target, swap_source_item,  selected_item_nb)
				swapmode = false
				active = false
				selected_item_nb = swap_source_item
				current_character = swap_source
				SelectPanel.setSwapmode(false, swap_source, swap_target )
				_update_inventory(current_character, false)
				_update_list()
				ActionSelect.visible = true
				ActionSelect.chain_with_equip()
			return

	else:
		selected_item_nb = 0 #temp?
		
	if Input.is_action_just_pressed("ui_ctrl"):
		Input.action_release("ui_ctrl")
		if !is_inventory_empty and !swapmode and !sort_mode:
			globaldata.description = !globaldata.description
			$Inventory/DescriptionPanel.visible = globaldata.description
			offset_list = globaldata.description
			_update_inventory(current_character, false)
		
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle"):
		Input.action_release("ui_cancel")
		Input.action_release("ui_toggle")
		if sort_mode:
			sort_mode = false
			SelectPanel.active = true
			return
		else:
			$AnimationPlayer.play("Close")
			active = false
			SelectPanel.active = false
			emit_signal("back")
			return
			
	
	pos.x = arrow_init_pos.x + (idx_x-1)*arrow_move_offset_x
	pos.y = arrow_init_pos.y + (idx_y-1)*arrow_move_offset_y
	
	if $Inventory/DescriptionPanel.visible:
		if idx_y >= 5:
			pos.y = arrow_init_pos.y + (5-1)*arrow_move_offset_y
	
	if offset_list:
		pos.y = clamp(pos.y, arrow_init_pos.y,arrow_init_pos.y +(offset_list_threshold*arrow_move_offset_y))
	
	
	
	
	arrow.rect_position = pos
	
	#highlight item
	var items = itemsGrid.get_children()
	for item_idx in items.size():
		if item_idx == item_to_hl:
			if swapmode:
				if items[item_to_hl].blinking == false:
					items[item_to_hl].blink(true)
			else:
				items[item_to_hl].highlight(1)
		else:
			if sort_mode:
				items[sort_source_idx].blink(true)
			else:
				items[item_idx].highlight(0)

func _on_InventorySelect_character_changed(character):
	current_character = character
	_update_inventory(character, true)


func _on_ActionSelect_back():
	_update_list()
	_update_inventory(current_character, false)
	active = true
	if !sort_mode:
		SelectPanel.active = true


func _on_ActionSelect_swapmode(target):
	$Inventory/DescriptionPanel.visible = false
	offset_list = false
	swap_source = current_character
	swap_source_item = selected_item_nb
	current_character = target
	swap_target = target
	swapmode = true
	SelectPanel.setSwapmode(true, swap_source, swap_target )
	_update_inventory(target,false)


func _on_ActionSelect_sortmode():
	$Inventory/DescriptionPanel.visible = false
	offset_list = false
	sort_source_idx = selected_item_nb
	sort_mode = true
	SelectPanel.active = false


func _on_ActionSelect_show_statsbar(character, unequip = false):
	
	var modifiersDic = {}
	var chara_data = InventoryManager.Get_global_data(character)
	var item = current_inventory[selected_item_nb].ItemName
	var item_stats= InventoryManager.Load_item_data(item)
	var item_slot = item_stats["slot"] 
	var is_equiped = false
	
	#test if item equiped:
	var projected_stat
	if chara_data["equipment"][item_slot] != item:
		for stat in StatsBar.stats_list:
			if item_stats["boost"].has(stat):
				var boost = int(item_stats["boost"][stat])
				if boost != 0:
					var equiped_item = chara_data["equipment"][item_slot]
					var equiped_boost = 0
					if equiped_item != "":
						equiped_boost = InventoryManager.Load_item_data(equiped_item)["boost"][stat]
					projected_stat = chara_data[stat] + chara_data["boosts"][stat] - equiped_boost + boost
						
					modifiersDic[stat] = projected_stat
	else:
		for stat in StatsBar.stats_list:
			if item_stats["boost"].has(stat):
				var boost = int(item_stats["boost"][stat])
				if boost != 0:
					var equiped_item = chara_data["equipment"][item_slot]
					var equiped_boost = 0
					if equiped_item != "":
						equiped_boost = InventoryManager.Load_item_data(equiped_item)["boost"][stat]
					projected_stat = chara_data[stat] + chara_data["boosts"][stat] - equiped_boost
						
					modifiersDic[stat] = projected_stat
		
		
	StatsBar.show_statsBar(character, modifiersDic)


func _on_ActionSelect_hide_statsbar():
	StatsBar.hide_statsBar()

func _on_TargetCharaSelect_hide_statsbar():
	StatsBar.hide_statsBar()

func _on_ActionSelect_show_dialogbox(dialog, character = null, action = ""):
	DialogBox.show_dialogBox(dialog, character, action)

func _on_TargetCharaSelect_show_dialogbox(dialog, character = null, action = ""):
	DialogBox.show_dialogBox(dialog, character, action)

func _on_DialogBox_back():
	updatePartyInfos()
	_update_list()
	active = true
	SelectPanel.active = true


func _on_DialogBox_exit():
	updatePartyInfos()
	$AnimationPlayer.play("Close")
	active = false
	SelectPanel.active = false
	emit_signal("exit")
	return



