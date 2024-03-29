extends Node

#signalling parent the world has finished loading (hide loading screen)
signal world_loaded

onready var zone_loader = $ZoneLoader

export var player_scene:PackedScene

#you can change the starting zone here
export(String) var starting_zone

#player spawn locations are in this group
const GROUP_PLAYER_SPAWN = "PLAYER_SPAWN"

var player


func _input(event):
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		
		if event.scancode == KEY_ESCAPE:

			#ask the loading process to stop and wait for it to finish (proper way to quit)
			BackgroundLoader.request_stop()
			yield(BackgroundLoader, "loading_process_stopped")

			# warning-ignore:return_value_discarded
			get_tree().change_scene("res://demo/menu.tscn")


func _ready():
	
	#this will fire the first time a zone is attached to the world (initial loading)
	zone_loader.connect("zone_attached", self, "_on_first_zone_attached", [], CONNECT_ONESHOT)
	
	zone_loader.connect("zone_loaded", self, "_on_zone_loaded")
	zone_loader.connect("zone_about_to_unload", self, "_on_zone_about_to_unload")
	
	#simulate player entering first zone area (as player is not in the world yet)
	zone_loader.enter_zone(starting_zone)

	get_tree().paused = true


#called when the initial first area has finished loading and is attached to the tree
# warning-ignore:unused_argument
func _on_first_zone_attached(zone_id):
	
	#get player spawn on the map
	
	
	#spawn player
	
	
	get_tree().paused = false
	
	#wait one frame
	yield(get_tree(), "idle_frame")
	
	emit_signal("world_loaded")

#load zone data here
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_zone_loaded(zone_id, zone_node):

	pass
#	print("zone loaded ", zone_id)

#save zone data here
# warning-ignore:unused_argument
# warning-ignore:unused_argument
func _on_zone_about_to_unload(zone_id, zone_node):

	pass
#	print("zone unloaded ", zone_id)
