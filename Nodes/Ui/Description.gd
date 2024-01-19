extends Control


const item_icons_path = "res://Graphics/Objects/Items/"

onready var DescText = $ColorRect/HBoxContainer/CenterContainer2/Desc
onready var DescSprite = $ColorRect/HBoxContainer/CenterContainer/TextureRect/Item


func Set_item(item):
	var path := str(item_icons_path + "/" + item + ".png")
	var directory = Directory.new()
	var doesFileExist = directory.file_exists(path)
		
	if item == "":
		DescText.text = ""
		DescSprite.texture = null
		$ColorRect/HBoxContainer/CenterContainer/TextureRect.hide()
	else:
		DescText.text = globaldata.replaceText((InventoryManager.Load_item_data(item))["description"][globaldata.language])
		$ColorRect/HBoxContainer/CenterContainer/TextureRect.show()
		DescSprite.texture = load(item_icons_path + "/" + item + ".png")
