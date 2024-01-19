extends Control

export(float) var textSpeed = 0.01

# node refs
onready var dialogueLabel = $ClipBox/Dialogue
onready var dotLabel = $ClipBox/DippinDots

#dialog and timing vars
var dialog := {}
var phraseNum = 0
var finished = true
var t = 0
var select = 0
var selected = 0
var currPhrase := {}
var methodTarget = self

var autoAdvanced = true
var autoAdvanceDelay = 1.25

#dialog signals
signal done

func _ready():
	dialogueLabel.bbcode_text = ""
	dotLabel.bbcode_text = ""

func _process(delta):
	if !finished:
		t += delta
		$Cursor_Down.hide()
		if t > textSpeed:
			t -= textSpeed
			dialogueLabel.visible_characters += 1
		if dialogueLabel.visible_characters >= len(dialogueLabel.text):
			t = 0
			finished = true
			$Cursor_Down.show()
	elif autoAdvanced:
		t += delta
		if t > autoAdvanceDelay:
			advanced()
			t = 0
func _physics_process(delta):
	if select > 0:
		if dialogueLabel.visible_characters == len(dialogueLabel.text):
			$Arrow.show()
			$Options.show()
			$Cursor_Down.hide()
			if selected != 0:
				if Input.is_action_just_pressed("ui_left"):
					$Arrow.position.x  -=  64
					selected = selected - 1
			if selected != (select - 1):
				if Input.is_action_just_pressed("ui_right"):
					$Arrow.position.x  +=  64
					selected = selected + 1
	else:
		selected = 0
		$Arrow.hide()
		$Options.hide()

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
		advanced()

func advanced():
	if finished:
		if currPhrase.has("goto"):
			phraseNum = str2var(currPhrase["goto"])
			nextPhrase()
		elif currPhrase.has("options"):
			if Input.is_action_just_pressed("ui_accept"):
				var option = currPhrase["options"].keys()[selected]
				phraseNum = str2var(currPhrase["options"][option]["goto"])
				for i in get_node("Options").get_children():
					get_node("Options").remove_child(i)
				dialogueLabel.bbcode_text = ""
				dotLabel.bbcode_text = ""
				dialogueLabel.visible_characters = 0
				nextPhrase()
			elif (Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle")) and currPhrase.has("cancel"):
				phraseNum = str2var(currPhrase["cancel"])
				for i in get_node("Options").get_children():
					get_node("Options").remove_child(i)
				dialogueLabel.bbcode_text = ""
				dotLabel.bbcode_text = ""
				dialogueLabel.visible_characters = 0
				nextPhrase()
		else:
			end()
	else:
		dialogueLabel.visible_characters = len(dialogueLabel.text)
		t = 0
		finished = true
		$Cursor_Down.show()

func start(_dialog = null):
	reset()
	show()
	$AnimationPlayer.play("RESET")
	if _dialog != null:
		dialog = _dialog
	
	dialogueLabel.visible_characters = 0
	nextPhrase()

func nextPhrase():
	$Arrow.position = Vector2(104,43)
	currPhrase = dialog[str(phraseNum)]
	
	select = 0
	finished = false
	
	if phraseNum == 0:
		dialogueLabel.remove_line(1)
		dotLabel.remove_line(1)

	if currPhrase["text"] != "":
		dialogueLabel.bbcode_text += "\n" + currPhrase["text"]
		
		# add dot, assuming no options on this
		dotLabel.bbcode_text += "\n@"
		adjustDotSpacing(currPhrase["text"])
	
	# Parse Commands
	if currPhrase.has("commands"):
		for command in currPhrase["commands"]:
			if methodTarget.has_method(command.method):
				methodTarget.call(command.method, command.param)
	
	if currPhrase.has("font"):
		if currPhrase["font"] == "EBZ":
			$ClipBox/Dialogue.add_font_override("font",load("res://Fonts/saturn.tres"))
	
	# Parse Options
	if currPhrase.has("options"):
		dialogueLabel.bbcode_text += "\n"
		dotLabel.bbcode_text += "\n"
		var optionNode = load("res://Nodes/Ui/DialogueOptions.tscn")
		select = currPhrase["options"].size()
		$Arrow.position.x = $Arrow.position.x / select
		for i in currPhrase["options"]:
			var option = optionNode.instance()
			get_node("Options").add_child(option)
			option.text = i
			option.set_name(i)
	
	if currPhrase.has("soundeffect"):
		$SoundEffect.stream = load("res://Audio/Sound effects/" + currPhrase["soundeffect"])
		$SoundEffect.play()

func adjustDotSpacing(line):
	var font = dialogueLabel.get_font("normal_font")
	var lineSize = font.get_wordwrap_string_size(line, dialogueLabel.rect_size.x)
	if lineSize.y > font.get_height():
		dotLabel.bbcode_text += "\n".repeat(int(floor(lineSize.y/font.get_height()) - 1))

func reset():
	dialog = {}
	finished = true
	t = 0
	select = 0
	selected = 0
	phraseNum = 0
	currPhrase = {}
	dialogueLabel.bbcode_text = ""
	dotLabel.bbcode_text = ""
	methodTarget = self
	set_process(true)
	set_process_input(true)

func end():
	set_process(false)
	set_process_input(false)
	hide()
	emit_signal("done")

func playWin():
	show()
	$AnimationPlayer.play("YouWin")
