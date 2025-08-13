extends Control

const ITEM_ICONS_PATHS = "res://Graphics/Objects/Items/%s.png"

export (NodePath) onready var _text_label = get_node(_text_label) as RichTextLabel
export (NodePath) onready var _sprite_container = get_node(_sprite_container) as NinePatchRect
export (NodePath) onready var _sprite = get_node(_sprite) as Sprite

var _text: String = ""
var _icon_path: String = ""

func _ready():
	_text_label.connect("resized", self, "_on_resized")

func _on_resized():
	_update()

func _set_text_with_item(text: String, icon_file: String):
	_text = text
	_icon_path = ITEM_ICONS_PATHS % icon_file if icon_file else ""
	_update()

func set_item(item_id: String, remaining_doses: int = 0):
	var text: String
	if item_id in globaldata.items:
		var item = globaldata.items[item_id]
		global.item = item
		text = TextTools.replace_text(item.description)
		text += TextTools.get_item_doses_phrase(item, remaining_doses)
	else:
		text = ""
	
	_set_text_with_item(text, item_id)

func set_item_from_inv(inv_item: InventoryManager.Item):
	if inv_item != null:
		set_item(inv_item.ItemName, inv_item.doses)
	else:
		set_item("")

func set_text(text):
	_set_text_with_item(text, "")

func _update():
	_text_label.bbcode_text = TextTools.add_line_breaks(_text, _text_label)

	if !_icon_path:
		_sprite_container.hide()
		_sprite.texture = null
	else:
		_sprite_container.show()
		if ResourceLoader.exists(_icon_path):
			_sprite.texture = load(_icon_path)
		else:
			_sprite.texture = null
