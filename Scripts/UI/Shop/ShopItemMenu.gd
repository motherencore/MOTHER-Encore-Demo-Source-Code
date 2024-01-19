extends NinePatchRect

onready var cursor = get_node_or_null("arrow")
onready var lines = $MarginContainer/VBoxContainer.get_children()
onready var scrollbg = $ScrollBG
onready var scrollbar = $ScrollBG/ScrollBar

export(String) var priceType = "cost"

const linesPerPage = 6
var page = 0

var itemList = []
var restrictions = []

signal selected(item)
signal moved(item)
signal exited()
signal entered()

func _ready():
	if cursor:
		cursor.connect("moved", self, "_on_cursor_move")
		cursor.connect("failed_move", self, "_on_cursor_failed_move")
		cursor.connect("selected", self, "_on_cursor_select")

func enter(reset=true):
	show()
	if reset:
		page = 0
		cursor.cursor_index = 0
		set_highlight(0)
	# check if the page is too far and there's no other items
	if page >= itemList.size():
		page = max(0, itemList.size() - 1)
	_updatePage()
	cursor.on = true
	if !itemList.empty():
		cursor.set_cursor_from_index(cursor.cursor_index, false)
		if itemList.size() > linesPerPage:
			scrollbg.show()
			set_scroll()
		else:
			scrollbg.hide()
	emit_signal("entered")

func exit():
	cursor.on = false
	hide()
	emit_signal("exited")

func get_current_item():
	if !itemList.empty():
		if itemList.size() > cursor.cursor_index + page:
			return itemList[cursor.cursor_index + page]
		else:
			_updatePage(-1)
			return itemList[cursor.cursor_index + page]
			
	else:
		return null

func _on_arrow_cancel():
	if cursor.on or (visible and itemList.empty()):
		exit()

func _updatePage(dir=0):
	page += dir
	for i in linesPerPage:
		var line = lines[i]
		if i + page >= itemList.size():
			line.hide()
		else:
			var itemName = itemList[i + page]
			if !itemName in globaldata.items:
				line.hide()
			else:
				var item = globaldata.items[itemName]
				line.show()
				line.get_node("ItemLabel").text = item.name.english
				if itemName in restrictions:
					line.get_node("ItemLabel").add_color_override("font_color", Color.darkgray)
				else:
					line.get_node("ItemLabel").add_color_override("font_color", Color.white)
				if priceType in item:
					line.get_node("PriceLabel").text = str(item[priceType])
				else:
					line.get_node("PriceLabel").text = ""
	if page > 0:
		$UpArrow.show()
	else:
		$UpArrow.hide()
	if page + linesPerPage < itemList.size():
		$DownArrow.show()
	else:
		$DownArrow.hide()
	if itemList.size() > linesPerPage:
		set_scroll()

func set_scroll():
	# we want the scroll to represent the amount of pages it takes to reach max
	# so, firs thing is if itemList > linesPerpage
	
	if itemList.size() <= linesPerPage:
		return
	# the max is itemList - linesPerPage + 1
	var maxStep = itemList.size() - linesPerPage + 1
	scrollbar.rect_size.y = scrollbg.rect_size.y/maxStep
	scrollbar.rect_position.y = (page * scrollbar.rect_size.y)
#	$Tween.interpolate_property(scrollbar, "rect_position:y",
#			rect_position.y, page * scrollbar.rect_size.y, 0.2,
#			Tween.TRANS_QUART,Tween.EASE_OUT)
#	$Tween.start()

func set_highlight(idx):
	for i in lines.size():
		var line = lines[i]
		for child in line.get_children():
			if i == idx:
				child.highlight(1)
			else:
				child.highlight(0)

func _on_cursor_failed_move(dir):
	if dir.y < 0 and dir.y + page < 0:
		return
	elif dir.y > 0 and dir.y + page + linesPerPage > itemList.size():
		return
	_updatePage(dir.y)
	var item = itemList[cursor.cursor_index + page]
	set_highlight(cursor.cursor_index)
	cursor.play_sfx("cursor1")
	emit_signal("moved", item)

func _on_cursor_move(dir):
	if !cursor.on:
		return
	var item = itemList[cursor.cursor_index + page]
	set_highlight(cursor.cursor_index)
	emit_signal("moved", item)

func _on_cursor_select(idx):
	if !cursor.on:
		return
	var item = itemList[idx + page]
	emit_signal("selected", item)
