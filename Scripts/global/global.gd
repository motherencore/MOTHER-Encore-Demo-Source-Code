extends Node2D

signal cutscene_ended
signal scene_changed

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
onready var dialogueBox = load("res://Nodes/Ui/DialogueBox.tscn")
var maxInventorySlots = 10
var dialogue = ""
var receiver = ""
var itemname = ""
var itemart = ""
var device = "Keyboard"
var cutscene = false
var talker = null
var inBattle = false
var queuedBattle = false
var gameover = false
var fadeout = 0


onready var playerNode = load("res://Nodes/Reusables/Player.tscn")

const partyMembers = ["ninten", "lloyd", "ana", "teddy", "pippi", "canarychick", "flyingman", "eve"]

func _ready():
	load_settings()
	set_dialog("noproblem", null)
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

func _physics_process(_delta):
	#print(party)
	if uiManager.uiStack.size() == 0:
		if Input.is_action_just_pressed("ui_select") and !persistPlayer.paused and persistPlayer.state == persistPlayer.MOVE:
			uiManager.open_commands_menu()
	
	if Input.is_action_just_pressed("ui_F4"):
		OS.window_fullscreen = !OS.window_fullscreen
		
	if Input.is_action_just_pressed("ui_F5"):
		increase_win_size(1)

func start_slowmo(speed, length):
	$Slowmo.start_slowmo(speed, length)

func add_persistent(node_to_persist):
	persistArray.append(node_to_persist)

func remove_persistent(node_to_remove):
	persistArray.erase(node_to_remove)

func goto_scene(path, playerPosition = Vector2.ZERO):
	call_deferred("_deferred_goto_scene", path, playerPosition)

func _deferred_goto_scene(path, playerPosition = Vector2.ZERO):
	if currentScene.has_node("YSort"):
		currentScene.get_node("YSort").remove_child(persistPlayer)
	else:
		currentScene.get_node("Objects").remove_child(persistPlayer)
	
	persistPlayer.collision.disabled = true
	
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
	set_party_position(playerPosition)
	
	
	for node in persistArray:
		currentScene.add_child(node)
	
	get_tree().set_current_scene(currentScene)
	uiManager.scene_changed()
	yield(get_tree(), "idle_frame")
	
	persistPlayer.collision.disabled = false

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

func set_party_position(position):
	persistPlayer.position = position
	if partySize > 1:
		for i in global.partySpace.size():
			partySpace.push_front(position)
			partySpace.pop_back()
	for i in partyObjects:
		if i.get("direction") != null:
			i.direction = Vector2(0, 1)
		elif i.get("inputVector") != null:
			i.inputVector = Vector2(0, 1)

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

func get_conscious_party():
	var arr = []
	for partyMember in party:
		if !partyMember["status"].has(globaldata.ailments.Unconscious):
			arr.append(partyMember)
	return arr

func set_dialog(path, npc):
	dialogue = "res://Data/Dialogue/" + path +".json"
	talker = npc

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

func _input(event):
	if event is InputEventJoypadButton or event is InputEventJoypadMotion :
		device = "Gamepad"
	elif event is InputEventKey:
		device = "Keyboard"

func increase_win_size(amount):
	globaldata.winSize += amount
	
	if globaldata.winSize < 1:
		globaldata.winSize = int(OS.get_screen_size().x / 320)
	
	if OS.get_screen_size() < Vector2(320 * globaldata.winSize, 180 * globaldata.winSize):
		globaldata.winSize = 1
	
	OS.window_borderless = false
	OS.window_fullscreen = false
	OS.set_window_size(Vector2(320 * globaldata.winSize, 180 * globaldata.winSize))
	OS.set_window_position(OS.get_screen_size()*0.5 - OS.get_window_size()*0.5)

func start_playtime():
	$Playtimer.start()

func stop_playtime():
	$Playtimer.stop()

func _on_Playtimer_timeout():
	globaldata.playtime += 1

func save_settings():
	var saveDict = {
		"language": globaldata.language,
		"winsize": globaldata.winSize,
		"fullscreen": OS.window_fullscreen,
		"musicvolume": globaldata.musicVolume,
		"sfxvolume": globaldata.sfxVolume
	}
	

	var saveGame = File.new()
	saveGame.open_encrypted_with_pass("user://settings.save", File.WRITE,"ENCORE")
	saveGame.store_line(to_json(saveDict))
	saveGame.close()

func load_settings():
	var saveGame = File.new()
	if not saveGame.file_exists("user://settings.save"):
		return 
	
	saveGame.open_encrypted_with_pass("user://settings.save", File.READ,"ENCORE")
	
	var saveData = parse_json(saveGame.get_line())
	
	globaldata.language = saveData["language"]
	globaldata.winSize = saveData["winsize"]
	OS.window_fullscreen = saveData["fullscreen"]
	globaldata.musicVolume = saveData["musicvolume"]
	globaldata.sfxVolume = saveData["sfxvolume"]
	
	OS.set_window_size(Vector2(320 * globaldata.winSize, 180 * globaldata.winSize))
	OS.set_window_position(OS.get_screen_size()*0.5 - OS.get_window_size()*0.5)
	saveGame.close()

func save():
	var saveDict = {
		"scene": currentScene.get_filename(),
		"scenename": currentScene.name,
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
		"favoritefood": globaldata.favoriteFood,
		"flying": globaldata.flyingman,
		"runsound": persistPlayer.run_sound,
		"dirX": persistPlayer.direction.x,
		"dirY": persistPlayer.direction.y,
		"party": party,
		"partyNpcs": partyNpcs,
		"inventories": InventoryManager._save_inventories(),
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
		InventoryManager._load_inventories(saveData["inventories"])
	if saveData.has("keys"):
		globaldata.keys = saveData["keys"]
	
	#reappend party
	global.party.clear()
	for i in saveData["party"]:
		global.party.append(globaldata.get(i["name"]))
	
	global.partyNpcs.clear()
	for i in saveData["partyNpcs"]:
		global.partyNpcs.append(globaldata.get(i["name"]))
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	
	#reappend statuses
	for partyMem in [globaldata.ninten, globaldata.ana, globaldata.lloyd, globaldata.teddy, globaldata.pippi, globaldata.flyingman]:
		var tempstatus = []
		for i in partyMem.status:
			tempstatus.append(globaldata.status_int_to_enum(i))
		partyMem.status.clear()
		partyMem.status.append_array(tempstatus)
		
	
	for i in saveData["flags"]:
		if globaldata.flags.get(i) != null:
			globaldata.flags[i] = saveData["flags"][i]
	
	
	if goto_game:
		persistPlayer.pause()
		goto_scene(saveData["scene"], globaldata.respawnPoint)
		create_party_followers()
		persistPlayer.inputVector = Vector2(saveData["dirX"], saveData["dirY"])
		persistPlayer.direction = Vector2(saveData["dirX"], saveData["dirY"])
		persistPlayer.animationTree.active = true
		persistPlayer.blend_position(persistPlayer.direction)
		persistPlayer.travel_fainted("Idle", "FaintedIdle")
		if saveData.has("runsound"):
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
