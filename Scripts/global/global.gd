extends Node2D

signal cutscene_ended
signal scene_changed
signal locale_changed
signal inputs_changed
signal settings_changed

onready var tween = $Tween
var party =  []
var partyNpcs = []
var partySize: int = 255
var partySpace = []
var persistArray = []
var partyObjects = []
var currentScene = null
var previousScene = null
var persistPlayer = null
var currentCamera = null
var debugMenu = load("res://Nodes/Ui/debug/debug.tscn")
var maxInventorySlots = 10
var dialogue = []
var receiver = null
var itemUser = null
var item = null
enum {KEYBOARD, GAMEPAD}
var device = KEYBOARD
var cutscene = false
var talker = null
var inBattle = false
var queuedBattle = false
var gameover = false
var fadeout = 0
var phoneLocation
var mousePosition
var mouseShownTime: float = 0.0
var mouseHiddenTime: float = 0.0

var LANGUAGES_DEBUG = ["en", "fr", "it", "ja", "ko", "es", "es_ES", "pt_BR", "pl", "de", "ru"]
var LANGUAGES_RELEASE = ["en", "fr", "it", "ja", "ko", "es", "es_ES", "pt_BR", "pl", "de"]
var LANGUAGE_DEFAULT = "en"

onready var playerNode = load("res://Nodes/Reusables/Player.tscn")

const POSSIBLE_PARTY_MEMBERS = ["ninten", "lloyd", "ana", "teddy", "pippi", "canarychick", "flyingman", "eve"]

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
		if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
			mouseHiddenTime += delta
			if mouseHiddenTime >= 0.05:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				mouseHiddenTime = 0
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		mouseShownTime += delta
		
	mousePosition = Input.get_last_mouse_speed()
	
	if mouseShownTime >= 1.5:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		mouseShownTime = 0
	
	if OS.is_debug_build():
		if Input.is_action_just_pressed("ui_g"):
			Engine.time_scale = 2.0
		elif Input.is_action_just_released("ui_g"):
			Engine.time_scale = 1.0
		
		if Input.is_action_just_pressed("ui_F2") and !persistPlayer.paused and persistPlayer.state == persistPlayer.MOVE and !global.inBattle:
			uiManager.onScreenEnemies.append(["TEST", null])
			uiManager.onScreenEnemies.append(["TEST", null])
			uiManager.onScreenEnemies.append(["TEST", null])
			uiManager.start_battle()
		
		if Input.is_action_just_pressed("ui_F6"):
			global.persistPlayer.pause()
			uiManager.open_storage()

		if Input.is_action_just_pressed("ui_F7"):
			global.persistPlayer.pause()
			uiManager.open_storage(true)

		if Input.is_action_just_pressed("ui_L"):
			audioManager.fadeout_all_music(0.5)
			load_game(globaldata.saveFile)
		
		# LOCALIZATION Code added: Debug feature to quickly translate the UI
		if Input.is_action_just_pressed("ui_translate"):
			toggle_language(LANGUAGES_DEBUG)
			save_settings()
		for i in LANGUAGES_DEBUG.size():
			if Input.is_action_just_pressed("ui_lang%s" % i):
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
		
		if Input.is_action_just_pressed("ui_backtick"):
			if uiManager.uiStack.size() == 0:
				var dm = debugMenu.instance()
				uiManager.add_ui(dm)
		
		var party_keys = ["one", "two", "three", "four", "five", "six", "seven"]
		for i in party_keys.size():
			if Input.is_action_just_pressed("ui_%s" % party_keys[i], true):
				var party_member = globaldata.get(POSSIBLE_PARTY_MEMBERS[i])
				if party_member in party:
					if party_member.status.has(globaldata.ailments.Unconscious):
						if partyObjects.size() > 1:
							party.erase(party_member)
							if party_member != globaldata.ninten:
								party_member.status.clear()
						else: 
							party_member.status.clear()
					else: 
						party_member.status.append(globaldata.ailments.Unconscious)
				else:
					party.append(party_member) 
					if party_member == globaldata.ninten:
						party_member.status.clear()
				create_party_followers()
				persistPlayer._spritesheet()
			
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
	var PassiveHealer
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").remove_child(persistPlayer)
	else:
		currentScene.get_node("Objects").remove_child(persistPlayer)
	PassiveHealer = currentScene.get_node("Objects").get_node_or_null("PassiveHeal")
	if PassiveHealer != null:
		PassiveHealer = PassiveHealer.duplicate()
	
	persistPlayer.set_all_collisions(false)
	
	for node in persistArray:
		if node != null:
			node.get_parent().remove_child(node)
	currentScene.free()
	var scene = ResourceLoader.load(path)
	currentScene = scene.instance()
	
	
	get_tree().get_root().add_child(currentScene)
	
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").add_child(persistPlayer)
	else:
		currentScene.get_node("Objects").add_child(persistPlayer)
	
	create_party_followers()
	set_party_position(playerPosition, playerDirection)
	
	if PassiveHealer != null:
		currentScene.get_node("Objects").add_child(PassiveHealer)
	
	for node in persistArray:
		currentScene.add_child(node)
	
	get_tree().set_current_scene(currentScene)
	uiManager.scene_changed()
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
		persistPlayer._spritesheet()
	else:
		persistPlayer.costume = "Snow"
		persistPlayer._spritesheet()

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
		if i >= party.size() - 1:
			follow.partyMemberClass = global.partyNpcs
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

func get_conscious_party():
	var arr = []
	for partyMember in party:
		if !partyMember["status"].has(globaldata.ailments.Unconscious):
			arr.append(partyMember)
	return arr

func set_dialog(path, npc):
	dialogue.append(["res://Data/Dialogue/" + path +".json", npc])

func set_respawn():
	globaldata.respawnPoint = persistPlayer.position
	globaldata.respawnScene = currentScene.get_filename()
	print(globaldata.respawnPoint)
	print(globaldata.respawnScene)

func goto_respawn():
	goto_scene(globaldata.respawnScene, globaldata.respawnPoint)
	create_party_followers()
	persistPlayer.direction = Vector2(0, 1)
	persistPlayer.blend_position(persistPlayer.direction)

func get_location():
	if phoneLocation == "":
		return currentScene.name
	else:
		return phoneLocation

func _input(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion :
		device = GAMEPAD
	elif event is InputEventKey:
		device = KEYBOARD
	
	if event.is_action_pressed("ui_fullscreen"):
		toggle_fullscreen()
		global.emit_signal("settings_changed")
		
	if event.is_action_pressed("ui_winsize"):
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
			return globaldata.BTN_STYLES.NINTENDO

	for pattern in PLAYSTATION_PATTERNS:
		if pattern in joy_name.to_lower():
			return globaldata.BTN_STYLES.PLAYSTATION

	return globaldata.BTN_STYLES.XBOX

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
			InputMap.action_erase_events(action)
			for event in controls[action]:
				InputMap.action_add_event(action, str2var(event))

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
	var saveDict = {
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
	

	var saveGame = File.new()
	saveGame.open_encrypted_with_pass("user://settings.save", File.WRITE,"ENCORE")
	saveGame.store_line(to_json(saveDict))
	saveGame.close()

func load_settings():
	var saveGame = File.new()
	if not saveGame.file_exists("user://settings.save"):
		set_language_default()
		return 
	
	saveGame.open_encrypted_with_pass("user://settings.save", File.READ,"ENCORE")
	
	var saveData = parse_json(saveGame.get_line())
	
	var language = saveData["language"]
	var winSize = saveData["winsize"]
	var fullscreen = saveData["fullscreen"]
	var musicVolume = saveData["musicvolume"]
	var sfxVolume = saveData["sfxvolume"]
	deserialize_inputs(saveData.get("inputmap"))
	globaldata.rumble = saveData.get("rumble", true)
	globaldata.buttonsStyle = saveData.get("buttonsStyle", globaldata.BTN_STYLES.DETECT)
	globaldata.saveFile = int(saveData.get("savefile", 0))

	if language in get_supported_languages():
		TranslationServer.set_locale(language)
	else:
		set_language_default()

	set_win_size(winSize, fullscreen)
	set_music_volume(musicVolume)
	set_sfx_volume(sfxVolume)
	
	saveGame.close()

func save():
	var saveDict = {
		"scene": currentScene.get_filename(),
		"scenename": get_location(),
		"posX": persistPlayer.position.x, 
		"posY": persistPlayer.position.y,
		"playtime": globaldata.playtime,
		"flags": globaldata.flags,
		"keys": globaldata.keys,
		"textspeed": globaldata.textSpeed,
		"menuflavor": globaldata.menuFlavor,
		"buttonprompts": globaldata.buttonPrompts,
		"earned_cash": globaldata.earned_cash,
		"description": globaldata.description,
		"cash": globaldata.cash,
		"bank": globaldata.bank,
		"ninten": globaldata.ninten,
		"ana": globaldata.ana,
		"lloyd": globaldata.lloyd,
		"teddy": globaldata.teddy,
		"pippi": globaldata.pippi,
		"eve": globaldata.eve,
		"favoritefood": globaldata.favoriteFood,
		"flying": globaldata.flyingman,
		"runsound": persistPlayer.run_sound,
		"dirX": persistPlayer.direction.x,
		"dirY": persistPlayer.direction.y,
		"party": party,
		"partyNpcs": partyNpcs,
		"inventories": InventoryManager.save_inventories(),
		"rareDrops": globaldata.rareDrops
	}
	return saveDict

func save_from_dict(num, dict):
	audioManager.play_sfx(load("res://Audio/Sound effects/Save.mp3"), "menu")
	var saveGame = File.new()
	saveGame.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.WRITE,"ENCORE")
	saveGame.store_line(to_json(dict))
	saveGame.close()

func save_game(num):
	audioManager.play_sfx(load("res://Audio/Sound effects/Save.mp3"), "menu")
	var saveGame = File.new()
	saveGame.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.WRITE,"ENCORE")
	var saveData = global.save()
	saveGame.store_line(to_json(saveData))
	saveGame.close()
	set_respawn()
	globaldata.flags["saved"] = true

func load_game(num, goto_game = true):
	var saveGame = File.new()
	if not saveGame.file_exists("user://saveFile" + var2str(num) + ".save"):
		return 
	
	saveGame.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.READ,"ENCORE")

	var saveData = parse_json(saveGame.get_line())
	
	if saveData.has("posX") and saveData.has("posY"):
		globaldata.respawnPoint = Vector2(saveData["posX"], saveData["posY"])
	if saveData.has("scene"):
		globaldata.respawnScene = saveData["scene"]
	if saveData.has("playtime"):
		globaldata.playtime = saveData["playtime"]
	
	
	if saveData.has("ninten"):
		globaldata.ninten = saveData["ninten"]
	if saveData.has("ana"):
		globaldata.ana = saveData["ana"]
	if saveData.has("lloyd"):
		globaldata.lloyd = saveData["lloyd"]
	if saveData.has("teddy"):
		globaldata.teddy = saveData["teddy"]
	if saveData.has("pippi"):
		globaldata.pippi = saveData["pippi"]
	if saveData.has("favoritefood"):
		globaldata.favoriteFood = saveData["favoritefood"]
	if saveData.has("flying"):
		globaldata.flyingman = saveData["flying"]
	if saveData.has("eve"):
		globaldata.flyingman = saveData["eve"]
	if saveData.has("textspeed"):
		globaldata.textSpeed = saveData["textspeed"]
	if saveData.has("menuflavor"):
		globaldata.menuFlavor = saveData["menuflavor"]
	if saveData.has("buttonprompts"):
		globaldata.buttonPrompts = saveData["buttonprompts"]
	if saveData.has("earned_cash"):
		globaldata.earned_cash = saveData["earned_cash"]
	if saveData.has("cash"):
		globaldata.cash = saveData["cash"]
	if saveData.has("bank"):
		globaldata.bank = saveData["bank"]
	if saveData.has("description"):
		globaldata.description = saveData["description"]
	if saveData.has("inventories"):
		InventoryManager.load_inventories(saveData["inventories"])
	if saveData.has("keys"):
		globaldata.keys = saveData["keys"]
	if saveData.has("rareDrops"):
		globaldata.rareDrops = saveData["rareDrops"]
	
	#reappend party
	global.party.clear()
	for i in saveData["party"]:
		global.party.append(globaldata.get(i["name"]))
	
	global.partyNpcs.clear()
	for i in saveData["partyNpcs"]:
		global.partyNpcs.append(globaldata.get(i["name"]))
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	
	#reappend statuses
	for partyMem in POSSIBLE_PARTY_MEMBERS:
		var tempstatus = []
		for i in globaldata.get(partyMem).status:
			tempstatus.append(int(i))
		globaldata.get(partyMem).status.clear()
		globaldata.get(partyMem).status.append_array(tempstatus)
		
	
	for flag in globaldata.flags:
		if saveData["flags"].get(flag) != null:
			globaldata.flags[flag] = saveData["flags"][flag]
		else:
			globaldata.flags[flag] = false
	
	globaldata.upgrade_from_old_save()
	
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
	saveGame.close()

func erase_save(num):
	audioManager.play_sfx(load("res://Audio/Sound effects/M3/Party_Member_Death.wav"), "menu")
	var saveGame = Directory.new()
	saveGame.remove("user://saveFile" + var2str(num) + ".save")

#Utility function, may be moved to a better place like Utils.gd if it exist?
static func delete_children(node):
	for n in node.get_children():
		n.free()
