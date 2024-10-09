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

const cursorCloseSfx = preload("res://Audio/Sound effects/M3/curshoriz.wav")
const registerSfx = preload("res://Audio/Sound effects/M3/register.wav")

# Nodes
onready var descNoDialog = $DescBox/DescriptionPanel
onready var descDialog = $DescBox/DescriptionDialog
onready var shopBox = {
	"header": $ShopBox/Header,
	"separater": $ShopBox/Separator,
	"buy": $ShopBox/BuyMenu,
	"sell": $ShopBox/SellMenu
}
onready var buySellCursor = $BuySellDialog/arrow
onready var characterPortraits = $CharacterSelect/CharacterPortraits

# Common
var _currentCharacter
var _selectedItem
var _prevEquip
var _characterOrder = ["ninten", "lloyd", "ana", "teddy", "pippi", "flyingman", "eve", "canarychick"]
var _characterIdx = 0

# Buy or Sell Menu State
# Buy state
var shopJsonName = ""
var shopList = []
# Sell state
var currentInv = []
# Description Dialog State
enum DialogState {
	BUY,
	EQUIP_BOUGHT,
	SELL_OLD_EQUIP,
	SELL_EQUIP_NO_SPACE,
	SELL_FOR_CASH,
	SELL,
}
# 0 - Buy a {...}?
# 	Yes -> dialog state, 1. process buy item
# 	No -> buy state
# 1 - {...} bought. Equip now?
# 	Yes -> dialog state, 2. process equip item
# 	No -> buy state
# 2 - Sell your old {...}?
# 	Yes -> buy state. process sold item
# 	No -> buy state
# 3 - Your inventory is full, sell {...}?
# 	Yes -> buy state. process sold item
# 	No -> buy state
# 4 - You don't have enough, sell something?
# 	Yes -> sell state
# 	No -> buy state
# 5 - Sell {...}?
# 	Yes -> sell state
# 	No -> sell state

# Called when the node enters the scene tree for the first time.
func _ready():
	buySellCursor.connect("selected", self, "_on_buysell_select")
	buySellCursor.connect("cancel", self, "_on_arrow_cancel")
	shopBox.buy.connect("exited", self, "_on_exit_buy")
	shopBox.buy.connect("entered", self, "_on_enter_buy")
	shopBox.buy.connect("moved", self, "_on_buy_cursor_moved")
	shopBox.buy.connect("selected", self, "_on_buy_item_selected")
	shopBox.sell.connect("exited", self, "_on_exit_sell")
	shopBox.sell.connect("entered", self, "_on_enter_sell")
	shopBox.sell.connect("moved", self, "_on_sell_cursor_moved")
	shopBox.sell.connect("selected", self, "_on_sell_item_selected")
	
	# set up character order
	_characterOrder.clear()
	for partyMem in global.party:
		_characterOrder.append(partyMem.name)
	
	# init shop
	if shopJsonName in globaldata.shopLists:
		shopList = globaldata.shopLists[shopJsonName]
		shopBox.buy.item_list.clear()
		shopBox.buy.restriction_func = funcref(self, "_is_purchasable_cb")
		for item_name in shopList:
			shopBox.buy.item_list.append(InventoryManager.Item.new(item_name, false))
	
	enter_buysell()
	#set up highlights for buy/sell
	$BuySellDialog/VBoxContainer/YesLabel.highlight(1)
	changeCharacter(0)
	_update_cash()

func _input(event):
	if event.is_action_pressed("ui_focus_next"):
		get_tree().set_input_as_handled()
		if !descDialog.open:
			changeCharacter(1)
	elif event.is_action_pressed("ui_focus_prev"):
		get_tree().set_input_as_handled()
		if !descDialog.open:
			changeCharacter(-1)

func close():
	if uiManager.dialogueBox:
		uiManager.dialogueBox.call_deferred("next_dialog")
		queue_free()

func _update_cash():
	$ShopBox/Header/CashBox/Label.text = str(globaldata.cash).pad_zeros(6)

func _is_purchasable_cb(item_instance):
	return !InventoryManager.isInventoryFull(_currentCharacter.name) \
		and globaldata.items[item_instance.ItemName].cost <= globaldata.cash

func _is_sellable_cb(item_instance):
	return globaldata.items[item_instance.ItemName].value > 0


func enter_buysell():
	# hide non-used menus
	$DescBox.hide()
	descDialog.hide()
	descNoDialog.hide()
	shopBox.separater.hide()
	shopBox.buy.hide()
	shopBox.sell.hide()
	_selectedItem = ""
	_prevEquip = ""
	updatePortraits()
	buySellCursor.on = true

func enter_buy(reset=true):
	# some bs to make sure you know what menu ur in lol
	buySellCursor.set_cursor_from_index(0, false)
	buySellCursor.on = false
	$DescBox.show()
	descNoDialog.show()
	shopBox.separater.show()
	shopBox.buy.show()
	shopBox.buy.enter(reset)
	_update_desc_and_portraits(shopBox.buy)

func enter_sell(reset=true):
	# some bs to make sure you know what menu ur in lol
	buySellCursor.set_cursor_from_index(1, false)
	buySellCursor.on = false
	shopBox.sell.restriction_func = funcref(self, "_is_sellable_cb")
	var inv = InventoryManager.getInventory(_currentCharacter.name)
	shopBox.sell.item_list = inv
	$DescBox.show()
	descNoDialog.show()
	shopBox.separater.show()
	shopBox.sell.show()
	shopBox.sell.enter(reset)
	_update_desc_and_portraits(shopBox.sell)

func enter_desc_dialog(state: int):
	if _selectedItem == "":
		_selectedItem = "error"
	var item = _selectedItem
	var question
	match(state):
		DialogState.BUY:
			question = "SHOP_ASK_BUY"
		DialogState.EQUIP_BOUGHT:
			question = "SHOP_ASK_EQUIP"
		DialogState.SELL_OLD_EQUIP:
			item = _prevEquip
			descNoDialog.setItem(_prevEquip)
			question = "SHOP_ASK_SELL_OLD"
		DialogState.SELL:
			question = "SHOP_ASK_SELL"
		DialogState.SELL_EQUIP_NO_SPACE:
			item = _prevEquip
			descNoDialog.setItem(_prevEquip)
			question = "SHOP_ASK_SELL_FOR_SPACE"
		DialogState.SELL_FOR_CASH:
			question = "SHOP_ASK_SELL_FOR_CASH"
	
	question = _format_text_with_item(question, globaldata.items[item])
	descDialog.ask(question, item, funcref(self, "desc_dialog_answer"), [state])
	

func desc_dialog_answer(state: int, yes: bool):
	if _selectedItem == "":
		_selectedItem = "error"
	var item = globaldata.items[_selectedItem]
	match(state):
		DialogState.BUY:
			if yes:
				buy_something()
				if InventoryManager.doesItemHaveFunction(_selectedItem, "equip") and checkCanEquip(_selectedItem, _currentCharacter):
					# next dialog state if equippible
					enter_desc_dialog(DialogState.EQUIP_BOUGHT)
					return
			# else, re enable buy state
			enter_buy(false)
		DialogState.EQUIP_BOUGHT:
			if yes:
				_prevEquip = _currentCharacter["equipment"][item.slot]
				# get most recent item (bought item)
				var recentItem = InventoryManager.getInventory(_currentCharacter.name).back()
				InventoryManager.equipItemFromUID(_currentCharacter, recentItem.uid)
				audioManager.play_sfx(load("res://Audio/Sound effects/M3/equip.wav"), "menu")
				if _prevEquip != "":
					enter_desc_dialog(DialogState.SELL_OLD_EQUIP)
					return
			enter_buy(false)
		DialogState.SELL_OLD_EQUIP:
			if yes:
				sell_something(_prevEquip)
			_prevEquip = ""
			enter_buy(false)
		DialogState.SELL:
			if yes:
				sell_something()
			enter_sell(false)
		DialogState.SELL_EQUIP_NO_SPACE:
			if yes:
				# *sighs*, the things I do around here to get an index
				var inv = InventoryManager.getInventory(_currentCharacter.name)
				var idx = -1
				for i in inv.size():
					if inv[i].ItemName == _prevEquip and inv[i].equiped:
						idx = i
				sell_something(_prevEquip, idx)
				enter_desc_dialog(DialogState.BUY)
				_prevEquip = ""
				return
			_prevEquip = ""
			enter_buy(false)
		DialogState.SELL_FOR_CASH:
			if yes:
				shopBox.buy.exit()
				shopBox.buy.hide()
				enter_sell()
			else:
				enter_buy(false)

func buy_something():
	$AudioStreamPlayer.stream = registerSfx
	$AudioStreamPlayer.play()
	var item = globaldata.items[_selectedItem]
	globaldata.cash -= item.cost
	var itemIdx = InventoryManager.getInventory(_currentCharacter.name)
	InventoryManager.addItem(_currentCharacter.name, _selectedItem)
	# update purchasables(in cash update?)
	_update_cash()

func sell_something(item_name = _selectedItem, idx = -1):
	$AudioStreamPlayer.stream = registerSfx
	$AudioStreamPlayer.play()
	var item = globaldata.items[item_name]
	globaldata.cash += item.value
	if item_name == _prevEquip:
		InventoryManager.dropItem(_currentCharacter.name, InventoryManager.findItemIdx(_currentCharacter.name, item_name))
	else:
		if idx > 0:
			InventoryManager.dropItem(_currentCharacter.name, idx)
		else:
			InventoryManager.dropItem(_currentCharacter.name, shopBox.sell.cursor.cursor_index + shopBox.sell.page)
	# update sell list
	_update_cash()

func updatePortraits(highlighted_item=null):
	for i in 4: # there's 4 portraits!
		var portraitNode = characterPortraits.get_node(str("Party", i + 1))
		if i >= _characterOrder.size():
			portraitNode.texture = null
		elif i == _characterIdx:
			portraitNode.texture = hlportraitSprites[_characterOrder[i]]
		else:
			portraitNode.texture = portraitSprites[_characterOrder[i]]
		
		# equipment information
		var is_suitable = false
		var is_equiped = false
		var is_better = false
		var is_lower = false
		if i < _characterOrder.size():
			if highlighted_item and !InventoryManager.isInventoryFull(_characterOrder[i]):
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
		portraitNode.show_is_item_suitable(is_suitable)
		portraitNode.show_is_item_equiped(is_equiped)
		portraitNode.show_is_item_better(is_better)
		portraitNode.show_is_item_lower(is_lower)

func _update_desc_and_portraits(current_menu):
	var item_id = current_menu.get_current_item_id()
	updatePortraits(item_id)
	descNoDialog.setItem(item_id)

func changeCharacter(dir):
	_characterIdx = wrapi(_characterIdx + dir, 0, _characterOrder.size())
	# change _currentCharacter
	for partyMem in global.party:
		if partyMem.name == _characterOrder[_characterIdx]:
			_currentCharacter = partyMem
	#if in "sell" phase, reenter it to refresh items
	if shopBox.sell.visible:
		shopBox.sell.exit()
		shopBox.sell.hide()
		buySellCursor.on = false
		enter_sell()
	elif shopBox.buy.visible:
		#updatePortraits(shopBox.buy.get_current_item_id())
		enter_buy(false)
	#Trust me this is helpful
	else:
		updatePortraits()

func checkCanEquip(itemname, character):
	var itemdata = globaldata.items[itemname]
	return itemdata.usable[character.name]

# SIGNAL CONNECTIONS


func _on_buysell_select(idx):
	if idx == 0:
		enter_buy()
	else:
		enter_sell()

func _on_exit_buy():
	enter_buysell()
	$AudioStreamPlayer.stream = cursorCloseSfx
	$AudioStreamPlayer.play()

func _on_exit_sell():
	enter_buysell()
	$AudioStreamPlayer.stream = cursorCloseSfx
	$AudioStreamPlayer.play()

func _on_buy_cursor_moved(itemIdx):
	_update_desc_and_portraits(shopBox.buy)

func _on_buy_item_selected(itemIdx):
	var item_id = shopBox.buy.get_current_item_id()
	var itemData = globaldata.items[item_id]
	if InventoryManager.isInventoryFull(_currentCharacter.name):
		_prevEquip = _currentCharacter.equipment[itemData.slot] if (itemData.slot in _currentCharacter["equipment"]) else ""
		# For SELL_EQUIP_NO_SPACE: The party member should be able to equip the item,
		# they should have another equippable item in the same slot, it should be different,
		# and they should have enough money to buy it after selling the current one
		if checkCanEquip(item_id, _currentCharacter) and InventoryManager.doesItemHaveFunction(item_id, "equip") \
		  and _prevEquip != "" and _prevEquip != item_id \
		  and itemData.cost - globaldata.items[_prevEquip].value <= globaldata.cash:
			_selectedItem = item_id
			shopBox.buy.cursor.on = false
			enter_desc_dialog(DialogState.SELL_EQUIP_NO_SPACE)
		else:
			descNoDialog.warn(tr("TRANSACTION_FULL"), 1)
	elif itemData.cost > globaldata.cash:
		_selectedItem = item_id
		shopBox.buy.cursor.on = false
		enter_desc_dialog(DialogState.SELL_FOR_CASH)
	else:
		_selectedItem = item_id
		shopBox.buy.cursor.on = false
		enter_desc_dialog(DialogState.BUY)

func _on_sell_cursor_moved(itemIdx):
	_update_desc_and_portraits(shopBox.sell)

func _on_sell_item_selected(itemIdx):
	var item_id = shopBox.sell.get_current_item_id()
	var itemData = globaldata.items[item_id]
	if itemData.value <= 0:
		return
	_selectedItem = item_id
	shopBox.sell.cursor.on = false
	enter_desc_dialog(DialogState.SELL)

func _on_enter_buy():
	if shopBox.buy.item_list.empty():
		$DescBox.hide()
	else:
		$DescBox.show()

func _on_enter_sell():
	if shopBox.sell.item_list.empty():
		$DescBox.hide()
	else:
		$DescBox.show()

func _on_arrow_cancel():
	uiManager.remove_ui(self)

# LOCALIZATION Code added: New method to handle formatting of items and articles in text
# Same method in Storage.gd
func _format_text_with_item(text, item):
	return tr(text).format({
		"item": tr(item.name)
		}).format(
			globaldata.get_item_or_skill_articles(item), "{i_}"
		)
