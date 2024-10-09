extends Control

onready var animationPlayer = $CanvasLayer/AnimationPlayer
onready var label = $CanvasLayer/Aboveground/Base/Label
var active = false
var canSkip = false

var option = 0
var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3")
}


func _ready():
	global.persistPlayer.pause()

	# LOCALIZATION Use of csv key for "Originally Produced by"
	label.text = "TITLE_NINTENDO"
	
	$CanvasLayer/Title/Earth.playing = true
	audioManager.add_at_zero()
	if audioManager.get_audio_player(audioManager.get_audio_player_count() - 1).stream != load("res://Audio/Music/Mother Earth.mp3"):
		audioManager.fadeout_all_music(0.2)
		audioManager.add_audio_player()
		audioManager.play_music_from_id("", "Mother Earth.mp3", audioManager.get_audio_player_count() - 1)
		animationPlayer.play("nintendo")
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
	var pressText = "[center]%s[/center]" % globaldata.replaceText("MENU_PRESS")
	$CanvasLayer / Title / PressButton.bbcode_text = pressText

	$CanvasLayer / Title / Version2.text = tr("TITLE_FNKEYS").format([globaldata.get_key_name("ui_fullscreen", global.KEYBOARD), globaldata.get_key_name("ui_winsize", global.KEYBOARD)])

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if canSkip:
			if $CanvasLayer/AnimationPlayer.current_animation != "Fade" and \
			   $CanvasLayer/AnimationPlayer.current_animation != "Skip Fade":
				$CanvasLayer/AnimationPlayer.play("Skip Fade")
		elif $CanvasLayer/Title/PressButton.modulate == Color.white:
			show_menu()
			audioManager.play_sfx(soundEffects["cursor2"], "cursor")
	
	if OS.is_debug_build():
		if active:
			if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
				audioManager.fadeout_all_music(1)
				Input.action_release("ui_cancel")
				Input.action_release("ui_toggle")
				globaldata.flags["bat"] = true
				globaldata.flags["switch_leader"] = true
				globaldata.flags["eagle_feather"] = true
				#globaldata.ninten["learnedSkills"].append("telepathy")
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
		if i == option:
			var flash = $CanvasLayer/Title/Menu.get_child(i).get_material()
			flash.set_shader_param("flash_modifier", 0.35)
		else:
			var flash = $CanvasLayer/Title/Menu.get_child(i).get_material()
			flash.set_shader_param("flash_modifier", 0)
	
func _on_AnimationPlayer_animation_finished(anim_name):
	match(anim_name):
		"nintendo":
			animationPlayer.play("itoi")
			# LOCALIZATION Use of csv key for "Originally Presented by"
			label.text = "TITLE_ITOI"
		"itoi":
			animationPlayer.play("Team Encore")
			# LOCALIZATION Use of csv key for "Presented by"
			label.text = "TITLE_TEAMENCORE"
		"Team Encore":
			$CanvasLayer/Aboveground/Base.hide()
			animationPlayer.play("Fade")
		#"Fade":
		#	canSkip = false

func show_menu():
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
	

func show_button():
	$Tween.interpolate_property($CanvasLayer/Aboveground/Base, "modulate",
		$CanvasLayer/Aboveground/Base.modulate, Color.transparent, 0.5)
	$Tween.start()
	yield($Tween,"tween_completed")
	$CanvasLayer/Title/PressButton.show()
	$Tween.interpolate_property($CanvasLayer/Title/PressButton, "modulate",
		Color.transparent, Color.white, 0.5)
	$Tween.start()
	canSkip = false
