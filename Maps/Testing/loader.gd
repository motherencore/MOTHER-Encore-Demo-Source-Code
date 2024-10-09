extends Node

export (String, FILE) var room
export (bool) var preview := false setget set_preview

var zone_id
var zone_trigger
var _preview_node: Node = null
var loadedRoom = null

var map = null

func _ready():
	set_process(false)
		#loadedRoom = roomLoad.instance()

func _on_loader_area_entered(area):
		
	if Engine.editor_hint:
		return
		
	#discard initial contact with other areas
	if area == global.persistPlayer.get_node("Camera2D").get_node("Area2D"):
		goto_scene(room)

func _on_loader_area_exited(area):
	
	if Engine.editor_hint:
		return
		
	#discard initial contact with other areas
	if area == global.persistPlayer.get_node("Camera2D").get_node("Area2D"):
		if map != null:
			map.queue_free()
			map = null


func set_preview(value: bool):
	
	if not Engine.editor_hint or preview == value:
		return
		
	preview = value

	# remove existing node, if any
	if _preview_node:
		_preview_node.queue_free()
		_preview_node = null

	# try to load the path
	if preview && room:
		
		var scene: PackedScene = load(room)
		
		# if we loaded something, add it
		if not scene:
			return
			
		_preview_node = scene.instance()
		
		add_child(_preview_node)
		
		# this node will not be saved in the editor
		_preview_node.owner = null

func goto_scene(path): # Game requests to switch to this scene.
	loadedRoom = ResourceLoader.load_interactive(room)
	if loadedRoom == null: # Check for errors
		return
	set_process(true)

	

func _process(time):
	if loadedRoom == null:
		set_process(false)
		return
	
	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + 100:
	# Poll your loader.
		var err = loadedRoom.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loadedRoom.get_resource()
			loadedRoom = null
			add_map(resource)
			break
		elif err == OK:
			pass
		else: # Error during loading.
			loadedRoom = null
			break

func add_map(rm):
	map = rm.instance()
	add_child(map)
