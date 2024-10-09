extends CanvasLayer

onready var arrow = $menu/Commands/Arrow
onready var cash_box = $menu/Commands/Bottom/Sign
onready var animation_player = $AnimationPlayer

onready var talk
onready var check

var pos = Vector2(0,0)
var active
var unpause = true

var cash_scene = preload("res://Nodes/Ui/CashBoxPause.tscn")

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
	global.connect("locale_changed", self, "_on_locale_changed")
	active = true
	cash_box.get_node("Amount").text = var2str(globaldata.cash)
	animation_player.play("open")
	audioManager.play_sfx(soundEffects["menu_open2"], "menu_open")
	uiManager.toggle_black_bars(true)
	audioManager.music_muffle(0, 1)
	yield(animation_player, "animation_finished")
	arrow.on = true

func _physics_process(delta):
	if active:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_select"):
			close_menu()

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Close" and !active:
		if unpause:
			uiManager.close_commands_menu()


func create_stats_menu():
	var statsMenuTemplate = load("res://Nodes/Ui/stats menu.tscn")#"res://Nodes/Ui/stats menu.tscn"
	var statsMenu = statsMenuTemplate.instance()
	uiManager.stableCanvasLayer.add_child(statsMenu)
	deactivate()

func deactivate():
	arrow.on = false
	audioManager.music_muffle(0, 2)
	audioManager.play_sfx(soundEffects["menu_open"], "menu_open")
	active = false
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.close()

func activate():
	arrow.on = true
	audioManager.music_muffle(0, 1)
	audioManager.play_sfx(soundEffects["menu_close"], "menu_close")
	active = true
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.open()

func _on_InventoryUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_EquipMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_StatsMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_PSIMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_MapScreen_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	activate()

func _on_OptionsUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
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
			$StatsMenuUI.Show_stats(global.party[0])
		4: #Map
			$MapScreen.slide_name()
		5: #Options
			$OptionsUI.Show_options()
	

func _on_locale_changed():
	_reload_cash_box()
	yield(get_tree(), "idle_frame")
	arrow.set_cursor_from_index(arrow.cursor_index)

# Dollar sign before or after the value depending on language
func _reload_cash_box():
	var cash_box_parent = cash_box.get_parent()
	cash_box.free()
	cash_box = cash_scene.instance()
	cash_box_parent.add_child(cash_box)
	cash_box.get_node("Amount").text = var2str(globaldata.cash)

func close_menu(deactivate = true, unpausePlayer = true):
	active = !deactivate
	unpause = unpausePlayer
	if $menu.rect_position.y > -40:
		audioManager.play_sfx(soundEffects["menu_close2"], "menu_close")
		uiManager.toggle_black_bars(false)
		animation_player.play("Close")
	else:
		_on_AnimationPlayer_animation_finished("Close")



func _on_InventoryUI_exit():
	close_menu(true)
