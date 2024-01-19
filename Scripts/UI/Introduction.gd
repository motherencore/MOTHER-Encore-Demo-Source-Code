extends Control

var currentText = 0
var finished = true
var t = 0
var textSpeed = 0.08
var text = [
	"In the early 1900's,\na dark shadow covered a small\ncountry town in rural America.",
	"The dark shadow formed\nmysteriously at the\nsummit of Mt Itoi.",
	"At that time,\nnumerous paranormal\nincidents occured.",
	"The last incident\ninvolved the disappearance\nof a young married couple.",
	"The man's name was George.\nThe woman's name was Maria.",
	"As soon as they disappeared,\nso did the dark shadow.",
	"Two years later,\nas suddenly as he left,\nGeorge returned.",
	"He never told anyone\nwhere he had been\nor what he had done.",
	"But he began an odd\nstudy of psychic powers,\nall by himself.",
	"As for Maria,\nhis wife...",
	"She never returned.",
	"80 years have passed\nsince then."
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
			if get_last_visible_character(dialogueLabel) in [",", ".", "!", "?"] and dialogueLabel.visible_characters < len(spacelessTest):
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
	dialogueLabel.rect_position.y = 0
	finished = true

func next_text():
	reset_text()
	set_process(true)
	if dialogueLabel.text != "":
		dialogueLabel.text += "\n"
	dialogueLabel.text += text[currentText]
	finished = false
	currentText += 1
	
func slow_down_text():
	textSpeed = 0.15

func reset_text_speed():
	textSpeed = 0.08


func stop_music():
	audioManager.fadeout_all_music(5)

func _on_AnimationPlayer_animation_finished(anim_name):
	$Objects/Door.enter()
