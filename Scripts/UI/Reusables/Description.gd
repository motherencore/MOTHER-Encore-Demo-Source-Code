extends Control

const item_icons_path = "res://Graphics/Objects/Items/"

export (NodePath) onready var DescText = get_node(DescText) as RichTextLabel
export (NodePath) onready var DescSpriteRect = get_node(DescSpriteRect) as TextureRect
export (NodePath) onready var DescSprite = get_node(DescSprite) as Sprite

func setTextWithItem(text, itemId):
	DescText.bbcode_text = text

	if !itemId:
		DescSpriteRect.hide()
		DescSprite.texture = null
	else:
		DescSpriteRect.show()
		DescSprite.texture = load("%s%s.png" % [item_icons_path, itemId])


func setItem(itemId):
	var text
	if itemId in globaldata.items:
		var item = globaldata.items[itemId]
		text = globaldata.replaceText(item.description)
	else:
		text = ""
	
	setTextWithItem(text, itemId)


func setText(text):
	setTextWithItem(text, "")
