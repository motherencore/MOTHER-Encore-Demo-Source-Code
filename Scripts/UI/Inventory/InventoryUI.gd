extends CanvasLayer

signal back
signal exit

const partyInfoTscn = preload("res://Nodes/Ui/Battle/PartyInfoPlate.tscn")

#external paths and references
onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")
onready var SelectPanel = $Inventory/InventorySelect
onready var StatsBar = $StatsBar
onready var DialogBox = $DialogBox
onready var ActionSelect = $ActionSelect
onready var arrow = $Inventory/ColorRect
onready var itemsGrid = $Inventory/CenterContainer/Items/GridContainer 
onready var arrow_init_pos = arrow.rect_position
onready var scrollbar = $Inventory/DescriptionPanel/Scrollbar

const max_item_collumns = 2
const offset_list_threshold = 5
const arrow_move_offset_x = 123
const arrow_move_offset_y = 12
const MAX_SUBMENU_POSITION = 60
const ITEM_LABEL_SIZE = 98

var active = false setget _setActive
func _setActive(val):
	active = val
	SelectPanel.active = val

var current_character = "ninten"
var current_inventory = []
var current_scroll_pos = 1
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
	_show_hide_description(globaldata.description)
	scrollbar.nb_visible_rows = offset_list_threshold
	_update_inventory(current_character, true)
	updatePartyInfos()
	active = true
	$AnimationPlayer.play("Open")
	$Inventory.visible = true
	SelectPanel.visible = true
	
	
func _update_inventory(character, reset_select):
	current_inventory = InventoryManager.getInventory(character)
	if reset_select:
		selected_item_nb = 0
		current_scroll_pos = 1
		idx_x = 1
		idx_y = 1
	_update_list()
	
	
func _ready():
	$Inventory.visible = false
	_update_list()
	global.connect("locale_changed", self, "_update_description")
	
func _physics_process(_delta):
	if active:
		$Inventory/ColorRect/Arrow.on = true
		if !swapmode:
			_update_description()
			_update_portraits()
		controls()
		highlight()
		
	else:
		$Inventory/ColorRect/Arrow.on = false
		

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
			if ((item_in_row >= current_scroll_pos - 1) and offset_list) or !offset_list:
				var item_label = item_label_template.instance()
				item_label.rect_min_size.x = ITEM_LABEL_SIZE
				var item_data = InventoryManager.Load_item_data(item.ItemName)
				# LOCALIZATION Code change: Removed use of globaldata.language
				item_label.text = item_data["name"]
				item_label.show_equiped(item.equiped)
				itemsGrid.add_child(item_label)
			item_cnt+=1
			
	var total_rows = ceil(item_cnt * 1.0 / max_item_collumns)

	# In case scrolling goes above the last row (like, because an item was deleted and the last row is empty)
	if total_rows < current_scroll_pos - 1 + offset_list_threshold:
		total_rows = current_scroll_pos - 1 + offset_list_threshold
		
	scrollbar.nb_rows = total_rows
	scrollbar.position = current_scroll_pos - 1

func _update_scroll():
	#updates the scrolling position if the selected item is out of visibility area
	if idx_y < current_scroll_pos:
		current_scroll_pos = idx_y
	if idx_y > current_scroll_pos + offset_list_threshold - 1:
		current_scroll_pos = idx_y - offset_list_threshold + 1

	#calculate the item selected according to the xy coordinates
	selected_item_nb = 2*(idx_y-1)+(idx_x-1)
	selected_item_nb = clamp(selected_item_nb, 0, current_inventory.size()-1)
	if offset_list:
		item_to_hl = 2*(idx_y - current_scroll_pos)+(idx_x-1)
	else:
		item_to_hl = selected_item_nb

func _update_description():
	#get the name of the selected items
	if selected_item_nb < current_inventory.size():
		var selected_item_name = current_inventory[selected_item_nb].ItemName
		var item = InventoryManager.Load_item_data(selected_item_name)
		$Inventory/DescriptionPanel.setItem(current_inventory[selected_item_nb].ItemName)
	else:
		$Inventory/DescriptionPanel.setItem("")

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
		if chara_nam in ["flyingman", "eve", "canarychick"]: # Useless? Same condition just below
			return
		if !(chara_nam in InventoryManager.no_inventory_characters): # Same condition just above
			if selected_item_nb < current_inventory.size():
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


func controls():
	if active:
		var pos = arrow.rect_position
		var update_flag = false
		
		#check for inputs for selecting items in the inventory
		if !is_inventory_empty:
			var input = controlsManager.get_controls_vector(true)
			if input.y < 0:
				$Inventory/ColorRect/Arrow.play_sfx("cursor1")
				idx_y -=1
				update_flag = true
			elif input.y > 0:
				$Inventory/ColorRect/Arrow.play_sfx("cursor1")
				idx_y +=1
				update_flag = true
			if input.x < 0:
				$Inventory/ColorRect/Arrow.play_sfx("cursor1")
				idx_x -=1 
				if idx_x < 1:
					idx_x = max_item_collumns
				update_flag = true
			elif input.x > 0:
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
			#only cycling if updated by user
			if update_flag:
				if idx_y < 1:
					idx_y = max_item_rows
				if idx_y > max_item_rows:
					idx_y = 1
			else:
				idx_y = clamp(idx_y, 1, max_item_rows)
			
			_update_scroll()

			#don't update if no changes
			if update_flag == true:
				_update_list()
				update_flag = false
			
		pos.x = arrow_init_pos.x + (item_to_hl % max_item_collumns) * arrow_move_offset_x
		pos.y = arrow_init_pos.y + (item_to_hl / max_item_collumns) * arrow_move_offset_y
		
		arrow.rect_position = pos

func _input(event):
	if active:
		var pos = arrow.rect_position
		var update_flag = false
		if !is_inventory_empty:
			if event.is_action_pressed("ui_scope"):
				Input.action_release("ui_scope")
				if !is_inventory_empty and !swapmode and !sort_mode:
					globaldata.description = !globaldata.description
					_show_hide_description(globaldata.description)
					_update_inventory(current_character, false)
				
					
			

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
						_show_hide_description(globaldata.description)
						_update_list()
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
							ActionSelect.set_for_new_item(submenu_position, item, side, current_character,selected_item_nb)
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
					_show_hide_description(globaldata.description)
					_update_inventory(current_character, false)
					ActionSelect.visible = true
					ActionSelect.chain_with_equip()
				return

		else:
			selected_item_nb = 0 #temp?
						
		if Input.is_action_just_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			if sort_mode:
				$Inventory/ColorRect/Arrow.play_sfx("back")
				sort_mode = false
				_show_hide_description(globaldata.description)
				highlight()
				SelectPanel.active = true
				return
			elif swapmode:
				$Inventory/ColorRect/Arrow.play_sfx("back")
				swapmode = false
				_show_hide_description(globaldata.description)
				highlight()
				SelectPanel.setSwapmode(false, swap_source, swap_target )
				current_character = swap_source
				_update_inventory(current_character, false)
				return
			else:
				$AnimationPlayer.play("Close")
				active = false
				SelectPanel.active = false
				emit_signal("back")
				return
				

		
	
	#highlight item
func highlight():	
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

func _show_hide_description(value):
	$Inventory/DescriptionPanel.visible = value
	offset_list = value
	_update_scroll()

func _on_InventorySelect_character_changed(character):
	current_character = character
	_update_inventory(character, true)


func _on_ActionSelect_back():
	_update_inventory(current_character, false)
	active = true
	if !sort_mode:
		SelectPanel.active = true


func _on_ActionSelect_swapmode(target):
	_show_hide_description(false)
	swap_source = current_character
	swap_source_item = selected_item_nb
	current_character = target
	swap_target = target
	swapmode = true
	SelectPanel.setSwapmode(true, swap_source, swap_target )
	_update_inventory(target,false)


func _on_ActionSelect_sortmode():
	_show_hide_description(false)
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
	
	if chara_data == null:
		StatsBar.hide_statsBar()
	elif chara_data["equipment"][item_slot] != item:
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
				
	StatsBar.show_statsBar(chara_data, modifiersDic)


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



