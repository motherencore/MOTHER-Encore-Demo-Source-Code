extends Node

signal menuFlavorUpdated

const _game_over_node = preload("res://Nodes/Ui/GameOver.tscn")

onready var _commands_menu_node = preload("res://Nodes/Ui/Pause menu.tscn")
var _dialogue_box_node = preload("res://Nodes/Ui/DialogueBox.tscn")
var _battle_menu_node = preload("res://Nodes/Ui/Battle/Battle.tscn")
var _battle_bg_node = preload("res://Nodes/Ui/Battle/BattleBG.tscn")
var _black_bars_node = preload("res://Nodes/Ui/Blackbars.tscn")
var _atm_menu_node = preload("res://Nodes/Ui/ATM/ATM Menu.tscn")
var _cash_node = preload("res://Nodes/Ui/CashBox.tscn")
var _key_node = preload("res://Nodes/Ui/KeyCount.tscn")
var _shop_node = preload("res://Nodes/Ui/Shop/ShopUI.tscn")
var _storage_node = preload("res://Nodes/Ui/Storage.tscn")
var _save_node = preload("res://Maps/SaveSelect.tscn")
onready var cash = _cash_node.instance()
onready var key = _key_node.instance()
onready var _black_bars = _black_bars_node.instance()
var menuFlavorShader = preload("res://Shaders/MenuFlavors.tres")
var battleTransitionNode = preload("res://Nodes/Ui/Battle/Battle Transition.tscn")
var battleBGs = {}
var queuedBattle = false
var battleWinCutscene = ""
var battleFleeCutscene = ""
var battleLoseCutscene = ""
var battleWinFlag = ""
var battleRematchFlag = ""
var battleLoseHeal = ""
var queueSetCrumbs = false

var _fixed_camera

var commandsMenu
var commandsMenuActive = false
var uiActive = false
var fade = null
var stableCanvasLayer = null
var uiStack = []
var onScreenEnemies = []
var dialogueBox


#Menu flavor colors, First is Border, Second is Darker Border, Third is InnerBorder, Fourth is Interior and Fifth is Highlight
var menuFlavors = {
	"Plain": ["f3f2f4", "bfb4cd", "7a6c86", "141117", "ba53e4", "d6cedf", "332943"],
	"Mint": ["a9fff1", "4ca8b0", "5d6fa5", "230c24", "945ffa", "69c3c4", "36182e"],
	"Strawberry": ["ffa2b5", "e47089", "b8425a", "361115", "2fc05c", "ee8399", "4f1e15"],
	"Banana": ["ffd152", "d4722c", "ad552f", "220a07", "d85123", "e08b37", "3c1a14"],
	"Peanut": ["fa8a52", "c2473c", "993131", "33161a", "c92727", "d86146", "432822"],
	"Grape": ["eab3ff", "a669c6", "304280", "171b32", "de3995", "b97ed6", "2e2743"],
	"Melon": ["81e06e", "4bb367", "963948", "29101c", "ff4f75", "a8c469", "362126"]
}


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var canvasLayerNode = load("res://Nodes/Ui/mainCanvasLayer.tscn")
	
	set_menu_flavors(globaldata.menuFlavor)
	
	#load all the battle bgs
	load_battle_bgs()
	
	if stableCanvasLayer == null:
		stableCanvasLayer = canvasLayerNode.instance()
		global.currentScene.add_child(stableCanvasLayer)
		global.add_persistent(stableCanvasLayer)
		add_to_canvas(_black_bars, 0)
		add_to_canvas(cash, 1)
		add_to_canvas(key, 2)
	
	if fade == null:
		var transitionNode = load("res://Nodes/Ui/effects/Fade.tscn")
		var transition = transitionNode.instance()
		transition.set_name("fade")
		stableCanvasLayer.add_child(transition)
		fade = transition

func set_menu_flavors(flavor):
	for i in 7:
		menuFlavorShader.set_shader_param("NEWCOLOR%s" % (i+1), Color(menuFlavors[flavor][i]))
	emit_signal("menuFlavorUpdated")

func add_ui(ui, addChild = true):
	uiStack.push_front(ui)
	uiActive = true
	if addChild:
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

func close_item(item): #Calls a function in the menu that closes it
	if item.has_method('close'):
		item.close()
	else:
		item.queue_free()

func open_dialogue_box():
	dialogueBox = _dialogue_box_node.instance()
	add_ui(dialogueBox)
	commandsMenuActive = false
	return dialogueBox


func check_keys(scene): #Returns the amount of keys collected in a scene. If you can't collect keys in a scene, it returns -1 
	if globaldata.keys.has(scene):
		return globaldata.keys[scene]
	else:
		return -1

func open_commands_menu():
	global.persistPlayer.pause()
	commandsMenu = _commands_menu_node.instance()
	add_ui(commandsMenu)
	commandsMenuActive = true

func close_commands_menu(keep_pause = false, remove_bars = false):
	audioManager.music_muffle(0, 0)
	remove_ui(commandsMenu)
	commandsMenuActive = false
	commandsMenu.queue_free()
	if !keep_pause:
		global.persistPlayer.unpause()
	if remove_bars:
		toggle_black_bars(false)

func toggle_black_bars(show):
	_black_bars.toggle(show)

func start_battle(type = 0, canRun = true):
	if global.inBattle:
		return
	global.persistPlayer.pause()
	queuedBattle = true
	
	
	# hoooo boy this is gonna be some funky code right here.
	var root = get_tree().root
	var battleui = _battle_menu_node.instance()
	
	# add enemies to battle and an enemyTransition sprite
	for enemy in onScreenEnemies:
#		enemy[1].set_physics_process(false)
		if enemy[1] != null:
			if enemy[1].get("eventRayCaster") != null and !enemy[1].drafted:
				enemy[1].eventRayCaster.look_at(global.persistPlayer.global_position + global.persistPlayer.get_node("CollisionShape2D").position * 2)
				if enemy[1].eventRayCaster.get_collider() == global.persistPlayer:
					enemy[1].emotes.hide()
					enemy[1].emotes.frame = 0
					battleui.add_enemy(enemy[0], enemy[1])
			else:
				enemy[1].emotes.hide()
				enemy[1].emotes.frame = 0
				battleui.add_enemy(enemy[0], enemy[1])
				enemy[1].drafted = false
		else:
			battleui.add_enemy(enemy[0], enemy[1])
	
	# set the bg and music to the strongest enemy
	var bg = battleBGs["lamp"]
	var musicIntro = ""
	var music = ""
	
	var firstEnemy = battleui.enemyBPs[0]
	if firstEnemy.stats.get("bg") != null:
		if firstEnemy.stats.bg in battleBGs:
			bg = battleBGs[firstEnemy.stats.bg]
	if "musicintro" in firstEnemy.stats:
		musicIntro = firstEnemy.stats.musicintro
	if "music" in firstEnemy.stats:
		music = firstEnemy.stats.music
	# add selected music to battle
	battleui.music = music
	battleui.musicIntro = musicIntro
	
	# and adjust advantages
	match type:
		1:
			battleui.playerAdv = true
		2:
			battleui.enemyAdv = true
	
	battleui.canRun = canRun
	
	if global.currentCamera.shaking:
		yield(global.currentCamera, "stoped_shaking")
	
	#set battle BG, a layer below to be solely caught by backbuffer
	var battleBG = CanvasLayer.new()
	battleBG.add_child(bg.instance())
	battleBG.layer = -1
	add_ui(battleBG)
	battleui.battleBG = battleBG
	
	
	#and lastly, add to UI canvas
	print("add battle")
	add_ui(battleui)
	
	# THEN a back buffer copy to the root, right before the current scene
	# This captures the BG as the SCREEN_TEXTURE, which is used by the transition shader
	var backBuffer = BackBufferCopy.new()
	backBuffer.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	root.add_child(backBuffer)
	root.move_child(backBuffer, root.get_children().size() - 2)
	
	# add the transition ui, keep at the end of the draw order. So it draws on top of everything else
	var transition = battleTransitionNode.instance()
	transition.battleui = battleui
	root.add_child(transition)
	# Set the position to the VIEWPORT POSITION (aka, so it lines up with the camera)
	transition.position = -get_viewport().canvas_transform.origin
	
	
	var transparency = 130
	match type:
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
	# move BG to its expected layer 
	transition.connect("done", battleBG, "set", ["layer", 1])
#	transition.connect("done", battleui, "start")
	queuedBattle = false


#updates enemy ids
func update_enemy_ids():
	for enemy in onScreenEnemies:
		if enemy[1].has_method("updateId"):
			enemy[1].updateId(onScreenEnemies.find(enemy))

func add_to_canvas(node, layer=0):
	stableCanvasLayer.add_child(node)
	if layer != -1:
		stableCanvasLayer.move_child(node, layer)

func load_battle_bgs():
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

func scene_changed():
	if check_keys(global.currentScene.name) <= 0:
		key.close()
	else:
		key.open()

func open_shop(shop):
	var shopui = _shop_node.instance()
	shopui.shopJsonName = shop
	commandsMenuActive = false
	add_ui(shopui)

func open_storage(god_mode = false):
	var storageui = _storage_node.instance()
	storageui.god_mode = god_mode
	commandsMenuActive = false
	add_ui(storageui)

func open_atm():
	var atmui = _atm_menu_node.instance()
	commandsMenuActive = false
	add_ui(atmui)

func open_save():
	var saveui = _save_node.instance()
	commandsMenuActive = false
	saveui.state = 1
	saveui.index = globaldata.saveFile
	add_ui(saveui)

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
	var gameOver = _game_over_node.instance()
	add_ui(gameOver)
	yield(gameOver, "fade_done")
