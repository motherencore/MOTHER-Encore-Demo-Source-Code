extends CanvasLayer

signal back

var active := false

var move_vec := Vector2.ZERO

var limits_reached := [false, false, false, false] # left, top, bottom, right

var map_size := Vector2.ZERO
var map_offset := Vector2.ZERO

var player_offset := Vector2.ZERO

var marker_time := 0.0

var loaded_map := "404"
var player_pos := Vector2.ZERO
var update_player := true

func _ready():
	$MapImage/PlayerMarker.hide()
	$MapImage/MapMarkers.hide()

func _physics_process(delta):
	move_vec = Input.get_vector("ui_key_left", "ui_key_right", "ui_key_up", "ui_key_down").round()
	move_vec += Input.get_vector("ui_dpad_left", "ui_dpad_right", "ui_dpad_up", "ui_dpad_down").round()
	move_vec += Input.get_vector("ui_lstick_left", "ui_lstick_right", "ui_lstick_up", "ui_lstick_down").round()
	move_vec += Input.get_vector("ui_rstick_left", "ui_rstick_right", "ui_rstick_up", "ui_rstick_down").round()
	var threshold = InputMap.action_get_deadzone("ui_lstick_left")
	move_vec = -sign_vector(move_vec, threshold)
	#print(move_vec)
	# these are reversed because i'm moving the sprite itself, not a camera around it.
	
	if global.currentScene.get("mapScreen") != self and global.currentScene is AreaRoom:
		global.currentScene.mapScreen = self
	
	if active:
		for i in range(get_child_count()):
			get_child(i).set("visible", true)
		
		if $MapImage.position.x - map_size.x * 0.5 >= 0: limits_reached[0] = true
		else: limits_reached[0] = false
		
		if $MapImage.position.x + map_size.x * 0.5 <= 320: limits_reached[3] = true
		else: limits_reached[3] = false
		
		if $MapImage.position.y - map_size.y * 0.5 >= 0: limits_reached[1] = true
		else: limits_reached[1] = false
		
		if $MapImage.position.y + map_size.y * 0.5 <= 180: limits_reached[2] = true
		else: limits_reached[2] = false
		
		if move_vec != Vector2.ZERO:
			if (move_vec.x < 0 and not limits_reached[3]) or (move_vec.x > 0 and not limits_reached[0]):
				map_offset.x += move_vec.x * (int(Input.is_action_pressed("ui_toggle")) + 1)
			if (move_vec.y < 0 and not limits_reached[2]) or (move_vec.y > 0 and not limits_reached[1]):
				map_offset.y += move_vec.y * (int(Input.is_action_pressed("ui_toggle")) + 1)
		
		$MapArrows/arrowL.visible = not limits_reached[0]
		$MapArrows/arrowU.visible = not limits_reached[1]
		$MapArrows/arrowD.visible = not limits_reached[2]
		$MapArrows/arrowR.visible = not limits_reached[3]
		
		$MapImage.position = Vector2(160,90) + map_offset
		
		if global.persistPlayer != null and update_player == true: # calculating player pos
			player_pos = (map_size * -0.5) + player_offset + (global.persistPlayer.position / 16)
		else:
			player_pos = (map_size * -0.5) + player_offset
			#printt($MapImage/PlayerMarker.position, map_size, player_offset)
		
		$MapImage/PlayerMarker.position = player_pos
		
		if marker_time >= 0.5:
			if $MapImage/MapMarkers.position.y == 0: # marker flash logic
				$MapImage/MapMarkers.position.y = -1
			elif $MapImage/MapMarkers.position.y == -1:
				$MapImage/MapMarkers.position.y = 0
			marker_time = 0
		marker_time += delta
		
		if Input.is_action_just_pressed("ui_scope", true) and loaded_map != "404":
			$MapImage/MapMarkers.visible = !$MapImage/MapMarkers.visible 
			$MapImage/PlayerMarker.visible = !$MapImage/PlayerMarker.visible 
		
		if Input.is_action_just_pressed("ui_cancel"): #returning to pause menu if player presses cancel
			Input.action_release("ui_cancel")
			active = false
			uiManager.commandsMenuActive = true
			emit_signal("back")
	else:
		for i in range(get_child_count()):
			get_child(i).set("visible", false)
	

func load_map(areaName: String, dontUpdate := false):
	var dir := Directory.new()
	
	var map_tex_path : String = "res://Graphics/UI/Maps/" + areaName + "_map.png"
	var name_tex_path : String = "res://Graphics/UI/Maps/" + areaName + "_namePlate.png"
	
	var map_tex : Texture
	var name_tex : Texture
	var map_markers : Array
	
	if areaName != loaded_map:
		if globaldata.mapMarkers.has(areaName): 
			map_tex = load(map_tex_path)
			name_tex = load(name_tex_path)
			loaded_map = areaName
			$MapImage/PlayerMarker.show()
			$MapImage/MapMarkers.show()
			$MapImage/Label.hide()
			map_markers = globaldata.mapMarkers[areaName]
		else: 
			map_tex = load("res://Graphics/UI/Maps/404_map.png")
			name_tex = load("res://Graphics/UI/Maps/404_namePlate.png")
			loaded_map = "404"
			update_player = true
			$MapImage/PlayerMarker.hide()
			$MapImage/MapMarkers.hide()
			$MapImage/Label.show()
			$MapImage.position = Vector2.ZERO
			map_markers = []
			#print("no map found ( " + areaName + " )")
		
		if global.currentScene.get_script() != null:
			if global.currentScene.get("player_map_offset") != null:
				player_offset = global.currentScene.player_map_offset
		
		
		if areaName != "":
			focus_to_player()
		
		$MapImage.texture = map_tex
		$MapNamePlate.texture = name_tex

		for node in $MapImage/MapMarkers.get_children():
			$MapImage/MapMarkers.remove_child(node)
			node.queue_free()

		for marker_data in map_markers:
			match marker_data.type:
				"label":
					var marker = $MapImage/LabelMarkerSample.duplicate()
					marker.text = marker_data.value
					marker.rect_position = Vector2(marker_data.position.x, marker_data.position.y)
					marker.show()
					$MapImage/MapMarkers.add_child(marker)
				"icon":
					var marker = $MapImage/IconMarkerSample.duplicate()
					marker.texture = load("res://Graphics/UI/Maps/marker_%s.png" % marker_data.value)
					marker.offset = Vector2(marker_data.position.x, marker_data.position.y)
					marker.flip_h = "flip_h" in marker_data and marker_data.flip_h
					marker.flip_v = "flip_v" in marker_data and marker_data.flip_v
					marker.show()
					$MapImage/MapMarkers.add_child(marker)

		map_size = $MapImage.texture.get_size()
		
		focus_to_player()

	if dontUpdate == true:
		if global.currentScene.get_script() != null:
			if global.currentScene.get("player_map_offset") != null:
				player_offset = global.currentScene.player_map_offset
		update_player = false

func focus_to_player():
	if global.persistPlayer != null and update_player == true: # calculating player pos
		player_pos = (map_size * -0.5) + player_offset + (global.persistPlayer.position / 16)
	else:
		player_pos = (map_size * -0.5) + player_offset
	
	#print(map_size * -0.5)
	map_offset.x = -clamp(player_pos.x, (-map_size.x / 2) + 160, map_size.x / 2 - 160)
	map_offset.y = -clamp(player_pos.y, (-map_size.y / 2) + 90, map_size.y / 2 - 90)
	
	$MapImage.position = Vector2(160,90) + map_offset
	
	if $MapImage.position.x - map_size.x * 0.5 >= 0: limits_reached[0] = true
	else: limits_reached[0] = false
	
	if $MapImage.position.x + map_size.x * 0.5 <= 320: limits_reached[3] = true
	else: limits_reached[3] = false
	
	if $MapImage.position.y - map_size.y * 0.5 >= 0: limits_reached[1] = true
	else: limits_reached[1] = false
	
	if $MapImage.position.y + map_size.y * 0.5 <= 180: limits_reached[2] = true
	else: limits_reached[2] = false
	
	$MapArrows/arrowL.visible = not limits_reached[0]
	$MapArrows/arrowU.visible = not limits_reached[1]
	$MapArrows/arrowD.visible = not limits_reached[2]
	$MapArrows/arrowR.visible = not limits_reached[3]

func sign_vector(vector2, threshold = 0):
	if abs(vector2.x) > threshold:
		vector2.x = sign(vector2.x)
	if abs(vector2.y) > threshold:
		vector2.y = sign(vector2.y)
	return vector2

func slide_name():
	if loaded_map != "404":
		focus_to_player()
	active = true
	$MapNamePlate.position = Vector2.ZERO
	var tween = $Tween
	tween.stop_all()
	tween.interpolate_property($MapNamePlate, "position", Vector2.ZERO, Vector2(0, -180), 1.0, Tween.TRANS_CIRC, Tween.EASE_IN_OUT, 1.5)
	tween.start()
	

func _on_MapScreen_tree_exiting():
	if global.currentScene.get("mapScreen") == self:
		global.currentScene.mapScreen = null
