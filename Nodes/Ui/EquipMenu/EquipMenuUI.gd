extends CanvasLayer

signal back

#small icon showing wether the item give bonus or malus when equipping
onready var _boost_icon_empty = preload("res://Graphics/UI/EquipMenu/empty.png")
onready var _boost_icon_bonus = preload("res://Graphics/UI/EquipMenu/red_arrow.png")
onready var _boost_icon_malus = preload("res://Graphics/UI/EquipMenu/blue_arrow.png")

#external paths and references
onready var _item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var _char_tabs = $EquipMenu/Box/InventorySelect
onready var _cursor_slots: Cursor = $EquipMenu/Box/Panels/Slots/SlotArrow
onready var _cursor_list: Cursor = $EquipMenu/Box/Panels/Slots/ItemListPanel/ItemArrow
onready var _item_panel = $EquipMenu/Box/Panels/Slots/ItemListPanel
onready var _items_container = $EquipMenu/Box/Panels/Slots/ItemListPanel/ItemList
onready var _desc_panel = $EquipMenu/Description/DescriptionPanel
onready var _level_label = $EquipMenu/Box/Panels/Stats/Columns/Values/LevelValue

export (Dictionary) onready var _np_values
export (Dictionary) onready var _np_boost_values
export (Dictionary) onready var _np_boost_icons

var _current_character: Dictionary
var _item_list := []

#true when a slot is selected and items are shown to be equiped
var _item_selection := false

#used by the general menu to show the equip menu
func open(party_member: Dictionary):
	$AnimationPlayer.play("Open")
	$AnimationPlayerDesc.assigned_animation = "Close"
	_current_character = party_member
	_char_tabs.InitFromCharacter(_current_character["name"])
	_char_tabs.visible = true
	_cursor_slots.set_cursor_from_index(0, false)
	_update_panel()

func _update_item_info():
	_update_description()
	_update_portraits()
	_update_stats()

func _update_description():
	var selected_item_name := _get_selected_item()
	var anim_to_play := "Close"
	if selected_item_name:
		_desc_panel.set_item(selected_item_name)
		anim_to_play = "Open"

	if $AnimationPlayerDesc.assigned_animation != anim_to_play:
		$AnimationPlayerDesc.play(anim_to_play)

func _get_current_slot() -> String:
	return InventoryManager.SLOTS[_cursor_slots.cursor_index]

func _get_selected_item() -> String:
	if _item_selection:
		return _item_list[_cursor_list.cursor_index] if _item_list else ""
	else:
		return _current_character["equipment"][_get_current_slot()]

#Update stats number depending on the current character
#manage also the stat boost column when an item is about to be equip
func _update_stats():
	_level_label.text = str(_current_character["level"])
	for stat in InventoryManager.BOOSTABLE_STATS:
		get_node(_np_values[stat]).text = str(_current_character[stat] + _current_character["boosts"][stat])

	$EquipMenu/Box/CharacterName.text = _current_character["nickname"]
	
	var equipped_item_boost: Dictionary = InventoryManager.calculate_stats_boost_from_slot(_current_character, _get_current_slot())
	var selected_item_boost: Dictionary = globaldata.items.get(_get_selected_item(), {}).get("boost", {})
	
	for stat in InventoryManager.BOOSTABLE_STATS:
		var current_value: int = _current_character[stat] + _current_character["boosts"][stat]
		var projected_value: int = current_value - equipped_item_boost.get(stat, 0) + selected_item_boost.get(stat, 0)

		if projected_value == current_value:
			get_node(_np_boost_values[stat]).text = ""
			get_node(_np_boost_icons[stat]).texture_normal = _boost_icon_empty
		else:
			get_node(_np_boost_values[stat]).text = str(projected_value)
			if projected_value > current_value:
				get_node(_np_boost_icons[stat]).texture_normal = _boost_icon_bonus
			elif projected_value < current_value:
				get_node(_np_boost_icons[stat]).texture_normal = _boost_icon_malus


func _on_slot_cursor_selected(cursor_index: int):
	if !InventoryManager.get_items_for_slot(_current_character.name, _get_current_slot(), true, false).empty():
		_item_selection = true
		_update_panel()
		_cursor_slots.play_sfx("cursor2")
	else:
		_cursor_slots.play_sfx("restricted")

func _on_slot_cursor_cancel():
	Input.action_release("ui_cancel")
	_char_tabs.visible = false
	_char_tabs.active = false
	_cursor_slots.on = false
	_cursor_list.on = false
	$AnimationPlayer.play("Close")
	if $AnimationPlayerDesc.assigned_animation != "Close":
		$AnimationPlayerDesc.play("Close")
	emit_signal("back")

func _on_list_cursor_selected(cursor_index: int):
	if _cursor_list.get_current_item().text == "EQUIP_NONE":
		InventoryManager.unequip_slot(_current_character, _get_current_slot())
		audioManager.play_sfx(load("res://Audio/Sound effects/EB/close.wav"), "menu")
	else:
		InventoryManager.equip_item_from_uid(_current_character, _cursor_list.get_current_item().uid)
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
	_item_selection = false
	_update_panel()

func _on_list_cursor_cancel():
	_cursor_list.play_sfx("back")
	_item_selection = false
	_update_panel()

func _on_cursor_moved(dir: Vector2):
	_update_item_info()

func _update_panel():
	if _item_selection:
		_update_item_list_for_slot()
		_cursor_list.cursor_index = 0
		_char_tabs.active = false
		_cursor_slots.on = false
		_cursor_list.on = true
		_item_panel.visible = true
	else:
		_update_slots()
		_item_panel.visible = false
		_cursor_list.on = false
		_cursor_slots.on = true
		_char_tabs.active = true

#callback function when character is changed
func _on_character_changed(char_name: String):
	_current_character = globaldata.get(char_name)
	_update_slots()

#show proper name of equipped stuff 
func _update_slots():
	var index = 0
	var equipment = _current_character["equipment"]
	var slots_texts = $EquipMenu/Box/Panels/Slots/EquippeditemsNames.get_children()
	#reset slots to "EQUIP_EMPTY"
	for i in slots_texts.size():
		slots_texts[i].text = "EQUIP_EMPTY"
	#set slot names
	for piece in equipment.values():
		if piece != "":
			index = InventoryManager.SLOTS.find(InventoryManager.Load_item_data(piece)["slot"])
			slots_texts[index].text = InventoryManager.Load_item_data(piece).name
	_update_item_info()

#for a specific slot, list all the applicable items from the character inventory
#minus the already equipped one
func _update_item_list_for_slot():
	var char_name: String = _current_character.name
	var current_slot := _get_current_slot()
	var items = InventoryManager.get_items_for_slot(char_name, current_slot, true, true)
	for n in _items_container.get_children():
		n.free()
	_item_list.clear()
	for item in items:
		var item_label =_item_label_template.instance()
		_item_list.append(item.ItemName)
		item_label.uid = item.uid
		_items_container.add_child(item_label)
		item_label.text = item.get_data().name
	
	if _current_character.equipment[current_slot] or items.empty():
		var none_label = _item_label_template.instance()
		_item_list.append("")
		none_label.text = "EQUIP_NONE"
		_items_container.add_child(none_label)
	_update_item_info()

#update portrait modifier according to selected items (both mode)
func _update_portraits():
	var current_item_name
	
	var selected_item = _get_selected_item()
	
	# But we've left the value in the array, just in case.
	if selected_item:
		#valid item, check if suitable, equiped, ....
		current_item_name = selected_item
	else:
		#show nothing on portrait
		for character in global.party:
			var is_suitable = false
			var is_equiped = false
			var is_better = false
			var is_lower = false
			var chara_nam = character["name"].to_lower()
			_char_tabs.update_portrait_modifiers(chara_nam, is_suitable, is_equiped, is_better,is_lower)
		return
			
	#update portrait modifiers
	#for each character, check if:
	for character in global.party:
		var is_suitable = false
		var is_equiped = false
		var is_better = false
		var is_lower = false
		#	- item is suitable for the character
		var chara_nam = character["name"].to_lower()
		
		if chara_nam in global.POSSIBLE_PLAYABLE_MEMBERS:
			is_suitable = InventoryManager.is_usable_by(chara_nam, current_item_name)
			#	- item is equiped
			if InventoryManager.is_equippable(current_item_name):
				is_equiped = InventoryManager.is_equipped_by(chara_nam, current_item_name)
				
				#if not equiped, check if stats boost
				if !is_equiped:
					var res = InventoryManager.is_the_item_better(character, current_item_name)
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
			_char_tabs.update_portrait_modifiers(chara_nam, is_suitable, is_equiped, is_better,is_lower)
	
