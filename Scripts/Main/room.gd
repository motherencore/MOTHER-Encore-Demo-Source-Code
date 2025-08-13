class_name AreaRoom
extends Node2D

signal area_left
signal synced_switches_changed (emitter, state, silent)

export var player_map_offset := Vector2.ZERO
# Find position 0,0 in the scene, and then find where that is in the map image.

export var region_name := ""
# Leave blank to rely on name of scene's root node. Names are case-sensitive.
# Set name override to "404" for the "Map not found" set."sprite"

export var map_item := ""
#The key item you need for the map to be visible

export var is_sub_area := false
# Tells the map whether or not to keep updating the player's position.

var mapScreen : CanvasLayer
var _switches_state := false

func _init():
	connect("synced_switches_changed", self, "_on_switches_changed_state")

func _ready():
	_update_flying_man_status()

func _update_flying_man_status():
	var is_magicant = (region_name == "Magicant")
	if !is_magicant or globaldata.flags["flying_man_in_party"]:
		if is_magicant != (globaldata.flyingman in global.partyNpcs):
			if is_magicant:
				global.partyNpcs.append(globaldata.flyingman)
			else:
				global.partyNpcs.erase(globaldata.flyingman)

func _physics_process(delta): # doing _physics_process instead of _process in case people wanna put timing-sensitive logic in here.
	if mapScreen != null:
		if _check_map_item():
			var map_to_load = self.name if region_name == "" else region_name
			if mapScreen.loaded_map != map_to_load:
				mapScreen.load_map(map_to_load, is_sub_area)

func _check_map_item():
	return map_item == "" or InventoryManager.check_item_for_all(map_item)

func leave_for(new_scene):
	emit_signal("area_left", new_scene.region_name != self.region_name)

func _on_switches_changed_state(emitter: TwoStatesSwitch, value: bool, silent: bool):
	_switches_state = value

func get_switches_state():
	return _switches_state
