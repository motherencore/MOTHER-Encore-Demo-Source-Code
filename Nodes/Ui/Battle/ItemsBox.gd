extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export (NodePath) var infoBox

onready var animationPlayer = $AnimationPlayer
onready var scrollbar = $Scrollbar

const itemPageSize = Vector2(2, 5)
var itemPageYOffset = 0
var itemList = []


func _ready():
	infoBox = get_node_or_null(infoBox)
	cursor.connect("failed_move", self, "skillBoxBoundaryMoved")
	scrollbar.nb_visible_rows = itemPageSize.y

func enter(reset = false, _action = null):
	.enter(reset, _action)
	animationPlayer.play("Open")
	scrollbar.on = true
	if reset:
		itemList.clear()
		itemList.append_array(InventoryManager.getInventory(action.user.stats.name))
		cursor.set_cursor_from_index(0, false)
		itemPageYOffset = 0
		scrollbar.position = itemPageYOffset
		updateItems(0)
		updateInfoBox()
	if infoBox != null and !itemList.empty():
		infoBox.activate()

func hide():
	if visible:
		animationPlayer.play("Close")
	.hide()
	scrollbar.on = false
	if infoBox != null:
		infoBox.deactivate()

func move(dir):
	if itemList.size() - 1 < cursor.cursor_index + itemPageYOffset * itemPageSize.x:
		cursor.cursor_index = itemList.size() - itemPageYOffset * itemPageSize.x - 1
		cursor.set_cursor_from_index(cursor.cursor_index)
	if !itemList.empty() and dir != Vector2.ZERO:
		var itemIdx = cursor.cursor_index + itemPageYOffset * itemPageSize.x
		# if we move to skill that doesn't exist, move back
		if itemIdx > itemList.size() - 1:
			cursor.set_cursor_from_index((int(itemList.size()) % int(itemPageSize.x)) - 1, false)
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

func updateItems(yOffset):
	itemPageYOffset = yOffset
	var itemsOnPage = itemList.slice(itemPageYOffset * itemPageSize.x, itemPageYOffset * itemPageSize.x + itemPageSize.x * itemPageSize.y)
	for itemLabel in $GridContainer.get_children():
		if itemsOnPage.empty():
			itemLabel.text = ""
		else:
			var item = itemsOnPage.pop_front()
			# LOCALIZATION Code change: Removed use of ".english" here
			itemLabel.text = globaldata.items[item.ItemName].name
			if doesItDoAnything(globaldata.items[item.ItemName]):
				itemLabel.set_self_modulate(Color.white)
			else:
				itemLabel.set_self_modulate(Color("bfb4cd"))
#	# update max cursor loc
#	maxCursorLoc = itemPageSize - Vector2(1, 1)
	move(Vector2.ZERO)
	scrollbar.nb_rows = ceil(itemList.size() / itemPageSize.x)

func skillBoxBoundaryMoved(dir):
	if dir.y != 0:
		if cursor.cursor_index + (dir.y * itemPageSize.x) < 0:
			cursor.play_sfx("cursor1")
			if itemPageYOffset > 0:
				updateItems(itemPageYOffset - 1)
			else:
				if itemList.size() > itemPageSize.x * itemPageSize.y:
					updateItems(ceil(itemList.size() / itemPageSize.x) - itemPageSize.y)
				var xPos = posmod(cursor.cursor_index, int(itemPageSize.x))
				var yPos = ceil((itemList.size() - xPos) / itemPageSize.x) - 1
				cursor.set_cursor_from_index((yPos - itemPageYOffset) * itemPageSize.x + xPos, false)
		elif cursor.cursor_index + (dir.y * itemPageSize.x) >= min(itemPageSize.x * itemPageSize.y, itemList.size() - itemPageYOffset * itemPageSize.x):
			cursor.play_sfx("cursor1")
			if (itemPageYOffset + itemPageSize.y) * itemPageSize.x < itemList.size():
				updateItems(itemPageYOffset + 1)
			else:
				updateItems(0)
				cursor.set_cursor_from_index(posmod(cursor.cursor_index, int(itemPageSize.x)), false)
		scrollbar.position = itemPageYOffset
	if dir.x != 0:
		cursor.play_sfx("cursor1")
		var xPos = posmod(int(cursor.cursor_index + dir.x), int(itemPageSize.x))
		var yPos = floor(cursor.cursor_index / itemPageSize.x)
		cursor.set_cursor_from_index(yPos * itemPageSize.x + xPos, false)
	updateInfoBox()

func updateInfoBox():
	if infoBox != null:
		if cursor.cursor_index == -1:
			infoBox.update_info("")
		else:
			var item = itemList[cursor.cursor_index + itemPageYOffset * 2]
			if !globaldata.items.has(item.ItemName):
				return
			var description = globaldata.replaceText(globaldata.items[item.ItemName].description)
			infoBox.update_info(description) 

func doesItDoAnything(itemData):
	if (itemData.HPrecover != 0 and itemData.boost["maxhp"] == 0) or (itemData.PPrecover != 0 and itemData.boost["maxpp"] == 0) or \
	   ("status_heals" in itemData and !itemData.status_heals.empty()) or\
	   ("battle_action" in itemData and itemData.battle_action != ""):
		return true
	else:
		return false

func _on_Arrow_moved(dir):
	updateInfoBox()
