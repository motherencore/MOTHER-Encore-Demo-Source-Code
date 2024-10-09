tool

extends Sprite

export (String) var flag = ""
export (String) var item = "" setget set_sprite
export (String) var dialog = ""

export (float) var bounce_height = 8

var player_turn = { 
	"y": true,
	"x": true
}

func set_sprite(Item):
	item = Item
	if is_inside_tree():
		var path := str("res://Graphics/Objects/Items/" + Item + ".png")
		var directory = Directory.new()
		var doesFileExist = directory.file_exists(path)
		if doesFileExist or !Engine.is_editor_hint():
			$Sprite.texture = load(path)
		else:
			$Sprite.texture = load("res://Graphics/Objects/Items/Error.png")

func _ready():
	hide()
	if is_inside_tree():
		set_sprite(item)
	if !Engine.is_editor_hint():
		if flag != null or flag != "":
			if globaldata.flags.has(flag):
				if globaldata.flags[flag] == true:
					queue_free()
		if dialog == "":
			dialog = "ItemDescriptions/itemcheck"
		
		global.persistPlayer.connect("paused", self, "_on_player_paused")
		global.persistPlayer.connect("unpaused", self, "_on_player_unpaused")
	yield(get_tree(), "idle_frame")
	show()
	

func interact():
	if globaldata.flags.has(flag):
		if globaldata.flags[flag] == false:
			check()
	else:
		check()
	
	uiManager.open_dialogue_box()

func unparent_buttonPrompt():
	var buttonPrompt = get_node("interact/ButtonPrompt")
	buttonPrompt.show_button()
	if buttonPrompt.visible:
		buttonPrompt.press_button()
		buttonPrompt.connect("hide", buttonPrompt, "queue_free")
		$interact.remove_child(buttonPrompt)
		get_parent().add_child(buttonPrompt)
		buttonPrompt.position = position + buttonPrompt.offset
	else:
		buttonPrompt.queue_free()
	

func check():
	if InventoryManager.hasInventorySpace() or InventoryManager.Load_item_data(item)["keyitem"]:
		unparent_buttonPrompt()
		InventoryManager.giveItemAvailable(item)
		# LOCALIZATION Code change: Storing item data instead of just name and article
		global.item = InventoryManager.Load_item_data(item)
		global.set_dialog(dialog, null) 
		if (flag != null or flag != "") and globaldata.flags.has(flag):
			globaldata.flags[flag] = true
		collect()
	else:
		global.set_dialog("ItemDescriptions/itemfull", null) 
		$Tween.interpolate_property($Sprite, "rotation_degrees",
		30, 0, 1, 
		Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	$Tween.start()

func collect():
	$Tween.interpolate_property(self, "global_position",
		global_position, global.persistPlayer.global_position, 0.3, 
		Tween.TRANS_QUART,Tween.EASE_OUT,0.045)
	$Tween.interpolate_property(self, "scale",
		Vector2(0.7,1.3), Vector2(0.5,0), 0.20, 
		Tween.TRANS_QUAD,Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	queue_free()

func disappear():
	$Timer.start(5)
	if global.persistPlayer.paused:
		_on_player_paused()
	yield($Timer,"timeout")
	$AnimationPlayer.play("blink")
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 2
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 3
	$Timer.start(3)
	yield($Timer,"timeout")
	queue_free()

func _on_player_paused():
	$Timer.paused = true

func _on_player_unpaused():
	$Timer.paused = false

