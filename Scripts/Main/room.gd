extends Node2D

class_name AreaRoom

export var player_map_offset := Vector2.ZERO
# Find position 0,0 in the scene, and then find where that is in the map image.

export var map_name_override := ""
# Leave blank to rely on name of scene's root node. Names are case-sensitive.
# Set name override to "404" for the "Map not found" set."sprite"

export var map_item := ""
#The key item you need for the map to be visible

export var is_sub_area := false
# Tells the map whether or not to keep updating the player's position.

var mapScreen : CanvasLayer 



func _physics_process(delta): # doing _physics_process instead of _process in case people wanna put timing-sensitive logic in here.
	if mapScreen != null:
		if check_map_item():
			if map_name_override == "" and mapScreen.loaded_map != self.name:
				mapScreen.load_map(self.name, is_sub_area)
			elif map_name_override != "" and mapScreen.loaded_map != map_name_override:
				mapScreen.load_map(map_name_override, is_sub_area)

func check_map_item():
	if map_item != "":
		if !InventoryManager.checkItemForAll(map_item):
			return false
	return true
