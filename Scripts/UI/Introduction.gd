extends Control

var currentText = 0
var finished = true
var t = 0
var textSpeed = 0.08
# LOCALIZATION Use of csv keys for story text ("In the early 1900's, a dark shadow" etc.)
var text = [
	"INTRO_CUTSCENE_OLD_01", 
	"INTRO_CUTSCENE_OLD_02", 
	"INTRO_CUTSCENE_OLD_03", 
	"INTRO_CUTSCENE_OLD_04", 
	"INTRO_CUTSCENE_OLD_05", 
	"INTRO_CUTSCENE_OLD_06", 
	"INTRO_CUTSCENE_OLD_07", 
	"INTRO_CUTSCENE_OLD_08", 
	"INTRO_CUTSCENE_OLD_09", 
	"INTRO_CUTSCENE_OLD_10", 
	"INTRO_CUTSCENE_OLD_11", 
	"INTRO_CUTSCENE_OLD_12"
]

onready var dialogueLabel = $Text/HBoxContainer/ScrollingText

# Called when the node enters the scene tree for the first time.
func _ready():
	global.persistPlayer.pause()
	dialogueLabel.visible_characters = 0
	dialogueLabel.text = ""
	$Timer.connect("timeout", self, "set_process", [true])
	yield(get_tree().create_timer(2), "timeout")
	$AnimationPlayer.play("Introduction")

func _process(delta):
	for i in 5:
		var path = "Images/Intro_" + var2str(i)
		get_node(path).rect_position = round_vector(get_node(path).rect_position)
	if !finished:
		var spacelessTest = get_spaceless_string(dialogueLabel.text)
		t += delta
		if t > textSpeed:
			dialogueLabel.visible_characters += 1
			t = 0
			$AudioStreamPlayer.play()
			if get_last_visible_character(dialogueLabel) in tr("INTRO_CUTSCENE_PUNCTUATION") and dialogueLabel.visible_characters < len(spacelessTest):
				$Timer.start()
				set_process(false)
		if dialogueLabel.visible_characters >= len(spacelessTest):
			finished = true
			dialogueLabel.visible_characters = len(spacelessTest)
			t = 0
func _physics_process(delta):
	if Input.is_action_just_pressed("ui_select") and $AnimationPlayer.is_playing():
		Input.action_release("ui_select")
		$AnimationPlayer.stop()
		stop_music()
		_on_AnimationPlayer_animation_finished("Introduction")

func round_vector(pos):
	pos.x = round(pos.x)
	pos.y = round(pos.y)
	return pos

func get_last_visible_character(label):
	var spacelessText = label.text.replace(" ", "")
	spacelessText = spacelessText.replace("\n", "")
	return(spacelessText.left(label.visible_characters).replace(spacelessText.left(label.visible_characters - 1), ""))

func get_spaceless_string(string):
	return string.replace(" ", "").replace("\n", "")
	

func hide_text():
	$Tween.interpolate_property(dialogueLabel, "rect_position:y",
		dialogueLabel.rect_position.y, -36, 0.5,
		Tween.TRANS_LINEAR,Tween.EASE_OUT)
	$Tween.start()

func reset_text():
	dialogueLabel.text = ""
	dialogueLabel.visible_characters = 0
	# LOCALIZATION Code change: Fixed bug where vertical alignment sometimes wasn't happening when it was a 2-line paragraph twice in a row
	dialogueLabel.rect_position.y = (dialogueLabel.get_parent().rect_size.y - dialogueLabel.rect_size.y) / 2
	finished = true

func next_text():
	reset_text()
	set_process(true)
	if dialogueLabel.text != "":
		dialogueLabel.text += "\n"
	# LOCALIZATION Code change: Added tr() for direct access to the translated string
	# (to handle string length and punctuation timing in _process())
	dialogueLabel.text += _snap_text_to_tiles(tr(text[currentText]))
	finished = false
	currentText += 1
	
# LOCALIZATION Made monospace text look "NES-like" while being centered (snap to 8x8 tiles)
func _snap_text_to_tiles(string):
	var splitString = string.split("\n")
	for i in splitString.size():
		if splitString[i].length() % 2 == 1:
			splitString[i] += " " # Same parity in length makes centering look good
	return splitString.join("\n")

func slow_down_text():
	textSpeed = 0.15

func reset_text_speed():
	textSpeed = 0.08


func stop_music():
	audioManager.fadeout_all_music(5)

func _on_AnimationPlayer_animation_finished(anim_name):
	$Objects/Door.enter()
