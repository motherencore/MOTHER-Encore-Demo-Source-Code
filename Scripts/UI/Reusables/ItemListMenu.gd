class_name ItemListMenu
extends NinePatchRect

onready var cursor = get_node_or_null("arrow")
onready var lines = $MarginContainer/VBoxContainer.get_children()
onready var scrollbar = $Scrollbar

export (bool) var _is_resale_price := false
export var loop_around := false

const LINES_PER_PAGE = 6

var page := 0

var item_list := [] setget _set_item_list	# list of InventoryManager.Item
var restriction_func: FuncRef

signal selected(itemIdx)
signal failed_select(itemIdx)
signal moved(itemIdx)
signal exited()
signal entered()

func _ready():
	if cursor:
		cursor.connect("moved", self, "_on_cursor_move")
		cursor.connect("failed_move", self, "_on_cursor_failed_move")
		cursor.connect("selected", self, "_on_cursor_select")
		cursor.connect("failed_select", self, "_on_cursor_failed_select")
	scrollbar.nb_visible_rows = LINES_PER_PAGE

func _physics_process(delta):
	if cursor.on and Input.is_action_pressed("ui_toggle"):
		var direction = controlsManager.get_controls_vector(true)
		var page_delta = direction.y * LINES_PER_PAGE
		if page_delta != 0:
			_on_cursor_move_by_page(page_delta)

func enter(reset=true, idx = -1):
	if idx != -1:
		cursor.set_cursor_from_index(idx, false)
	cursor.on = true
	cursor.visible = true
	scrollbar.on = true
	_update_content(reset)
	if !item_list.empty():
		cursor.set_cursor_from_index(cursor.cursor_index, false)
	emit_signal("entered")

func _update_content(reset=false):
	if reset:
		page = 0
		cursor.set_cursor_from_index(0, false)

	# check if the page is too far and there's no other items
	if page + LINES_PER_PAGE > item_list.size():
		page = int(max(0, item_list.size() - LINES_PER_PAGE))
	_update_page()

	if cursor.cursor_index + page > item_list.size() - 1:
		cursor.set_cursor_from_index(item_list.size() - page - 1, false)

	if cursor.on:
		set_highlight(cursor.cursor_index)

	scrollbar.nb_rows = item_list.size()
	scrollbar.on = true

func _set_item_list(list):
	item_list = list
	_update_content(false)

func exit():
	cursor.on = false
	cursor.visible = false
	scrollbar.on = false
	set_highlight(-1)
	emit_signal("exited")


func scroll_to(pos):
	page = int(clamp(page, pos - LINES_PER_PAGE + 1, pos))
	cursor.set_cursor_from_index(pos - page)
	if cursor.on:
		set_highlight(cursor.cursor_index)
	_update_page()

func get_current_item() -> InventoryManager.Item:
	if !item_list.empty():
		return item_list[cursor.cursor_index + page]
	else:
		return null

func get_current_item_id() -> String:
	if !item_list.empty():
		return item_list[cursor.cursor_index + page].ItemName
	else:
		return ""

func _on_arrow_cancel():
	if cursor.on or (visible and item_list.empty()):
		exit()

func _update_page(dir = 0):
	page += dir
	for i in LINES_PER_PAGE:
		var line = lines[i]
		if i + page >= item_list.size():
			line.hide()
		else:
			var item_instance: InventoryManager.Item = item_list[i + page]
			var item_id = item_instance.ItemName
			if !item_id in globaldata.items:
				line.hide()
			else:
				var item = globaldata.items[item_id]
				line.show()
				line.get_node("ItemLabel").text = item["name"]
				if restriction_func != null and restriction_func.call_funcv([item_instance]) == false:
					line.get_node("ItemLabel").add_color_override("font_color", Color.darkgray)
				else:
					line.get_node("ItemLabel").add_color_override("font_color", Color.white)
				if line.has_node("PriceLabel"):
					if _is_resale_price:
						line.get_node("PriceLabel").text = str(item.value * item_instance.doses)
					else:
						line.get_node("PriceLabel").text = str(item.cost)
				line.get_node("ItemLabel").show_equiped(item_instance.equiped)
	scrollbar.position = page

func set_highlight(idx):
	for i in lines.size():
		var line = lines[i]
		for child in line.get_children():
			if i == idx:
				child.highlight(1)
			else:
				child.highlight(0)

func _on_cursor_failed_move(dir: Vector2):
	if dir.y == 0:
		return

	if dir.y < 0 and dir.y + page < 0:
		if loop_around:
			dir.y = 0
			page = int(max(0, item_list.size() - LINES_PER_PAGE))
			cursor.set_cursor_from_index(min(LINES_PER_PAGE - 1, item_list.size() - 1))
		else:
			return
	elif dir.y > 0 and dir.y + page + LINES_PER_PAGE > item_list.size():
		if loop_around:
			dir.y = 0
			page = 0
			cursor.set_cursor_from_index(0)
		else:
			return
	_update_page(dir.y)

	if not item_list.empty():
		set_highlight(cursor.cursor_index)
		cursor.play_sfx("cursor1")
		emit_signal("moved", cursor.cursor_index + page)

func _on_cursor_move(dir: Vector2):
	if !cursor.on:
		return
	set_highlight(cursor.cursor_index)
	emit_signal("moved", cursor.cursor_index + page)

func _on_cursor_move_by_page(delta: int):
	var new_page := page + delta
	new_page = int(clamp(new_page, 0, item_list.size() - LINES_PER_PAGE))
	if new_page != page and item_list.size() > LINES_PER_PAGE:
		page = new_page
		_update_page()
		cursor.play_sfx("cursor1")
		emit_signal("moved", cursor.cursor_index + page)

func _on_cursor_select(idx):
	if !cursor.on:
		return
	if restriction_func == null or restriction_func.call_funcv([item_list[idx + page]]) == true:
		cursor.play_sfx('cursor2')
	else:
		cursor.play_sfx('restricted')
	emit_signal("selected", idx + page)

func _on_cursor_failed_select(idx):
	if !cursor.on:
		return
	emit_signal("failed_select", idx + page)
