extends CanvasLayer

onready var arrow = $menu/Commands/Arrow
onready var talk
onready var check

var pos = Vector2(0,0)
var active
var unpause = true

var soundEffects = {
	"menu_open": load("res://Audio/Sound effects/M3/menu_open.wav"),
	"menu_open2": load("res://Audio/Sound effects/M3/menu_open2.wav"),
	"menu_close": load("res://Audio/Sound effects/M3/menu_close.wav"),
	"menu_close2": load("res://Audio/Sound effects/M3/menu_close2.wav"),
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3")
}

func _ready():
	active = true
	set_text()
	$menu/Commands/Sign/Amount.text = var2str(globaldata.cash)
	$AnimationPlayer.play("open")
	audioManager.play_sfx(soundEffects["menu_open2"], "menu_open")
	uiManager.blackBars.animaPlayer.play("Open")
	audioManager.set_audio_player_bus(0, "Filter")
	yield($AnimationPlayer, "animation_finished")
	arrow.on = true

func _physics_process(delta):
	if active:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle") or Input.is_action_just_pressed("ui_select"):
			close_menu()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Close" and !active:
		if unpause:
			uiManager.close_commands_menu(true)


func create_stats_menu():
	var statsMenuTemplate = load("res://Nodes/Ui/stats menu.tscn")#"res://Nodes/Ui/stats menu.tscn"
	var statsMenu = statsMenuTemplate.instance()
	uiManager.stableCanvasLayer.add_child(statsMenu)
	deactivate()

func set_text():
	#$Commands/title/Label.text = globaldata.text["stats"]["commands"]
	#$Commands/Items/Talk.text = globaldata.text["actions"]["talk"]
	#$Commands/Items/Check.text = globaldata.text["actions"]["check"]
	#$Commands/Items/Goods.text = globaldata.text["actions"]["goods"]
	#$Commands/Items/Map.text = globaldata.text["actions"]["map"]
	#$Commands/Items/PSI.text = globaldata.text["actions"]["psi"]
	#$Commands/Items/Stats.text = globaldata.text["actions"]["stats"]
	#$cash/Sign.text = globaldata.text["stats"]["dollarsign"]
	pass

func deactivate():
	arrow.on = false
	audioManager.set_audio_player_bus(0, "More Filter")
	audioManager.play_sfx(soundEffects["menu_open"], "menu_open")
	active = false
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.close()

func activate():
	arrow.on = true
	audioManager.set_audio_player_bus(0, "Filter")
	audioManager.play_sfx(soundEffects["menu_close"], "menu_close")
	active = true
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.open()

func _on_InventoryUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_EquipMenuUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_StatsMenuUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_PSIMenuUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_MapScreen_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_OptionsUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_OptionsUI_closeMenu():
	close_menu(true, false)

func _on_Arrow_selected(cursor_index):
	Input.action_release("ui_accept")
	deactivate()
	match cursor_index:
		0: #Goods
			$InventoryUI.Show_inventory(global.party[0])
		1: #PSI
			$PSIMenuUI.show_PSIMenu()
		2: #Equip
			$EquipMenuUI.Show_equipMenu(global.party[0])
		3: #Status
			$StatsMenuUI.Show_stats()
		4: #Map
			$MapScreen.slide_name()
		5: #Options
			$OptionsUI.Show_options()
	
func close_menu(deactivate = true, unpausePlayer = true):
	active = !deactivate
	unpause = unpausePlayer
	if $menu.rect_position.y != -80:
		audioManager.play_sfx(soundEffects["menu_close2"], "menu_close")
		uiManager.blackBars.animaPlayer.play("Close")
		$AnimationPlayer.play("Close")
	else:
		_on_AnimationPlayer_animation_finished("Close")



func _on_InventoryUI_exit():
	close_menu(true)
