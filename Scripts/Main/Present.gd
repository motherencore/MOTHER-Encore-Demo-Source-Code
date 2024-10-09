tool

extends Sprite

export (String) var flag = ""
export (String) var item = ""
export (String) var dialog = ""
export (String, "item", "map", "briefcase") var type setget set_type

var opened = false
var player_turn = { 
	"y": true,
	"x": true
}

func set_type(sprite):
	type = sprite
	if is_inside_tree():
		match type:
			"item":
				get_node("Sprite").texture = load("res://Graphics/Objects/Present Box.png")
			"map":
				get_node("Sprite").texture = load("res://Graphics/Objects/Present Box Blue.png")
			"briefcase":
				get_node("Sprite").texture = load("res://Graphics/Objects/Briefcase.png")

func _ready():
	set_type(type)
	if !Engine.is_editor_hint():
		if flag != null or flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag] == true:
					opened = true
					$Sparkles.stop()
					$Sparkles.hide()
					$Sprite.frame = 4
		if dialog == "":
			dialog = "ItemDescriptions/presentcheck"

func interact():
	if !opened:
		if globaldata.flags.has(flag):
			if globaldata.flags[flag] == false:
				open()
		else:
			open()
	else:
		global.set_dialog("ItemDescriptions/presentempty", null) 
	uiManager.open_dialogue_box()

func open():
	# LOCALIZATION Code change: Removed use of globaldata.language (storing the csv key id) × 2
	global.item = InventoryManager.Load_item_data(item)
	$AnimationPlayer.play("Unwrapped")
	if (InventoryManager.hasInventorySpace() or InventoryManager.Load_item_data(item)["keyitem"]) and !opened:
		InventoryManager.giveItemAvailable(item)
		global.set_dialog(dialog , null) 
		if flag != "" and globaldata.flags.has(flag):
			globaldata.flags[flag] = true
		opened = true
		$Sparkles.stop()
		$Sparkles.hide()
	else:
		global.set_dialog("ItemDescriptions/presentfull", null)
		yield($AnimationPlayer,"animation_finished")
		$AnimationPlayer.play("Wrapped")
