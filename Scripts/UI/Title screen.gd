extends Control

const CREDITS_STEPS = 3

onready var animationPlayer = $CanvasLayer/AnimationPlayer
onready var label = $CanvasLayer/Aboveground/Base/IntroTexts/Label
var active = false
var canSkip = false
var seq = ""

var option = 0
var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3")
}


func _ready():
	global.persistPlayer.pause()

	# LOCALIZATION Use of csv key for "Originally Produced by"
	label.text = "TITLE_INTRO_1"
	
	$CanvasLayer/Title/Earth.playing = true
	if audioManager.get_audio_player(audioManager.get_latest_audio_player_index()).stream != load("res://Audio/Music/Mother Earth.mp3"):
		audioManager.fadeout_all_music(0.2)
		audioManager.add_audio_player()
		audioManager.play_music_on_latest_player("", "Mother Earth.mp3")
		animationPlayer.play("intro1")
		canSkip = true
	else:
		animationPlayer.play("Instant Start")
		
	_update_text()
	global.connect("locale_changed", self, "_update_text")
	global.connect("inputs_changed", self, "_update_text")
#	set_physics_process(false)
#	yield(get_tree(), "idle_frame")
#	set_physics_process(true)

func _update_text():
	var pressText = "[center]%s[/center]" % TextTools.replace_text("MENU_PRESS")
	$CanvasLayer / Title / PressButton.bbcode_text = pressText

	$CanvasLayer / Title / Version2.text = tr("TITLE_FNKEYS").format([TextTools.get_key_name("ui_fullscreen", global.KEYBOARD), TextTools.get_key_name("ui_winsize", global.KEYBOARD)])

func _input(event):
	for action in InputMap.get_actions():
		if Input.is_action_just_pressed(action):
			seq += action.substr(3, 2)
			if !active and !canSkip and seq.ends_with(globaldata.LANG_ALT):
				global.set_language("pr")
			break
	
	if event.is_action_pressed("ui_accept"):
		if canSkip:
			if $CanvasLayer/AnimationPlayer.current_animation != "Fade" and \
			   $CanvasLayer/AnimationPlayer.current_animation != "Skip Fade":
				$CanvasLayer/AnimationPlayer.play("Skip Fade")
		elif $CanvasLayer/Title/PressButton.modulate == Color.white:
			_show_menu()
			audioManager.play_sfx(soundEffects["cursor2"], "cursor")
	
	if OS.is_debug_build():
		if active:
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
				audioManager.fadeout_all_music(1)
				Input.action_release("ui_cancel")
				Input.action_release("ui_toggle")
				$Objects/DoorToDebug.enter()

func _physics_process(delta):
	if active:
		var input = controlsManager.get_controls_vector(true)
		
		if input.y > 0:
			option += 1
			optionChanged()
			audioManager.play_sfx(soundEffects["cursor1"], "cursor")
		elif input.y < 0:
			option -= 1
			optionChanged()
			audioManager.play_sfx(soundEffects["cursor1"], "cursor")
		
		if Input.is_action_just_pressed("ui_accept"):
			audioManager.play_sfx(soundEffects["cursor2"], "cursor")
			active = false
			match(option):
				0:
					audioManager.fadeout_all_music(0.5)
					set_saveFile()
					globaldata.reset_data()
					$Objects/DoorToNewGame.enter()
				1:
					$Objects/DoorToSaveSelect.enter()
				2:
					#$OptionsUI.Show_options()
					$Objects/DoorToSettings.enter()
				3:
					global.save_settings()
					get_tree().quit()
		
		if OS.is_debug_build() and Input.is_action_just_pressed("ui_cancel"):
			$Objects/DoorToDebug.enter()


func _on_OptionsUI_back():
	audioManager.play_sfx(soundEffects["back"], "cursor")
	active = true

func set_saveFile():
	var saveGame = File.new()
	var newSave = 1
	for num in 10:
		if saveGame.file_exists("user://saveFile" + var2str(num) + ".save"):
			newSave += 1
	if newSave > 10:
		newSave = 10
	globaldata.saveFile = newSave

func optionChanged():
	match(option):
		-1:
			option = 3
		4:
			option = 0
		
	for i in $CanvasLayer/Title/Menu.get_child_count():
		var flash = $CanvasLayer/Title/Menu.get_child(i).get_material()
		if i == option:
			flash.set_shader_param("flash_modifier", 0.35)
		else:
			flash.set_shader_param("flash_modifier", 0)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	for i in range(1, CREDITS_STEPS):
		if anim_name == "intro%s" % i:
			animationPlayer.play("intro%s" % (i + 1))
			label.text = "TITLE_INTRO_%s" % (i + 1)
			var swap_array = tr("TITLE_INTRO_SWAP_LINES").split(",")
			if i < swap_array.size() and swap_array[i]:
				_swap_credit_layout()

	if anim_name == "intro%s" % CREDITS_STEPS:
		$CanvasLayer/Aboveground/Base.hide()
		animationPlayer.play("Fade")

func _swap_credit_layout():
	var container = $CanvasLayer/Aboveground/Base/IntroTexts
	var node_to_move = container.get_child(1)
	container.move_child(node_to_move, 0)

func _show_menu():
	if globaldata.saveFile != 0:
		option = 1
	optionChanged()
	$CanvasLayer/Title/Menu.show()
	$Tween.interpolate_property($CanvasLayer/Title/PressButton, "modulate",
		$CanvasLayer/Title/PressButton.modulate, Color.transparent, 0.2)
	$Tween.interpolate_property($CanvasLayer/Title/Menu, "modulate",
		Color.transparent, Color.white, 0.25,
		Tween.TRANS_LINEAR,Tween.EASE_IN_OUT, 0.2)
	$Tween.start()
	yield($Tween,"tween_completed")
	$CanvasLayer/Title/PressButton.hide()
	active = true
	

func _show_button():
	$Tween.interpolate_property($CanvasLayer/Aboveground/Base, "modulate",
		$CanvasLayer/Aboveground/Base.modulate, Color.transparent, 0.5)
	$Tween.start()
	yield($Tween,"tween_completed")
	$CanvasLayer/Title/PressButton.show()
	$Tween.interpolate_property($CanvasLayer/Title/PressButton, "modulate",
		Color.transparent, Color.white, 0.5)
	$Tween.start()
	canSkip = false
