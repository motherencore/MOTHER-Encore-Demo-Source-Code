extends Control

var portraitSprites = {
	"ninten": preload("res://Graphics/UI/Inventory/characters/ninten.png"),
	"ana": preload("res://Graphics/UI/Inventory/characters/ana.png"),
	"lloyd": preload("res://Graphics/UI/Inventory/characters/lloyd.png"),
	"teddy": preload("res://Graphics/UI/Inventory/characters/teddy.png"),
	"pippi": preload("res://Graphics/UI/Inventory/characters/pippi.png"),
	"flyingman": preload("res://Graphics/UI/Inventory/characters/flyingman.png"),
	"eve": preload("res://Graphics/UI/Inventory/characters/eve.png"),
	"canarychick": preload("res://Graphics/UI/Inventory/characters/canarychick.png"),
}

var hlportraitSprites = {
	"ninten": preload("res://Graphics/UI/Inventory/characters/ninten_hl.png"),
	"ana": preload("res://Graphics/UI/Inventory/characters/ana_hl.png"),
	"lloyd": preload("res://Graphics/UI/Inventory/characters/lloyd_hl.png"),
	"teddy": preload("res://Graphics/UI/Inventory/characters/teddy_hl.png"),
	"pippi": preload("res://Graphics/UI/Inventory/characters/pippi_hl.png"),
	"flyingman": preload("res://Graphics/UI/Inventory/characters/flyingman_hl.png"),
	"eve": preload("res://Graphics/UI/Inventory/characters/eve_hl.png"),
	"canarychick": preload("res://Graphics/UI/Inventory/characters/canarychick_hl.png")
}

# Nodes
onready var charaSelect = $StorageBox/InventorySelect
onready var listOnHand = $StorageBox/ItemsOnHand
onready var listStorage = $StorageBox/ItemsStored
onready var description = $DescBox/DescriptionPanel
onready var dialog = $DescBox/DescriptionDialog

var god_mode = false setget _set_god_mode

var _characterOrder = ["ninten", "lloyd", "ana", "teddy", "pippi", "flyingman", "eve", "canarychick"]
var _characterIdx = 0
var _storage_id = InventoryManager.ID_STORAGE

# Common
var _current_character_name
var _currentPanelIsStorage = false

func _ready():
	$StorageBox/Separator.modulate = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR%s" % 2)

	_set_god_mode()

	charaSelect.visible = true
	charaSelect.active = true

	charaSelect.connect("character_changed", self, "_change_character")
	listOnHand.connect("moved", self, "_on_list_move")
	listStorage.connect("moved", self, "_on_list_move")
	listOnHand.connect("selected", self, "_on_selected_on_hand")
	listStorage.connect("selected", self, "_on_selected_storage")
	listOnHand.connect("failed_select", self, "_on_failed_select")
	listStorage.connect("failed_select", self, "_on_failed_select")
	listOnHand.connect("exited", self, "_on_exit_on_hand")
	listStorage.connect("exited", self, "_on_exit_storage")
	dialog.connect("closed", self, "_on_dialog_closed")
	global.connect("locale_changed", self, "_update_desc")

	# set up character order
	_characterOrder.clear()
	for partyMem in global.party:
		_characterOrder.append(partyMem.name)

	_change_character(_characterOrder[0])
	_update_list_storage()
	_switch_to_panel(false, true)
	_update_desc()

func _set_god_mode(value = god_mode):
	god_mode = value
	_storage_id = InventoryManager.ID_STORAGE_GOD if value else InventoryManager.ID_STORAGE
	if charaSelect:
		charaSelect.noKey = !value
		charaSelect.include_storage = value

func _on_arrow_failed_move(dir):
	if !dialog.open:
		if dir.x < 0:
			_switch_to_panel(false, false, true)
		elif dir.x > 0:
			_switch_to_panel(true, false, true)
		

func _switch_to_panel(isStorage, force = false, same_index = false):
	var cur_index = listStorage.cursor.cursor_index if _currentPanelIsStorage else listOnHand.cursor.cursor_index

	if (!isStorage) and (force or !listOnHand.item_list.empty()): # To "on hand" panel
		if _currentPanelIsStorage:
			listOnHand.cursor.play_sfx("cursor1")
		_currentPanelIsStorage = false
		listOnHand.enter(false, cur_index if same_index else -1)
		listStorage.exit()
		_update_desc()			
	elif isStorage and (force or !listStorage.item_list.empty()): # To storage panel
		if !_currentPanelIsStorage:
			listOnHand.cursor.play_sfx("cursor1")
		_currentPanelIsStorage = true
		listStorage.enter(false, cur_index if same_index else -1)
		listOnHand.exit()
		_update_desc()

func _change_character(character):
	_current_character_name = character
	
	_update_portraits()
	_update_list_on_hand()
	_update_list_storage()
	_update_desc()


func _update_list_on_hand():
	var isFull = InventoryManager.isInventoryFull(_storage_id)
	_update_list(listOnHand, _current_character_name, isFull)

func _update_list_storage():
	var isFull = InventoryManager.isInventoryFull(_current_character_name)
	_update_list(listStorage, _storage_id, isFull)
	$StorageBox/TitleAndCounter/Counter/Label.text = "%s/%s" % [listStorage.item_list.size(), InventoryManager.get_inventory_size(_storage_id)]

func _update_list(list, targetId, isDisabled):
	list.restriction_func = funcref(self, "_list_restrictions_cb")
	list.item_list = InventoryManager.getInventory(targetId)

func _list_restrictions_cb(item_instance):
	if item_instance in InventoryManager.Inventories[_current_character_name]:
		return !InventoryManager.isInventoryFull(_storage_id)
	else:
		return !InventoryManager.isInventoryFull(_current_character_name)

func _update_portraits(highlighted_item=null):
	for i in 4: # there's 4 portraits!
		# equipment information
		var is_suitable = false
		var is_equiped = false
		var is_better = false
		var is_lower = false
		if i < _characterOrder.size():
			if highlighted_item:
				var current_item_data = globaldata.items[highlighted_item]
				var character = _characterOrder[i]
				if InventoryManager.doesItemHaveFunction(highlighted_item, "equip"):
					is_suitable = current_item_data["usable"][character]
					var current_item_slot = current_item_data["slot"]
					#- item is equiped
					is_equiped = global.party[i]["equipment"][current_item_slot] == highlighted_item
					
					#if not equiped, check if stats boost
					if !is_equiped:
						var res = InventoryManager.is_the_item_better(global.party[i], highlighted_item)
						match res:
							1:
								is_better = true
							-1:
								is_lower = true
			is_suitable = is_suitable and !is_equiped
			charaSelect.Update_portrait_modifiers(_characterOrder[i], is_suitable, is_equiped, is_better, is_lower)


func _on_list_move(itemPos):
	_update_desc()

func _update_desc():
	var fromList
	if !_currentPanelIsStorage:
		fromList = listOnHand
	else:
		fromList = listStorage
	var item_id = fromList.get_current_item_id()
	_update_portraits(item_id)
	description.setItem(item_id)

func _on_selected_on_hand(itemPos):
	if !InventoryManager.isInventoryFull(_storage_id):
		var item_id = listOnHand.get_current_item_id()
		var itemData = globaldata.items[item_id]
		var is_equiped = InventoryManager.getInventory(_current_character_name)[itemPos].equiped

		if is_equiped:
			var question_str = _format_text_with_item("TRANSACTION_ASK_UNEQUIP", itemData)
			_ask_user(question_str, item_id, "_unequip_and_store", [_current_character_name, itemPos])
		else:
			_store_item(_current_character_name, itemPos)
	else:
		_warn_user(tr("TRANSACTION_STORAGE_FULL"))


func _on_selected_storage(itemPos):
	if !InventoryManager.isInventoryFull(_current_character_name):
		var item_id = listStorage.get_current_item_id()
		_withdraw_item(_current_character_name, itemPos)
		var itemData = globaldata.items[item_id]
		var canEquip = InventoryManager.doesItemHaveFunction(item_id, "equip") && itemData["usable"][_current_character_name]
		if canEquip:
			var itemUid = InventoryManager.getInventory(_current_character_name).back().uid
			var question_str = _format_text_with_item("SHOP_ASK_EQUIP", itemData)
			_ask_user(question_str, item_id, "_equip_after_withdrawal", [ _current_character_name, itemUid])
	else:
		_warn_user(tr("TRANSACTION_FULL"))

func _ask_user(question_str, item_id, callback, cbParams):
	dialog.ask(question_str, item_id, funcref(self, callback), cbParams, true)
	listOnHand.exit()
	listStorage.exit()
	charaSelect.active = false

func _warn_user(question_str):
	description.warn(question_str, 1)

func _on_dialog_closed():
	charaSelect.active = true
	_switch_to_panel(_currentPanelIsStorage, true)

func _unequip_and_store(character_name, itemPos):
	audioManager.play_sfx(load("res://Audio/Sound effects/EB/close.wav"), "menu")
	_store_item(character_name, itemPos)

func _equip_after_withdrawal(character_name, itemPos):
	audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
	var itemUid = InventoryManager.getInventory(character_name).back().uid
	var character_data = InventoryManager.Get_global_data(character_name)
	if character_data:
		InventoryManager.equipItemFromUID(character_data, itemUid)
	_update_list_on_hand()

func _store_item(characterName, itemPos):
	_item_transaction(characterName, _storage_id, itemPos, listStorage, true)

func _withdraw_item(characterName, itemPos):
	_item_transaction(_storage_id, characterName, itemPos, listOnHand)

func _item_transaction(source, target, itemPos, targetList, sort=false):
	var item_id = InventoryManager.getInventory(source)[itemPos].ItemName
	InventoryManager.giveItem(source, target, itemPos)
	if sort:
		InventoryManager.sortAuto(_storage_id)
	_update_list_on_hand()
	_update_list_storage()
	_update_desc()
	_scroll_to_focus(targetList, item_id)

func _scroll_to_focus(list, item_id):
	var newPos = 0
	for i in list.item_list.size():
		if list.item_list[i].ItemName == item_id:
			newPos = i
	list.scroll_to(newPos)

func _on_failed_select(itemPos):
	audioManager.play_sfx(load("res://Audio/Sound effects/M3/bump.wav"), "menu")

func _on_exit_on_hand():
	print("exit 1")
	if not _currentPanelIsStorage and dialog.open == false:
		uiManager.remove_ui(self)

func _on_exit_storage():
	print("exit 2")
	if _currentPanelIsStorage and dialog.open == false:
		uiManager.remove_ui(self)

func close():
	print("close %s" % var2str(get_stack()))
	if is_instance_valid(uiManager.dialogueBox):
		uiManager.dialogueBox.call_deferred("next_dialog")
	else:
		global.persistPlayer.unpause()
	queue_free()

# LOCALIZATION Code added: New method to handle formatting of items and articles in text
# Same method in ShopUI.gd
func _format_text_with_item(text, item):
	return tr(text).format({
		"item": tr(item.name)
		}).format(
			globaldata.get_item_or_skill_articles(item), "{i_}"
		)
