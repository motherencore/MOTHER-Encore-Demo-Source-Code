extends Node2D

signal cutscene_ended
signal locale_changed
signal inputs_changed
signal settings_changed
signal party_changed

onready var tween = $Tween
var party = []
var partyNpcs = []
var partySize: int = 255
var partySpace = []
var persistArray = []
var partyObjects = []
var currentScene = null
var previousScene = null
var persistPlayer = null
var currentCamera: GameCamera = null
var debugMenu = load("res://Nodes/Ui/debug/debug.tscn")
var maxInventorySlots = 10
var dialogue = []
var receiver = null
var item = null
enum {KEYBOARD, GAMEPAD}
var device = KEYBOARD
var cutscene = false
var talker = null
var inBattle = false
var queuedBattle = false
var gameover = false
var phoneLocation
var mousePosition
var mouseShownTime: float = 0.0
var mouseHiddenTime: float = 0.0
var mouseIdleTime: float = 0.0

var LANGUAGES_DEBUG = ["en", "fr", "it", "ja", "ko", "es", "es_ES", "pt_BR", "pl", "de", "ru", "uk"]
var LANGUAGES_RELEASE = ["en", "fr", "it", "ja", "ko", "es", "es_ES", "pt_BR", "pl", "de", "ru", "uk"]
var LANGUAGE_DEFAULT = "en"

onready var playerNode = load("res://Nodes/Reusables/Player.tscn")

const POSSIBLE_PARTY_MEMBERS = ["ninten", "ana", "lloyd", "teddy", "pippi", "canarychick", "flyingman", "eve"]
const POSSIBLE_PLAYABLE_MEMBERS = ["ninten", "ana", "lloyd", "teddy", "pippi"]

func _ready():
	set_localized_default_inputs()
	load_settings()
	partySpace.resize(partySize)
	var root = get_tree().get_root()
	
	currentScene = root.get_child(root.get_child_count() - 1)
	if persistPlayer == null:
		party.append(globaldata.ninten)
		var player = playerNode.instance()
		player.name = "player"
		if currentScene.has_node("YSort"):
			currentScene.get_node("YSort").add_child(player)
		elif currentScene.has_node("Objects"):
			var objects = currentScene.get_node("Objects")
			if objects != null:
				objects.add_child(player)
		else:
			currentScene.add_child(player)
			player.hide()
			player.pause()
		persistPlayer = player
		player.position.x = 0
		player.position.y = 0
		create_party_followers()
		set_respawn()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	mousePosition = Input.get_last_mouse_speed()

func _physics_process(delta):
	#print(party)
	if uiManager.uiStack.size() == 0:
		if Input.is_action_just_pressed("ui_select") and !persistPlayer.paused and persistPlayer.state == persistPlayer.MOVE:
			uiManager.open_commands_menu()
		
	if mousePosition != Input.get_last_mouse_speed():
		mouseShownTime = 0
		mouseIdleTime = 0
		if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
			mouseHiddenTime += delta
			if mouseHiddenTime >= delta*5:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mouseHiddenTime = 0
	else:
		mouseIdleTime += delta
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		mouseShownTime += delta
		
	mousePosition = Input.get_last_mouse_speed()
	
	if mouseIdleTime >= 0.5:
		mouseHiddenTime = 0

	if mouseShownTime >= 1.5:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		mouseShownTime = 0
	
	if OS.is_debug_build():
		if Input.is_action_just_pressed("ui_g"):
			Engine.time_scale = 2.0
		elif Input.is_action_just_released("ui_g"):
			Engine.time_scale = 1.0
		
		if Input.is_action_just_pressed("ui_w"):
			global.persistPlayer.visible = !global.persistPlayer.visible
		
		if Input.is_action_just_pressed("ui_F2") and !persistPlayer.paused and persistPlayer.state == persistPlayer.MOVE and !global.inBattle:
			uiManager.start_battle(0, true, ["TEST", "TEST"])
		
		if Input.is_action_just_pressed("ui_F6"):
			global.persistPlayer.pause()
			uiManager.open_storage()

		if Input.is_action_just_pressed("ui_F7"):
			global.persistPlayer.pause()
			uiManager.open_storage(true)

		if Input.is_action_just_pressed("ui_load", true):
			audioManager.fadeout_all_music(0.5)
			load_game(globaldata.saveFile)

		if Input.is_action_just_pressed("ui_load_select"):
			global.persistPlayer.pause()
			uiManager.open_save(SaveSelect.Type.LOAD)
		
		# LOCALIZATION Code added: Debug feature to quickly translate the UI
		if Input.is_action_just_pressed("ui_translate"):
			if Input.is_action_just_pressed("ui_translate", true):
				toggle_language(LANGUAGES_DEBUG)
			else:
				toggle_language(LANGUAGES_DEBUG, -1)
			save_settings()
			
		for i in LANGUAGES_DEBUG.size():
			var input = "ui_lang%s" % i
			if input in InputMap.get_actions() and Input.is_action_just_pressed(input):
				set_language(LANGUAGES_DEBUG[i])
				save_settings()
		
		if !persistPlayer.paused:
			if Input.is_action_just_pressed("ui_q"):
				party_call("set_all_collisions", false)
			if Input.is_action_just_released("ui_q"):
				party_call("set_all_collisions", true)
			
			if Input.is_action_pressed("ui_e"):
				persistPlayer.speed = 600
			elif !persistPlayer.running:
				persistPlayer.speed = persistPlayer.SPEED_WALKING
				
		if Input.is_action_just_pressed("ui_F12"):
			goto_scene("res://Maps/Testing/Debug world.tscn")
			persistPlayer.position = Vector2.ZERO
			persistPlayer.unpause()
		
		if Input.is_action_just_pressed("ui_backtick"):
			if uiManager.uiStack.size() == 0:
				var dm = debugMenu.instance()
				uiManager.add_ui(dm)
		
		for i in POSSIBLE_PARTY_MEMBERS.size():
			if Input.is_action_just_pressed("ui_%s" % (i+1), true):
				var party_member = globaldata.get(POSSIBLE_PARTY_MEMBERS[i])
				if party_member in party:
					if StatusManager.is_unconscious(party_member):
						if party.size() > 1:
							party.erase(party_member)
							if party_member != globaldata.ninten:
								party_member.status.clear()
						else:
							party_member.status.clear()
					else: 
						StatusManager.add_status(party_member, StatusManager.AILMENT_UNCONSCIOUS)
				elif party_member in partyNpcs:
					partyNpcs.erase(party_member)
					party_member.status.clear()
				else:
					if party_member.name in POSSIBLE_PLAYABLE_MEMBERS:
						party.append(party_member) 
					else:
						party_member.status.clear()
						partyNpcs.append(party_member)
					if party_member == globaldata.ninten:
						party_member.status.clear()
				create_party_followers()
				global.emit_signal("party_changed")
				persistPlayer.spritesheet()
			
		if Input.is_action_just_pressed("ui_mute"):
			audioManager.stop_all_music()
	

func start_slowmo(speed, length):
	$Slowmo.start_slowmo(speed, length)

func add_persistent(node_to_persist):
	persistArray.append(node_to_persist)

func remove_persistent(node_to_remove):
	persistArray.erase(node_to_remove)

func goto_scene(path, playerPosition = Vector2.ZERO, playerDirection = Vector2(0,1)):
	call_deferred("_deferred_goto_scene", path, playerPosition, playerDirection)

func _deferred_goto_scene(path, playerPosition, playerDirection):
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").remove_child(persistPlayer)
	else:
		currentScene.get_node("Objects").remove_child(persistPlayer)
	
	# This could be moved somewhere else for better code organization
	# var ao_oni
	# ao_oni = currentScene.get_node("Objects").get_node_or_null("AoOni")
	# if ao_oni != null:
	# 	ao_oni = ao_oni.duplicate()
	
	persistPlayer.set_all_collisions(false)
	
	for node in persistArray:
		if node != null:
			node.get_parent().remove_child(node)
	
	var new_scene = ResourceLoader.load(path).instance()

	if currentScene is AreaRoom and new_scene is AreaRoom:
		currentScene.leave_for(new_scene)
	
	currentScene.free()

	currentScene = new_scene
	
	get_tree().get_root().add_child(currentScene)
	
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").add_child(persistPlayer)
	else:
		currentScene.get_node("Objects").add_child(persistPlayer)
	
	create_party_followers()
	set_party_position(playerPosition, playerDirection)
	
	# if ao_oni != null:
	# 	currentScene.get_node("Objects").add_child(ao_oni)
	
	for node in persistArray:
		currentScene.add_child(node)
	
	get_tree().set_current_scene(currentScene)
	uiManager.update_key_indicator()
	yield(get_tree(), "idle_frame")
	
	persistPlayer.set_all_collisions(true)

func add_map(scene):
	call_deferred("_deferred_goto_zone", scene)

func _deferred_goto_zone(scene):
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").remove_child(persistPlayer)
	else:
		currentScene.get_node("Objects").remove_child(persistPlayer)
	
	for node in persistArray:
		if node != null:
			node.get_parent().remove_child(node)
	currentScene.free()
	currentScene = scene.instance()
	
	get_tree().get_root().add_child(currentScene)
	
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").add_child(persistPlayer)
	else:
		currentScene.get_node("Objects").add_child(persistPlayer)
	
	create_party_followers()
	
	for node in persistArray:
		currentScene.add_child(node)
	
	get_tree().set_current_scene(currentScene)
	
	if currentScene.get_name() != "Snowman" and currentScene.get_name() != "Snowman Interiors":
		persistPlayer.costume = "Normal"
		persistPlayer.spritesheet()
	else:
		persistPlayer.costume = "Snow"
		persistPlayer.spritesheet()

func set_party_position(position, direction):
	persistPlayer.position = position
	if partySize > 1:
		for i in global.partySpace.size():
			partySpace.push_front(position)
			partySpace.pop_back()
	for i in partyObjects:
		if i.get("direction") != null:
			i.direction = direction
		elif i.get("inputVector") != null:
			i.inputVector = direction

func reset_party_positions():
	if partySize > 1:
		for i in partySpace.size():
			partySpace.push_front(persistPlayer.position)
			partySpace.pop_back()



func set_party_spacing(spacing):
	for i in range(partyObjects.size()):
		if partyObjects[i] != persistPlayer and is_instance_valid(partyObjects[i]):
			partyObjects[i].set_spacing(spacing)

func create_party_followers():
	var active = party + partyNpcs
	if partyObjects.size() > 1:
		for i in range(partyObjects.size()):
			if partyObjects[i] != persistPlayer and is_instance_valid(partyObjects[i]):
				partyObjects[i].queue_free()
	partyObjects.clear()
	partyObjects.append(persistPlayer)
	for i in range(active.size() - 1):
		var follower = load("res://Nodes/Reusables/PartyFollower.tscn")
		var follow = follower.instance()
		follow.spacing = i * 18 + 18
		follow.delay = i * 0.2 + 0.2
		follow.position = partySpace[follow.spacing]
		partyObjects.append(follow)
		persistPlayer.get_parent().add_child(follow)
	set_follower_index() # ensures follower objects know what place they're supposed to be in

func set_follower_index():
	if partyObjects.size() > 1:
		for i in range(1, partyObjects.size()):
			partyObjects[i].followerIdx = i
			partyObjects[i].initiate()

func party_call(function, value = null):
	for i in partyObjects:
		if is_instance_valid(i):
			if i.has_method(function):
				if value != null:
					i.call(function, value)
				else:
					i.call(function)

func get_conscious_party() -> Array:
	var arr := []
	for mem in party:
		if !StatusManager.is_unconscious(mem):
			arr.append(mem)
	return arr

func get_party_names() -> Array:
	var ret := []
	for mem in party:
		ret.append(mem.name)
	return ret

func set_dialog(path, npc = null):
	dialogue.append(["res://Data/Dialogue/" + path +".yaml", npc])

func set_respawn():
	globaldata.respawnPoint = persistPlayer.position
	globaldata.respawnScene = currentScene.get_filename()
	print("Respawn: %s %s" % [currentScene.name, globaldata.respawnPoint])

func goto_respawn():
	goto_scene(globaldata.respawnScene, globaldata.respawnPoint)
	create_party_followers()
	persistPlayer.direction = Vector2(0, 1)
	persistPlayer.blend_position(persistPlayer.direction)

func _input(event: InputEvent):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion :
		device = GAMEPAD
	elif event is InputEventKey:
		device = KEYBOARD
	
	if event is InputEventWithModifiers and !(event.alt or event.control or event.meta):
		if event.is_action_pressed("ui_fullscreen"):
			toggle_fullscreen()
			global.emit_signal("settings_changed")
			
		if event.is_action_pressed("ui_winsize"):
			if event.shift:
				increase_win_size(-1)
			else:
				increase_win_size(1)

func start_joy_vibration(device_id: int, weak_magnitude: float, strong_magnitude: float, duration: float = 0):
	if globaldata.rumble:
		Input.start_joy_vibration(device_id, weak_magnitude, strong_magnitude, duration)

func detect_buttons_style():
	var joy_name = Input.get_joy_name(0)
	var NINTENDO_PATTERNS = ["nintendo", "switch", "joy-con", "snes", "famicom", "pro controller", "gamecube"]
	var PLAYSTATION_PATTERNS = ["playstation", "sony", "ps5", "ps4", "ps3", "ps2", "dualsense", "dualshock"]
	for pattern in NINTENDO_PATTERNS:
		if pattern in joy_name.to_lower():
			return globaldata.BtnStyles.NINTENDO

	for pattern in PLAYSTATION_PATTERNS:
		if pattern in joy_name.to_lower():
			return globaldata.BtnStyles.PLAYSTATION

	return globaldata.BtnStyles.XBOX

# LOCALIZATION Code added: New method "set_win_size" to set window size to any value
# (especially from the options UI)
func increase_win_size(amount):
	var newWinSize = globaldata.winSize + amount

	if newWinSize < 1:
		newWinSize = int(OS.get_screen_size().x / 320)

	if OS.get_screen_size() < Vector2(320 * newWinSize, 180 * newWinSize):
		newWinSize = 1
	
	set_win_size(newWinSize)
	

func toggle_fullscreen(value = !OS.window_fullscreen):
	set_win_size(globaldata.winSize, value)

func set_win_size(newSizeNum, fullscreen = false):
	# Everything here needs to happen asynchronously: sometimes resizing the window hangs the system for a few milliseconds, causing issues
	yield(get_tree(), "idle_frame")

	if fullscreen != OS.window_fullscreen:
		OS.window_fullscreen = fullscreen

	if not fullscreen:
		var oldSize = OS.window_size
		var newSize = Vector2(320 * newSizeNum, 180 * newSizeNum)
		globaldata.winSize = newSizeNum
		if newSize != oldSize:
			OS.window_borderless = false
			var newPos = OS.window_position - (newSize - oldSize) / 2
			# We don’t want the title bar to be out of screen
			var topLeft = OS.get_screen_position() + Vector2(OS.get_screen_size().x * .1, 0)
			var bottomRight = OS.get_screen_position() + OS.get_screen_size() * .9
			newPos.x = clamp(newPos.x, topLeft.x - newSize.x, bottomRight.x)
			newPos.y = clamp(newPos.y, topLeft.y, bottomRight.y)
			OS.set_window_size(newSize)
			OS.set_window_position(newPos)

	global.emit_signal("settings_changed")

func set_music_volume(volume):
	globaldata.musicVolume = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), volume)
	global.emit_signal("settings_changed")

func set_sfx_volume(volume):
	globaldata.sfxVolume = volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), volume)
	global.emit_signal("settings_changed")

func toggle_language(ordered_languages, direction = 1):
	direction = sign(direction)
	# Obtaining the language code the game falls back to (ex: "fr" if locale is "fr_BE")
	var lang = tr("LANGUAGE_CODE")
	var index = ordered_languages.find(lang)
	var newIndex = fposmod(index + direction, ordered_languages.size())
	set_language(ordered_languages[newIndex])

func set_language(lang_code):
	TranslationServer.set_locale(lang_code)
	global.emit_signal("locale_changed")

# Sets the default language based on the OS, in cases where the automatic selection fails
func set_language_default():
	print("OS locale code: %s" % OS.get_locale())
	if OS.get_locale_language() == "es":
		if OS.get_locale() in ["es", "es_ES", "es_GQ", "es_IC"]:
			print("Switching to Spain Spanish")
			TranslationServer.set_locale("es_ES")
		else:
			print("Switching to American Spanish")
			TranslationServer.set_locale("es")
	else:
		var language_code = tr("LANGUAGE_CODE")
		if not language_code in get_supported_languages():
			language_code = LANGUAGE_DEFAULT
		TranslationServer.set_locale(language_code)

func get_supported_languages():
	if OS.is_debug_build():
		return LANGUAGES_DEBUG
	else:
		return LANGUAGES_RELEASE

func serialize_inputs() -> Dictionary:
	var controls = {}
	for action in InputMap.get_actions():
		controls[action] = []
		for event in InputMap.get_action_list(action):
			controls[action].append(var2str(event))
	return controls

func deserialize_inputs(controls) -> void:
	if controls != null:
		for action in controls:
			if InputMap.has_action(action):
				InputMap.action_erase_events(action)
				for event in controls[action]:
					var event_to_add = str2var(event)
					event_to_add.device = 0
					InputMap.action_add_event(action, event_to_add)

# Default action keys adapted to various keyboard layouts
func set_localized_default_inputs():
	var actions = ["ui_accept", "ui_cancel", "ui_select", "ui_focus_prev", "ui_focus_next"]
	var all_layouts = {
		"QWERTY": "ZXCAS", "AZERTY": "WXCQS", "BÉPO": "ZYXAU", "QWERTZ": "YXCAS",
		"QZERTY": "WXCAS", "DVORAK": ";QJAO", "COLEMAK": "ZXCAR", "NEO": "ZXCUI"
	}
	
	var user_layout_type = OS.get_latin_keyboard_variant()
	if user_layout_type in ["QWERTY", "ERROR"]:
		# workaround for BÉPO layout not recognized natively
		var os_layout_index = OS.keyboard_get_current_layout()
		var os_layout_name = OS.keyboard_get_layout_name(os_layout_index).to_upper()
		if ("BÉPO" in os_layout_name or "BEPO" in os_layout_name) \
			or (OS.keyboard_get_layout_language(os_layout_index) == "fr" and ("FRANCE" in os_layout_name) and not ("AZERTY" in os_layout_name)):
			user_layout_type = "BÉPO"
		else:
			user_layout_type = "QWERTY"
	
	for i in actions.size():
		var events = InputMap.get_action_list(actions[i])
		for event in events:
			if event is InputEventKey:
				event.scancode = ord(all_layouts[user_layout_type][i])
	
func start_playtime():
	$Playtimer.start()

func stop_playtime():
	$Playtimer.stop()

func _on_Playtimer_timeout():
	globaldata.playtime += 1

func save_settings():
	# LOCALIZATION Code change: Language isn't stored in globaldata anymore
	var save_dict = {
		"language": TranslationServer.get_locale(),
		"winsize": globaldata.winSize,
		"fullscreen": OS.window_fullscreen,
		"musicvolume": globaldata.musicVolume,
		"sfxvolume": globaldata.sfxVolume,
		"savefile": globaldata.saveFile,
		"inputmap": serialize_inputs(),
		"rumble": globaldata.rumble,
		"buttonsStyle": globaldata.buttonsStyle
	}
	

	var save_file = File.new()
	save_file.open_encrypted_with_pass("user://settings.save", File.WRITE,"ENCORE")
	save_file.store_line(to_json(save_dict))
	save_file.close()

func load_settings():
	var save_file = File.new()
	if not save_file.file_exists("user://settings.save"):
		set_language_default()
		return 
	
	save_file.open_encrypted_with_pass("user://settings.save", File.READ,"ENCORE")
	
	var save_data = parse_json(save_file.get_line())
	save_file.close()

	var language = save_data["language"]
	var winSize = save_data["winsize"]
	var fullscreen = save_data["fullscreen"]
	var musicVolume = save_data["musicvolume"]
	var sfxVolume = save_data["sfxvolume"]
	deserialize_inputs(save_data.get("inputmap"))
	globaldata.rumble = save_data.get("rumble", true)
	globaldata.buttonsStyle = save_data.get("buttonsStyle", globaldata.BtnStyles.DETECT)
	globaldata.saveFile = int(save_data.get("savefile", 0))

	if language in TranslationServer.get_loaded_locales():
		TranslationServer.set_locale(language)
	else:
		set_language_default()

	set_win_size(winSize, fullscreen)
	set_music_volume(musicVolume)
	set_sfx_volume(sfxVolume)
	
func save_from_dict(num: int, dict: Dictionary):
	audioManager.play_sfx(load("res://Audio/Sound effects/Save.mp3"), "menu")
	var save_file = File.new()
	save_file.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.WRITE,"ENCORE")
	save_file.store_line(to_json(dict))
	save_file.close()

func save_game(num: int):
	var location = phoneLocation if phoneLocation else currentScene.name

	var party_names := []
	for mem in party + partyNpcs:
		party_names.append(mem.name)

	var save_dict = {
		"scene": currentScene.get_filename(),
		"scenename": location,
		"posX": persistPlayer.position.x, 
		"posY": persistPlayer.position.y,
		"playtime": globaldata.playtime,
		"flags": globaldata.flags,
		"object_flags": globaldata.object_flags,
		"keys": globaldata.keys,
		"textspeed": globaldata.textSpeed,
		"menuflavor": globaldata.menuFlavor,
		"buttonprompts": globaldata.buttonPrompts,
		"earned_cash": globaldata.earned_cash,
		"description": globaldata.description,
		"cash": globaldata.cash,
		"bank": globaldata.bank,
		"ninten": globaldata.ninten.duplicate(true),
		"ana": globaldata.ana.duplicate(true),
		"lloyd": globaldata.lloyd.duplicate(true),
		"teddy": globaldata.teddy.duplicate(true),
		"pippi": globaldata.pippi.duplicate(true),
		"eve": globaldata.eve.duplicate(true),
		"flyingman": globaldata.flyingman.duplicate(true),
		"favoritefood": globaldata.favoriteFood,
		"playername": globaldata.playerName,
		"runsound": persistPlayer.run_sound,
		"dirX": persistPlayer.direction.x,
		"dirY": persistPlayer.direction.y,
		"party": party_names,
		"inventories": InventoryManager.save_inventories(),
		"rareDrops": globaldata.rareDrops,
		"encountered": globaldata.encountered
	}
	StatusManager.save_statuses(save_dict)
	save_from_dict(num, save_dict)
	set_respawn()
	globaldata.flags["saved"] = true

func load_to_dict(num):
	var save_file = File.new()
	if not save_file.file_exists("user://saveFile" + var2str(num) + ".save"):
		return
	save_file.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.READ,"ENCORE")
	var save_dict = parse_json(save_file.get_line())
	save_file.close()
	_upgrade_from_old_save(save_dict)
	return save_dict

func load_game(num, goto_game = true):
	var saveData = load_to_dict(num)
	if not saveData:
		return
	
	globaldata.respawnPoint = Vector2(saveData.get("posX", 0), saveData.get("posY", 0))
	globaldata.respawnScene = saveData.get("scene", globaldata.respawnScene)
	globaldata.playtime = int(saveData.get("playtime", 0))
	globaldata.ninten = saveData.get("ninten", globaldata.ninten)
	globaldata.ana = saveData.get("ana", globaldata.ana)
	globaldata.lloyd = saveData.get("lloyd", globaldata.lloyd)
	globaldata.teddy = saveData.get("teddy", globaldata.teddy)
	globaldata.pippi = saveData.get("pippi", globaldata.pippi)
	globaldata.flyingman = saveData.get("flyingman", globaldata.flyingman)
	globaldata.eve = saveData.get("eve", globaldata.eve)
	globaldata.favoriteFood = saveData.get("favoritefood", globaldata.favoriteFood)
	globaldata.playerName = saveData.get("playername", globaldata.playerName)
	globaldata.textSpeed = saveData.get("textspeed", globaldata.TEXT_SPEEDS[0])
	globaldata.menuFlavor = saveData.get("menuflavor", globaldata.FLAVORS[0])
	globaldata.buttonPrompts = saveData.get("buttonprompts", globaldata.BUTTON_PROMPTS[0])
	globaldata.earned_cash = int(saveData.get("earned_cash", 0))
	globaldata.cash = int(saveData.get("cash", 0))
	globaldata.bank = int(saveData.get("bank", 0))
	globaldata.description = saveData.get("description", true)
	InventoryManager.load_inventories(saveData.get("inventories", {}))
	globaldata.keys = saveData.get("keys", {})
	globaldata.object_flags = saveData.get("object_flags", {})
	globaldata.rareDrops = saveData.get("rareDrops", {})
	globaldata.encountered = saveData.get("encountered", {})
	#load statuses
	StatusManager.load_statuses(saveData)
	#reappend party
	party.clear()
	partyNpcs.clear()
	for i in saveData["party"]:
		if i in POSSIBLE_PLAYABLE_MEMBERS:
			party.append(globaldata.get(i))
		else:
			partyNpcs.append(globaldata.get(i))
	
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	
	for flag in globaldata.flags:
		globaldata.flags[flag] = saveData["flags"].get(flag, false)
		
	if goto_game:
		persistPlayer.pause()
		goto_scene(saveData["scene"], globaldata.respawnPoint, Vector2(saveData["dirX"], saveData["dirY"]))
		create_party_followers()
		persistPlayer.inputVector = Vector2(saveData["dirX"], saveData["dirY"])
		persistPlayer.direction = Vector2(saveData["dirX"], saveData["dirY"])
		persistPlayer.eventRayCaster.rotation = persistPlayer.direction.angle() - TAU/4
		persistPlayer.animationTree.active = true
		persistPlayer.blend_position(persistPlayer.direction)
		persistPlayer.travel_fainted("Idle", "FaintedIdle")
		if saveData.has("runsound"):
			saveData["runsound"] = saveData["runsound"].replace(".wav", "")
			persistPlayer.run_sound = saveData["runsound"]
			
		
		yield(get_tree(), "idle_frame")
		persistPlayer.unpause()
		start_playtime()

func erase_save(num):
	audioManager.play_sfx(load("res://Audio/Sound effects/M3/Party_Member_Death.wav"), "menu")
	var saveGame = Directory.new()
	saveGame.remove("user://saveFile" + var2str(num) + ".save")

func _upgrade_from_old_save(save_data: Dictionary):
	globaldata.reset_constant_char_data(save_data)

	for char_name in POSSIBLE_PARTY_MEMBERS:
		if save_data.has(char_name):
			var chara = save_data[char_name]
			if char_name in POSSIBLE_PLAYABLE_MEMBERS:
				# Escape characters that may cause conflicts with text tags
				chara["nickname"] = chara["nickname"].replace("[", "⟦").replace("]", "⟧")
			if chara.get("equipment", {}).get("head") != null:
				# Handle the new slots (arms/body/other instead of head/body/other)
				chara["equipment"]["arms"] = ""
				chara["equipment"]["other"] = chara["equipment"]["head"]
				chara["equipment"].erase("head")
			# Remove passiveSkill field, we don’t need that anymore (deduced from items)
			chara.erase("passiveSkills")
			# Remove passiveHeal field, it's handled within the status now
			chara.erase("passiveHeal")
			# Convert statuses from integers to dictionaries
			var status = chara.get("status")
			if status != null:
				var old_status_enum = ["asthma","blinded","burned","cold","confused","forgetful","nausea","numb","poisoned","sleeping","sunstroked","mushroomized","unconscious"]
				for i in range(status.size()):
					if typeof(status[i]) in [TYPE_INT, TYPE_REAL]:
						status[i] = { "status": old_status_enum[status[i]] }
							

	# Now "party" is just an array of names, because we don't need duplicate data
	for i in save_data.get("party", []).size():
		if save_data.party[i] is Dictionary:
			save_data.party[i] = save_data.party[i].name

	# Now "partyNpcs" is just an array of names, because we don't need duplicate data
	for i in save_data.get("partyNpcs", []).size():
		save_data.party.append(save_data.partyNpcs[i].name)
	save_data.erase("partyNpcs")

	save_data["flags"]["visited_podunk"] = true

	save_data["object_flags"] = save_data.get("object_flags", {})
	for flag_key in save_data["flags"].keys():
		if ("_present_" in flag_key) or ("_pres_" in flag_key)\
			or ("_item_" in flag_key) or ("_key_" in flag_key)\
			or ("_door_" in flag_key) or ("_plate_" in flag_key):
			var new_flag_key = flag_key
			new_flag_key = flag_key.replace("debug_present_", "Debug World/Present")\
			.replace("basement_pres_", "Ninten's House/Present")\
			.replace("podunk_pres_", "Podunk/Present")\
			.replace("cem_pres_", "Podunk/PresentCem")\
			.replace("zoo_pres_", "Podunk/PresentZoo")\
			.replace("catac_pres_", "Catacombs/Present")\
			.replace("zoo_office_pres_", "Zoo Office/Present")\
			.replace("catac_item_", "Catacombs/Item")\
			.replace("catac_key_", "Catacombs/Key")\
			.replace("catac_door_", "Catacombs/Locked Door")\
			.replace("catac_plate_", "Catacombs/Plate")\

			if new_flag_key != flag_key:
				save_data["object_flags"][new_flag_key] = save_data["flags"][flag_key] or save_data["object_flags"].get(new_flag_key, false)
				save_data["flags"].erase(flag_key)
