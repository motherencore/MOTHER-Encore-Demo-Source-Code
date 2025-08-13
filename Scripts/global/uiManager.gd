extends Node

signal menuFlavorUpdated

const GameOverRes = preload("res://Nodes/Ui/GameOver.tscn")

onready var CommandsMenuRes = preload("res://Nodes/Ui/Pause menu.tscn")
var DialogueBoxRes = preload("res://Nodes/Ui/DialogueBox.tscn")
var BattleMenuRes = preload("res://Nodes/Ui/Battle/Battle.tscn")
var BlackBarsRes = preload("res://Nodes/Ui/Blackbars.tscn")
var ATMMenuRes = preload("res://Nodes/Ui/ATM/ATM Menu.tscn")
var CashBoxRes = preload("res://Nodes/Ui/CashBox.tscn")
var PhoneUnitsBoxRes = preload("res://Nodes/Ui/PhoneUnitsBox.tscn")
var KeyIndicatorRes = preload("res://Nodes/Ui/KeyCount.tscn")
var ShopRes = preload("res://Nodes/Ui/Shop/ShopUI.tscn")
var StorageRes = preload("res://Nodes/Ui/Storage.tscn")
var SaveSelectRes = preload("res://Maps/SaveSelect.tscn")
var TeleportRes = preload("res://Nodes/Ui/Teleport/TeleportUI.tscn")
var KeyboardRes = preload("res://Maps/Naming screen.tscn")
var PartyInfoRes = preload("res://Nodes/Ui/PartyInfo.tscn")
var BattleTransitionRes = preload("res://Nodes/Ui/Battle/Battle Transition.tscn")
onready var cash = CashBoxRes.instance()
onready var phone_units = PhoneUnitsBoxRes.instance()
onready var key = KeyIndicatorRes.instance()
onready var party_info_view = PartyInfoRes.instance()
onready var _black_bars = BlackBarsRes.instance()
var menuFlavorShader = preload("res://Shaders/MenuFlavors.tres")
var battleBGs := {}
var battleWinCutscene := ""
var battleFleeCutscene := ""
var battleLoseCutscene := ""
var battleWinFlag := ""
var battleRematchFlag := ""
var battleLoseHeal := ""
var queueSetCrumbs := false

var _fixed_camera

var _commands_menu
var commandsMenuActive = false
var uiActive = false
var fade = null
var stableCanvasLayer = null
var uiStack = []
var onScreenEnemies = []
var dialogueBox


# Menu flavor colors, First is Border, Second is Darker Border, Third is InnerBorder, Fourth is Interior, Fifth is Highlight and Sixth is Interior Secondary Tone (seen in the party plate of the pause menu)
var menuFlavors = [
	["f3f2f4", "bfb4cd", "7a6c86", "141117", "ba53e4", "d6cedf", "332943"],	# Plain
	["a9fff1", "4ca8b0", "5d6fa5", "230c24", "945ffa", "69c3c4", "36182e"],	# Mint
	["ffa2b5", "e47089", "b8425a", "361115", "2fc05c", "ee8399", "4f1e15"],	# Strawberry
	["ffd152", "d4722c", "ad552f", "220a07", "d85123", "e08b37", "3c1a14"],	# Banana
	["fa8a52", "c2473c", "993131", "33161a", "c92727", "d86146", "432822"],	# Peanut
	["eab3ff", "a669c6", "304280", "171b32", "de3995", "b97ed6", "2e2743"],	# Grape
	["81e06e", "4bb367", "963948", "29101c", "ff4f75", "a8c469", "362126"]	# Melon
]


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var canvasLayerNode = load("res://Nodes/Ui/mainCanvasLayer.tscn")
	
	set_menu_flavors(globaldata.menuFlavor)
	
	# Load all the battle bgs
	_load_battle_bgs()
	
	if stableCanvasLayer == null:
		stableCanvasLayer = canvasLayerNode.instance()
		global.currentScene.add_child(stableCanvasLayer)
		global.add_persistent(stableCanvasLayer)
		_add_to_canvas(_black_bars, 0)
		_add_to_canvas(cash, 1)
		_add_to_canvas(phone_units, 1)
		_add_to_canvas(key, 2)
		_add_to_canvas(party_info_view, 3)
	
	if fade == null:
		var transitionNode = load("res://Nodes/Ui/effects/Fade.tscn")
		var transition = transitionNode.instance()
		transition.set_name("fade")
		stableCanvasLayer.add_child(transition)
		fade = transition

func set_menu_flavors(flavor):
	var flavor_index = globaldata.FLAVORS.find(flavor)
	for i in 7:
		menuFlavorShader.set_shader_param("NEWCOLOR%s" % (i+1), Color(menuFlavors[flavor_index][i]))
	emit_signal("menuFlavorUpdated")

func add_ui(ui, add_child = true):
	uiStack.push_front(ui)
	uiActive = true
	if add_child:
		stableCanvasLayer.call_deferred("add_child", ui)

func remove_ui(ui=uiStack[0]):
	if ui in uiStack:
		uiStack.erase(ui)
	if is_instance_valid(ui):
		close_item(ui)
	if uiStack.empty():
		uiActive = false

func get_fixed_camera():
	if _fixed_camera == null:
		_fixed_camera = preload("res://Nodes/Ui/Camera.tscn").instance()
		get_tree().get_root().add_child(_fixed_camera)
	return _fixed_camera

func close_current():
	remove_ui()

func close_item(item): #Calls a function in the menu that closes it.
	if item.has_method('close'):
		item.close()
	else:
		item.queue_free()

func open_dialogue_box():
	dialogueBox = DialogueBoxRes.instance()
	add_ui(dialogueBox)
	commandsMenuActive = false
	return dialogueBox

func get_key_count(): #Returns the amount of keys collected in a scene. If you can't collect keys in a scene, it returns -1 
	return globaldata.keys.get(global.currentScene.name, 0)

func try_alter_key_count(delta): #Increases or decreases the amount of keys collected. Returns true if and only if it succeeds.
	var key_count = get_key_count()
	if key_count >= 0 and key_count + delta >= 0:
		globaldata.keys[global.currentScene.name] = globaldata.keys.get(global.currentScene.name, 0) + delta
		return true
	else:
		return false

func open_commands_menu():
	global.persistPlayer.pause()
	_commands_menu = CommandsMenuRes.instance()
	add_ui(_commands_menu)
	commandsMenuActive = true

func close_commands_menu(keep_pause = false, remove_bars = false):
	party_info_view.close()
	audioManager.music_muffle(0, 0)
	remove_ui(_commands_menu)
	commandsMenuActive = false
	_commands_menu.queue_free()
	if !keep_pause:
		global.persistPlayer.unpause()
	if remove_bars:
		toggle_black_bars(false)

func toggle_black_bars(show):
	_black_bars.toggle(show)

func start_battle(advantage = 0, can_run = true, enemies_to_join = []):
	if global.inBattle:
		return
	global.persistPlayer.pause()
	
	# hoooo boy this is gonna be some funky code right here.
	var root = get_tree().root
	var battle_ui = BattleMenuRes.instance()
	
	if !enemies_to_join:
		# add enemies to battle and an enemyTransition sprite
		for enemy in onScreenEnemies:
			#enemy[1].set_physics_process(false)
			if enemy[1] != null:
				if enemy[1].get("eventRayCaster") != null and !enemy[1].drafted:
					enemy[1].eventRayCaster.look_at(global.persistPlayer.global_position + global.persistPlayer.get_node("CollisionShape2D").position * 2)
					if enemy[1].eventRayCaster.get_collider() == global.persistPlayer:
						enemy[1].emotes.hide()
						enemy[1].emotes.frame = 0
						enemies_to_join.append(enemy)
				else:
					enemy[1].emotes.hide()
					enemy[1].emotes.frame = 0
					enemies_to_join.append(enemy)
					enemy[1].drafted = false
			else:
				enemies_to_join.append(enemy)

	var transition = BattleTransitionRes.instance()
	transition.battleui = battle_ui

	battle_ui.init_battle_params(enemies_to_join, advantage == 1, advantage == 2, can_run, battleBGs, transition)
	
	if global.currentCamera.shaking:
		yield(global.currentCamera, "stoped_shaking")
	
	#and lastly, add to UI canvas
	add_ui(battle_ui)
	
	# THEN a back buffer copy to the root, right before the current scene
	# This captures the BG as the SCREEN_TEXTURE, which is used by the transition shader
	var backBuffer = BackBufferCopy.new()
	backBuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	root.add_child(backBuffer)
	root.move_child(backBuffer, root.get_children().size() - 2)
	
	# add the transition ui, keep at the end of the draw order. So it draws on top of everything else
	root.call_deferred("add_child", transition)
	# Set the position to the VIEWPORT POSITION (aka, so it lines up with the camera)
	transition.position = -get_viewport().canvas_transform.origin
	
	var transparency = 130
	match advantage:
		0:
			transition.set_color(Color8(0, 0, 255, transparency))
			#normal
		1:
			transition.set_color(Color8(0, 255, 0, transparency))
			#player advantage
		2:
			transition.set_color(Color8(255, 0, 0, transparency))
			#enemy advantage
	
	# delete the backbuffer after the transition is complete
	transition.connect("done", backBuffer, "queue_free")

#updates enemy ids
func update_enemy_ids():
	for enemy in onScreenEnemies:
		if enemy[1].has_method("updateId"):
			enemy[1].updateId(onScreenEnemies.find(enemy))

func _add_to_canvas(node, layer=0):
	stableCanvasLayer.add_child(node)
	if layer != -1:
		stableCanvasLayer.move_child(node, layer)

func _load_battle_bgs():
	var dir = Directory.new()
	var path = "res://Graphics/Battle BGS/"
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				# jank bg import lol
				if file_name.ends_with(".bbg.import"):
					battleBGs[file_name.replace(".bbg.import", "")] = load(path + file_name.replace(".import", ""))
				elif file_name.ends_with(".dsp.import"):
					battleBGs[file_name.replace(".dsp.import", "")] = load(path + file_name.replace(".import", ""))
			file_name = dir.get_next()

func reset_battle_cutscenes():
	battleFleeCutscene = ""
	battleLoseCutscene = ""
	battleWinCutscene = ""
	battleWinFlag = ""
	battleLoseHeal = ""

func update_key_indicator():
	if get_key_count() <= 0:
		key.close()
	else:
		key.open()

func close_key_indicator():
	key.close()

func open_shop(shop):
	var shopui = ShopRes.instance()
	shopui.shopYamlName = shop
	commandsMenuActive = false
	add_ui(shopui)

func open_storage(god_mode = false):
	var storageui = StorageRes.instance()
	storageui.god_mode = god_mode
	commandsMenuActive = false
	add_ui(storageui)

func open_atm():
	var atmui = ATMMenuRes.instance()
	commandsMenuActive = false
	add_ui(atmui)

func open_teleport():
	var teleport_ui = TeleportRes.instance()
	add_ui(teleport_ui)
	yield(teleport_ui, "entered")

func open_save(type := SaveSelect.Type.SAVE):
	var saveui = SaveSelectRes.instance()
	commandsMenuActive = false
	saveui.init(type, globaldata.saveFile, true)
	add_ui(saveui)

func open_keyboard(scenario):
	var keyboard_ui = KeyboardRes.instance()
	commandsMenuActive = false
	keyboard_ui.init(scenario, true)
	add_ui(keyboard_ui)

func open_ocarina_screen():
	pass

func set_telepathy_effect(enabled, object = global.persistPlayer):
	if enabled:
		fade.focus_object(object)
		fade.set_color(Color(0, 0, 0, 0.5))
		fade.set_cut(0.1, 0.3, 1, Tween.EASE_OUT)
		fade.set_spin(true, 0.5)
	else:
		fade.set_cut(1, 0.3, 1, Tween.EASE_IN)
		yield(fade, "cut_done")
		print("DONE")
		fade.set_spin(false)

func create_flying_num(text, targetPos):
	var flyingNumTscn = load("res://Nodes/Ui/Battle/FlyingNumber.tscn")
	var flyingNum = flyingNumTscn.instance()
	flyingNum.text = str(text)
	global.currentScene.add_child(flyingNum)
	flyingNum.rect_position = targetPos - Vector2(16, 0) 
	flyingNum.run()

func clearOnScreenEnemies():
	onScreenEnemies.clear()

func game_over(play_sfx = true):
	if play_sfx:
		audioManager.play_sfx(load("res://Audio/Sound effects/PartyLose.mp3"), "PartyLose")
	var game_over = GameOverRes.instance()
	add_ui(game_over)
	yield(game_over, "fade_done")
