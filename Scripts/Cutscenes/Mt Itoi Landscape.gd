extends Control

var currentText = 0
var finished = true
var t = 0
var textSpeed = 0.08
var text = [
	"The year is 1988.",
	"Outside Podunk, a small town in America."
]

onready var dialogueLabel = $Text/HBoxContainer/ScrollingText

func _ready():
	global.persistPlayer.pause()
	reset_text()
	$Timer.connect("timeout", self, "set_process", [true])
	yield(get_tree().create_timer(1), "timeout")
	$AnimationPlayer.play("Introduction")
	$Blackbars.open()

func _process(delta):
	if !finished:
		var spacelessTest = get_spaceless_string(dialogueLabel.text)
		t += delta
		if t > textSpeed:
			dialogueLabel.visible_characters += 1
			t = 0
			if $AudioStreamPlayer.stream != null:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85,1.0))
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
		$AnimationPlayer.stop()
		Input.action_release("ui_select")
		_on_AnimationPlayer_animation_finished("Introduction")

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

func play_sound(sound, name):
	audioManager.play_sfx(load(sound), name)

func _on_AnimationPlayer_animation_finished(anim_name):
	$Objects/Door.enter()
	global.start_playtime()
