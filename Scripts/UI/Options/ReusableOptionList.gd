extends PanelContainer

const Cursor = preload("res://Scripts/UI/cursor.gd")
const Scrollbar = preload("res://Scripts/UI/Reusables/Scrollbar.gd")

signal selected (cursor_index)
signal cancel

export var max_visible_items: int = 10
export var scrolling_threshold: int = 2

var _items_count: int
var _scroll_position: int = 0

var _items_list

export (bool) var hide_on_select = true
export (bool) var can_cancel = true
export (PoolStringArray) onready var content
export (NodePath) onready var _cursor = get_node(_cursor) as Cursor
export (NodePath) onready var scroll_view = get_node(scroll_view) as ScrollContainer
export (NodePath) onready var list = get_node(list) as VBoxContainer
export (NodePath) onready var scrollbar = get_node(scrollbar) as Scrollbar

func _ready():
	list.connect("resized", self, "_fit_content")
	scrollbar.connect("resized", self, "_update_scroll_bar")
	_cursor.cancel_on = can_cancel
	if content:
		open(content)

func open(items_list, cur_value = "", naming_func: FuncRef = null, enabled_func: FuncRef = null):
	self.show()

	_items_list = items_list

	_items_count = items_list.size()

	for i in list.get_child_count():
		var cur_label = list.get_child(i)
		cur_label.hide()
	
	scrollbar.hide()

	var cur_index = 0
	for i in list.get_child_count():
		var cur_label = list.get_child(i)
		if i < _items_count:

			cur_label.visible = true
			
			if naming_func:
				cur_label.text = naming_func.call_funcv([items_list[i]])
			else:
				cur_label.text = str(items_list[i])
			
			if enabled_func and not enabled_func.call_funcv([items_list[i]]):
				cur_label.add_color_override("font_color", Color.darkgray)
			else:
				cur_label.add_color_override("font_color", Color.white)

			if items_list[i] == cur_value:
				cur_index = i

	_cursor.cursor_index = cur_index
	yield(list, "draw")
	_scroll_smartly()
	_cursor.on = true
	_cursor.show()

func _on_arrow_moved(dir):
	_scroll_smartly()

func _scroll_smartly():
	if _cursor.cursor_index - scrolling_threshold < _scroll_position:
		_scroll_position = _cursor.cursor_index - scrolling_threshold
	elif _cursor.cursor_index + scrolling_threshold + 1 > _scroll_position + max_visible_items:
		_scroll_position = _cursor.cursor_index - max_visible_items + scrolling_threshold + 1

	_scroll_position = min(_scroll_position, _items_count - max_visible_items)
	_scroll_position = max(_scroll_position, 0)
	yield(_scroll_to(_scroll_position), "completed")

func _scroll_to(index):
	_scroll_position = index
	var top_item = list.get_child(_scroll_position) as Control
	scroll_view.scroll_vertical = top_item.rect_position.y
	yield(_update_scroll_bar(), "completed")
	_cursor.set_cursor_from_index(_cursor.cursor_index, false)

func _update_scroll_bar():
	yield(get_tree(), "idle_frame")
	scrollbar.nb_rows = _items_count
	scrollbar.nb_visible_rows = max_visible_items
	scrollbar.position = _scroll_position

func _fit_content():
	var max_height = list.get_child(0).get_size().y * max_visible_items + 4 * (max_visible_items - 1)
	rect_min_size.y = min(list.get_size().y, max_height)

func _on_arrow_selected(cursor_index):
	_cursor.on = false
	if hide_on_select:
		_cursor.hide()
		self.hide()
	emit_signal("selected", cursor_index, _items_list[cursor_index])

func _on_arrow_cancel():
	_cursor.on = false
	if hide_on_select:
		_cursor.hide()
		self.hide()
	emit_signal("cancel")

