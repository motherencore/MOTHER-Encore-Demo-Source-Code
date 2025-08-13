extends Control

signal back
signal exit

onready var _party_info_view = uiManager.party_info_view

#external paths and references
onready var ItemLabelTemplate = preload("res://Nodes/Ui/HighlightLabel.tscn")

onready var _select_panel = $InventorySelect
onready var _stats_bar = $Bottom/StatsBar
onready var _dialog_box = $Bottom/DialogBox
onready var _action_select = $ActionSelect
onready var _arrow: Cursor = $Inventory/Arrow
onready var _items_grid = $Inventory/CenterContainer/Items/GridContainer 
onready var _scroll_bar = $Inventory/DescriptionPanel/Scrollbar

const NB_COLUMNS := 2
const NB_ROWS_WITH_DESC := 5
const ARROW_MOVE_OFFSET_X := 123
const ARROW_MOVE_OFFSET_Y := 12
const MAX_SUBMENU_POSITION := 60

var _is_active := false

var _current_character := "ninten"
var _current_inventory := []
var _current_scroll_pos := 0
var _is_desc_shown := false
var _swap_mode := false
var _swap_source := ""
var _swap_source_item := 0
var _swap_target: = ""
var _sort_mode := false
var _sort_source_idx := 0

	
func open(party_member: Dictionary):
	_current_character = party_member["name"].to_lower()
	_select_panel.InitFromCharacter(_current_character)
	_show_hide_description(globaldata.description)
	_scroll_bar.nb_visible_rows = NB_ROWS_WITH_DESC
	_update_inventory(true)
	_update_party_infos()
	_set_active(true)
	$AnimationPlayer.play("Open")
	$Inventory.visible = true
	_select_panel.visible = true
	_highlight()
	
func _update_inventory(reset_select: bool):
	_current_inventory = InventoryManager.getInventory(_current_character)
	if reset_select:
		_current_scroll_pos = 0
		_set_selected_idx(0)
	else:
		pass
		#_idx_y = int(clamp(_idx_y, 1, _get_max_items_rows()))
	_update_scroll()	
	
func _ready():
	$Inventory.visible = false
	_update_list_view()
	global.connect("locale_changed", self, "_update_description")
	
#Update the list 	
func _update_list_view(select_idx := -1):
	for i in _items_grid.get_child_count():
		var which_row = i / NB_COLUMNS
		var item_label = _items_grid.get_child(i)
		var item_idx = i + _current_scroll_pos * 2
		if item_idx < _current_inventory.size() and (!_is_desc_shown or i < NB_ROWS_WITH_DESC * NB_COLUMNS):
			var item = _current_inventory[item_idx]
			item_label.text = item.get_data()["name"]
			item_label.show_equiped(item.equiped)
		else:
			item_label.text = ""
			item_label.show_equiped(false)

	_arrow.visible = !_is_inventory_empty()
			
	var total_rows = ceil(_current_inventory.size() * 1.0 / NB_COLUMNS)

	# In case scrolling goes above the last row (like, because an item was deleted and the last row is empty)
	if total_rows < _current_scroll_pos + NB_ROWS_WITH_DESC:
		total_rows = _current_scroll_pos + NB_ROWS_WITH_DESC

	if select_idx > -1:
		_arrow.set_cursor_from_index(select_idx - _current_scroll_pos * NB_COLUMNS, false)

	_scroll_bar.nb_rows = total_rows
	_scroll_bar.position = _current_scroll_pos

	_highlight()
	_update_item_details()

func _update_item_details():
	_update_description()
	_update_portraits()

func _set_active(val: bool):
	_is_active = val
	_update_select_panel_state()
	_arrow.on = val

func _update_select_panel_state():
	_select_panel.active = _is_active and !_sort_mode

func _is_inventory_empty() -> bool:
	return _current_inventory.empty()

func _get_selected_pos_x() -> int:
	return _get_selected_idx() % NB_COLUMNS

func _get_selected_pos_y() -> int:
	return _get_selected_idx() / NB_COLUMNS

func _get_selected_idx() -> int:
	var idx := _arrow.cursor_index + _current_scroll_pos * NB_COLUMNS
	if _current_inventory.size() in range(1, idx + 1):
		idx = _current_inventory.size() - 1
	return idx

func _update_scroll():
	_set_selected_idx(_get_selected_idx())

func _set_selected_idx(index: int):
	if _is_desc_shown:
		if index < NB_COLUMNS * _current_scroll_pos:
			_current_scroll_pos = index / NB_COLUMNS
		elif index >= NB_COLUMNS * (_current_scroll_pos + NB_ROWS_WITH_DESC):
			_current_scroll_pos = index / NB_COLUMNS - NB_ROWS_WITH_DESC + 1
	else:
		_current_scroll_pos = 0
		
	_update_list_view(index)

func _get_max_items_rows(pos_x: int) -> int:
	return ((_current_inventory.size() / NB_COLUMNS)+((-pos_x) * (_current_inventory.size() % NB_COLUMNS)))+(_current_inventory.size() % NB_COLUMNS)

func _update_description():
	if _get_selected_idx() < _current_inventory.size():
		$Inventory/DescriptionPanel.set_item_from_inv(_current_inventory[_get_selected_idx()])
	else:
		$Inventory/DescriptionPanel.set_item_from_inv(null)

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
		if chara_nam in global.POSSIBLE_PLAYABLE_MEMBERS:
			if _get_selected_idx() < _current_inventory.size():
				var current_item_name = _current_inventory[_get_selected_idx()].ItemName
				
				if InventoryManager.is_equippable(current_item_name):
					is_suitable = InventoryManager.is_usable_by(chara_nam, current_item_name)
					#- item is equiped
					is_equiped = InventoryManager.is_equipped_by(chara_nam, current_item_name)
					
					#if not equiped, check if stats boost
					if !is_equiped:
						var res = InventoryManager.is_the_item_better(InventoryManager.get_global_data(chara_nam), current_item_name)
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
				_select_panel.update_portrait_modifiers(chara_nam, is_suitable, is_equiped, is_better, is_lower)

func _update_party_infos(set := true):
	if _party_info_view:
		_party_info_view.update_party_infos(set)

func _on_arrow_moved(dir: Vector2):
	#check for inputs for selecting items in the inventory
	_update_item_details()
	if !_is_inventory_empty():
		_highlight()

func _on_arrow_failed_move(dir: Vector2):
	if !_is_inventory_empty():
		_arrow.play_sfx("cursor1")

		var pos_x = _get_selected_pos_x()
		var pos_y = _get_selected_pos_y()
		pos_y += dir.y

		if pos_y >= _get_max_items_rows(pos_x):
			pos_y = 0
		elif pos_y < 0:
			pos_y = _get_max_items_rows(pos_x) - 1

		pos_x = posmod(pos_x + int(dir.x), NB_COLUMNS)

		_set_selected_idx(pos_y * NB_COLUMNS + pos_x)

		_update_scroll()

func _on_arrow_selected(cursor_index: int):
	if !_is_inventory_empty():
		#item selected and validated, show actions box at the right place
		Input.action_release("ui_accept")
		var item = _current_inventory[_get_selected_idx()].ItemName
		if _swap_mode:
			InventoryManager.swap_between_characters(_swap_source, _swap_target, _swap_source_item, _get_selected_idx())
			_swap_mode = false
			_set_active(false)
			_set_selected_idx(_swap_source_item)
			_current_character = _swap_source
			_select_panel.set_swap_mode(false, _swap_source, _swap_target)
			_show_hide_description(globaldata.description)
			_update_inventory(false)
			_action_select.visible = true
			_action_select.chain_with_equip()
		elif _sort_mode:
			var target_idx = _get_selected_idx()
			InventoryManager.switch_items(_current_character, _sort_source_idx, target_idx)
			_update_inventory(false)
			_sort_mode = false
			_show_hide_description(globaldata.description)
			_update_list_view()
			_update_select_panel_state()		
		else:
			var side := -1.5 if _get_selected_pos_x() == 1 else 1.0
			var submenu_position = $Inventory/Arrow/Position2D.global_position
			submenu_position.x = submenu_position.x + 25 * side
			submenu_position.y = min(MAX_SUBMENU_POSITION, submenu_position.y)
			_action_select.set_for_new_item(submenu_position, item, side, _current_character,_get_selected_idx())
			_set_active(false)

func _on_arrow_cancel():
	if _sort_mode:
		_arrow.play_sfx("back")
		_sort_mode = false
		_show_hide_description(globaldata.description)
		_highlight()
		_update_select_panel_state()
	elif _swap_mode:
		_arrow.play_sfx("back")
		_swap_mode = false
		_show_hide_description(globaldata.description)
		_highlight()
		_select_panel.set_swap_mode(false, _swap_source, _swap_target )
		_current_character = _swap_source
		_update_inventory(false)
	else:
		_close()

func _input(event: InputEvent):
	if _is_active and !_is_inventory_empty():
		if event.is_action_pressed("ui_scope"):
			Input.action_release("ui_scope")
			if !_swap_mode and !_sort_mode:
				globaldata.description = !globaldata.description
				_show_hide_description(globaldata.description)
					
#highlight item
func _highlight():
	var item_to_hl = _arrow.cursor_index

	var items = _items_grid.get_children()

	for item_idx in items.size():
		if _sort_mode and item_idx == _sort_source_idx:
			if items[item_idx].blinking == false:
				items[item_idx].blink(true)
		elif item_idx == item_to_hl and item_idx < _current_inventory.size():
			if _swap_mode:
				if !items[item_idx].blinking:
					items[item_idx].blink(true)
			else:
				if items[item_idx].blinking:
					items[item_idx].blink(false)
				items[item_idx].highlight(1)
		else:
			if items[item_idx].blinking:
				items[item_idx].blink(false)
			items[item_idx].highlight(0)

func _show_hide_description(value: bool):
	$Inventory/DescriptionPanel.visible = value
	_is_desc_shown = value
	_update_scroll()
	#_update_list_view()

func _on_InventorySelect_character_changed(character: String):
	_current_character = character
	_update_inventory(true)

func _on_ActionSelect_back():
	_update_inventory(false)
	_set_active(true)
	_update_select_panel_state()
		
func _on_ActionSelect_exit():
	_close(true)

func _on_ActionSelect_swapmode(target: String):
	_show_hide_description(false)
	_swap_source = _current_character
	_swap_source_item = _get_selected_idx()
	_current_character = target
	_swap_target = target
	_swap_mode = true
	_select_panel.set_swap_mode(true, _swap_source, _swap_target )
	_update_inventory(false)


func _on_ActionSelect_sortmode():
	_show_hide_description(false)
	_sort_source_idx = _get_selected_idx()
	_sort_mode = true
	_update_select_panel_state()

func _on_ActionSelect_show_statsbar(character: String, unequip := false):
	
	var modifiersDic = {}
	var chara_data = InventoryManager.get_global_data(character)
	var item = _current_inventory[_get_selected_idx()].ItemName
	var item_stats = globaldata.items[item]
	var item_slot = item_stats["slot"] 
	var is_equiped = false
	
	#test if item equiped:
	var projected_stat
	
	if chara_data == null:
		_hide_stats_bar()
	elif chara_data["equipment"][item_slot] != item:
		for stat in _stats_bar.stats_list:
			if item_stats["boost"].has(stat):
				var boost = int(item_stats["boost"][stat])
				if boost != 0:
					var equiped_item = chara_data["equipment"][item_slot]
					var equiped_boost = 0
					if equiped_item != "":
						equiped_boost = globaldata.items[equiped_item]["boost"][stat]
					projected_stat = chara_data[stat] + chara_data["boosts"][stat] - equiped_boost + boost
						
					modifiersDic[stat] = projected_stat
	else:
		for stat in _stats_bar.stats_list:
			if item_stats["boost"].has(stat):
				var boost = int(item_stats["boost"][stat])
				if boost != 0:
					var equiped_item = chara_data["equipment"][item_slot]
					var equiped_boost = 0
					if equiped_item != "":
						equiped_boost = globaldata.items[equiped_item]["boost"][stat]
					projected_stat = chara_data[stat] + chara_data["boosts"][stat] - equiped_boost
						
					modifiersDic[stat] = projected_stat
				
	_stats_bar.show_statsBar(chara_data, modifiersDic)
	_party_info_view.close()

func _on_ActionSelect_hide_statsbar():
	_hide_stats_bar()

func _on_TargetCharaSelect_hide_statsbar():
	_hide_stats_bar()

func _hide_stats_bar():
	_stats_bar.hide_statsBar()
	_party_info_view.open()

func _close(exit_pause := false):
	$AnimationPlayer.play("Close")
	_set_active(false)
	emit_signal("exit" if exit_pause else "back")

func _on_ActionSelect_show_dialogbox(dialog: String, character = "", value := 0, stat := "", item = null):
	yield(get_tree(), "idle_frame")
	_set_active(false)
	_dialog_box.show_dialog_box(dialog, character, value, stat, item)
	_update_description()
	_update_portraits()

func _on_DialogBox_back():
	_update_party_infos()
	_update_scroll()
	_set_active(true)

