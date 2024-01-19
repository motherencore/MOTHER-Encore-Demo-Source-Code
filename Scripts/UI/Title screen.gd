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
	label.text = "Originally Produced by"
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
		
#	set_physics_process(false)
#	yield(get_tree(), "idle_frame")
#	set_physics_process(true)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		if canSkip:
			if $CanvasLayer/AnimationPlayer.current_animation != "Fade" and \
			   $CanvasLayer/AnimationPlayer.current_animation != "Skip Fade":
				$CanvasLayer/AnimationPlayer.play("Skip Fade")
		elif $CanvasLayer/Title/PressButton.modulate == Color.white:
			show_menu()
			audioManager.play_sfx(soundEffects["cursor2"], "cursor")

func _physics_process(delta):
	if active:
		if Input.is_action_just_pressed("ui_down"):
			option += 1
			optionChanged()
			audioManager.play_sfx(soundEffects["cursor1"], "cursor")
		elif Input.is_action_just_pressed("ui_up"):
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
					$Objects/Door2.enter()
				1:
					$Objects/Door3.enter()
				2:
					global.save_settings()
					get_tree().quit()
		


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
			option = 2
		3:
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
			label.text = "Originally Presented by"
		"itoi":
			animationPlayer.play("Team Encore")
			label.text = "Presented by"
		"Team Encore":
			$CanvasLayer/Aboveground/Base.hide()
			animationPlayer.play("Fade")
		#"Fade":
		#	canSkip = false

func show_menu():
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
