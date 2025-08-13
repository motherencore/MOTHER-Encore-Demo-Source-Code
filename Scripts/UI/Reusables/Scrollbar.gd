extends Control

class_name EncoreScrollBar

export var on = true setget _set_on, _get_on
export var nb_visible_rows: int setget _set_nb_visible_items
export var nb_rows: int setget _set_nb_items
export var position: int setget _set_position

func _ready():
	self.hide()

func _set_on(val):
	on = val
	_refresh()

func _get_on():
	return on

func _set_nb_items(val):
	nb_rows = val
	_refresh()

func _set_nb_visible_items(val):
	nb_visible_rows = val
	_refresh()

func _set_position(val):
	position = val
	_refresh()

func update_from_scroll_view(scroll_view):
	nb_rows = scroll_view.get_child(0).rect_size.y
	nb_visible_rows = scroll_view.rect_size.y
	position = scroll_view.scroll_vertical
	_refresh()

func _refresh():
	if nb_rows == null or nb_rows <= nb_visible_rows:
		self.hide()
	else:
		self.show()
		$ScrollBG/Thumb.rect_size.y = $ScrollBG.rect_size.y * nb_visible_rows / nb_rows
		$ScrollBG/Thumb.rect_position.y = $ScrollBG.rect_size.y * position / nb_rows
		if position == 0:
			$UpArrow.hide()
			$DownArrow.show()
		elif position + nb_visible_rows < nb_rows:
			$UpArrow.show()
			$DownArrow.show()
		else:
			$UpArrow.show()
			$DownArrow.hide()

	if on:
		$UpArrow/arrow.on = true
		$DownArrow/arrow.on = true
	else:
		$UpArrow/arrow.on = false
		$UpArrow/arrow.frame = 0
		$DownArrow/arrow.on = false
		$DownArrow/arrow.frame = 0
