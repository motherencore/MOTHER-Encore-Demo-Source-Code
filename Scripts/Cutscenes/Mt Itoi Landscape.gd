extends Control

var currentText = 0
var finished = true
var t = 0
var textSpeed = 0.08
# LOCALIZATION Use of csv keys for story text ("The year is 1988. Outside Podunk", etc.)
var text = [
	"INTRO_CUTSCENE_NOW_01", 
	"INTRO_CUTSCENE_NOW_02"
]

onready var dialogueLabel = $Text/HBoxContainer/ScrollingText

func _ready():
	global.persistPlayer.pause()
	reset_text()
	$Timer.connect("timeout", self, "set_process", [true])
	yield (get_tree().create_timer(0.8), "timeout")
	$AnimationPlayer.play("Introduction")
	$Blackbars.toggle(true)

func _process(delta):
	if !finished:
		var spacelessTest = _get_spaceless_text(dialogueLabel.text)
		t += delta
		if t > textSpeed:
			dialogueLabel.visible_characters += 1
			t = 0
			if $AudioStreamPlayer.stream != null:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85,1.0))
				$AudioStreamPlayer.play()
			if _get_last_visible_character(dialogueLabel) in tr("INTRO_CUTSCENE_PUNCTUATION") and dialogueLabel.visible_characters < len(spacelessTest):
				$Timer.start()
				set_process(false)
		if dialogueLabel.visible_characters >= len(spacelessTest):
			finished = true
			dialogueLabel.visible_characters = len(spacelessTest)
			t = 0
			$Timer.start()
			set_process(false)
	else:
		# LOCALIZATION Code added: If the last text has finished appearing, we're calling hide_text
		# (Not from the animation because text length may vary between languages)
		if currentText == text.size():
			hide_text()


func _physics_process(delta):
	if Input.is_action_just_pressed("ui_select") and $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
		Input.action_release("ui_select")
		finish_intro()

func _get_last_visible_character(label):
	var spaceless_text = _get_spaceless_text(label.text)
	return spaceless_text[min(label.visible_characters, spaceless_text.length()) - 1]

func _get_spaceless_text(string):
	return string.replace(" ", "").replace("\n", "")

func hide_text():
	$Tween.interpolate_property(dialogueLabel, "rect_position:y",
		dialogueLabel.rect_position.y, -36, 0.5,
		Tween.TRANS_LINEAR,Tween.EASE_OUT)
	$Tween.start()

func reset_text():
	dialogueLabel.text = ""
	dialogueLabel.visible_characters = 0
	dialogueLabel.rect_position.y = 0
	finished = true

func next_text():
	reset_text()
	set_process(true)
	if dialogueLabel.text != "":
		dialogueLabel.text += "\n"
	# LOCALIZATION Code change: Added tr() for direct access to the translated string
	# (to handle string length and punctuation timing in _process())
	var currentTextStr = tr(text[currentText])
	dialogueLabel.text += currentTextStr
	finished = false
	currentText += 1

func play_sound(sound, name):
	audioManager.play_sfx(load(sound), name)

func stop_sound(name):
	if audioManager.get_sfx(name) != null:
		audioManager.get_sfx(name).stop()

func finish_intro():
	stop_sound("teleport")
	$Objects/Door.enter()
	global.start_playtime()

# LOCALIZATION Code added: The finish is handled differently because text length may vary
func _on_Tween_tween_completed(object, key):
	if currentText == text.size(): # If last text
		finish_intro()

