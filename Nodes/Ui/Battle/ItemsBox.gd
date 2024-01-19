extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var infoBox

const itemPageSize = Vector2(2, 5)
var itemPageYOffset = 0
var itemList = []

func _ready():
	infoBox = get_node_or_null(infoBox)
	cursor.connect("failed_move", self, "skillBoxBoundaryMoved")

func enter(reset = false, _action = null):
	.enter(reset, _action)
	if reset:
		itemList.clear()
		itemList.append_array(InventoryManager.getInventory(action.user.stats.name))
		cursor.set_cursor_from_index(0, false)
		itemPageYOffset = 0
		updateItems(0)
		if itemList.size() > 0:
			updateInfoBox()
	if infoBox != null and !itemList.empty():
		infoBox.show()

func hide():
	.hide()
	if infoBox != null:
		infoBox.hide()

func move(dir):
	if itemList.size() - 1 < cursor.cursor_index + itemPageYOffset * 2:
		cursor.cursor_index = itemList.size() - itemPageYOffset * 2 - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !itemList.empty() and dir != Vector2.ZERO:
		var itemIdx = cursor.cursor_index + itemPageYOffset * itemPageSize.x
		# if we move to skill that doesn't exist, move back
		if itemIdx > itemList.size() - 1:
			cursor.set_cursor_from_index((int(itemList.size()) % int(itemPageSize.length())) - 1, false)
		updateInfoBox()

func select(idx):
	var i = idx + itemPageYOffset * itemPageSize.x
	if !globaldata.items.has(itemList[i].ItemName) or \
	   !doesItDoAnything(globaldata.items[itemList[i].ItemName]):
		cursor.play_sfx("back")
		return
	action.item = globaldata.items[itemList[i].ItemName]
	action.inv_idx = i
	emit_signal("next")

func updateItems(offsetBy):
	itemPageYOffset += offsetBy
	var itemsOnPage = itemList.slice(itemPageYOffset * itemPageSize.x, itemPageYOffset * itemPageSize.x + itemPageSize.x * itemPageSize.y)
	for itemLabel in $GridContainer.get_children():
		if itemsOnPage.empty():
			itemLabel.text = ""
		else:
			var item = itemsOnPage.pop_front()
			itemLabel.text = globaldata.items[item.ItemName].name["english"]
			if doesItDoAnything(globaldata.items[item.ItemName]):
				itemLabel.set_self_modulate(Color.white)
			else:
				itemLabel.set_self_modulate(Color("bfb4cd"))
#	# update max cursor loc
#	maxCursorLoc = itemPageSize - Vector2(1, 1)
	if (itemPageYOffset + itemPageSize.y) * itemPageSize.x < itemList.size():
		$DownArrow.show()
	else:
		$DownArrow.hide()
	if itemPageYOffset > 0:
		$UpArrow.show()
	else:
		$UpArrow.hide()
	move(Vector2.ZERO)

func skillBoxBoundaryMoved(dir):
	var idx = cursor.cursor_index + (itemPageYOffset * itemPageSize.x)
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * itemPageSize.x) < 0:
			if itemPageYOffset > 0:
				$Arrow.play_sfx("cursor1")
				updateItems(-1)
		elif cursor.cursor_index + (dir.y * itemPageSize.x) > itemPageSize.length():
			if (itemPageYOffset + itemPageSize.y) * itemPageSize.x < itemList.size():
				$Arrow.play_sfx("cursor1")
				updateItems(1)

func updateInfoBox():
	if infoBox != null:
		var item = itemList[cursor.cursor_index + itemPageYOffset * 2]
		if !globaldata.items.has(item.ItemName):
			return
		infoBox.get_child(0).text = globaldata.replaceText(globaldata.items[item.ItemName].description["english"])

func doesItDoAnything(itemData):
	if (itemData.HPrecover != 0 and itemData.boost["maxhp"] == 0) or (itemData.PPrecover != 0 and itemData.boost["maxpp"] == 0) or \
	   ("status_heals" in itemData and !itemData.status_heals.empty()) or\
	   ("battle_action" in itemData and itemData.battle_action != ""):
		return true
	else:
		return false


func _on_Arrow_moved(dir):
	updateInfoBox()
