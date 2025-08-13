extends CanvasLayer

onready var _arrow = $menu/Commands/Arrow
onready var _cash_box = $menu/Commands/Bottom/Cash
onready var _animation_player = $AnimationPlayer
var _party_info_view = uiManager.party_info_view

var _active
var _visible

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
	_active = true
	_visible = true
	_cash_box.get_node("Amount").text = var2str(globaldata.cash)
	_animation_player.play("open")
	_party_info_view.update_party_infos()
	_party_info_view.open()
	audioManager.play_sfx(soundEffects["menu_open2"], "menu_open")
	uiManager.toggle_black_bars(true)
	audioManager.music_muffle(0, 1)
	yield(_animation_player, "animation_finished")
	_arrow.on = true

func _physics_process(delta):
	if _active:
		if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_select"):
			_close_menu()

func create_stats_menu():
	var statsMenuTemplate = load("res://Nodes/Ui/stats menu.tscn")#"res://Nodes/Ui/stats menu.tscn"
	var statsMenu = statsMenuTemplate.instance()
	uiManager.stableCanvasLayer.add_child(statsMenu)
	_deactivate()

func _deactivate():
	_arrow.on = false
	audioManager.music_muffle(0, 2)
	audioManager.play_sfx(soundEffects["menu_open"], "menu_open")
	_active = false
	uiManager.close_key_indicator()

func _activate():
	_arrow.on = true
	audioManager.music_muffle(0, 1)
	audioManager.play_sfx(soundEffects["menu_close"], "menu_close")
	_active = true
	_party_info_view.open()
	uiManager.update_key_indicator()

func _on_InventoryUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_EquipMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_StatsMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_PSIMenuUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_MapScreen_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_OptionsUI_back():
	#audioManager.play_sfx(soundEffects["back"], "cursor")
	_activate()

func _on_close_to_title():
	_close_menu(false, true)

func _on_Arrow_selected(cursor_index):
	Input.action_release("ui_accept")
	_deactivate()
	match cursor_index:
		0: #Goods
			$InventoryUI.open(global.party[0])
		1: #PSI
			$PSIMenuUI.show_PSIMenu()
		2: #Equip
			_party_info_view.close()
			$EquipMenuUI.open(global.party[0])
		3: #Status
			_party_info_view.close()
			$StatsMenuUI.Show_stats(global.party[0])
		4: #Map
			$MapScreen.slide_name()
		5: #Options
			_party_info_view.close()
			$OptionsUI.Show_options()
	
func _close_menu(unpause_player := true, leave_to_title := false):
	if _visible:
		_visible = false
		_active = false
		_arrow.on = false
		audioManager.play_sfx(soundEffects["menu_close2"], "menu_close")
		uiManager.toggle_black_bars(false)
		_party_info_view.close()
		_animation_player.play("Close")
		if !leave_to_title:
			yield(_animation_player, "animation_finished")
			uiManager.close_commands_menu(!unpause_player, true)
		else:
			_deactivate()

func _on_InventoryUI_exit():
	_close_menu(false)
