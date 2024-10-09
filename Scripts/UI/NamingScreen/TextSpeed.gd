extends NinePatchRect

var t = 0
var textSpeed = 0.02
var finished = true
onready var dialogueLabel = $VBoxContainer/Fast

func _process(delta):
	if !finished and dialogueLabel != null:
		t += delta
		if t > textSpeed:
			dialogueLabel.visible_characters += 1
			t = 0
		# LOCALIZATION Code change: Animation was left incomplete if the translated text was long
		if dialogueLabel.visible_characters >= len(tr(dialogueLabel.text)):
			finished = true
			dialogueLabel.visible_characters = len(tr(dialogueLabel.text))
			t = 0

func _on_TextSpeedArrow_moved(dir):
	dialogueLabel.percent_visible = 1
	match $TextSpeedArrow.cursor_index:
		0:
			textSpeed = 0.02
			dialogueLabel = $VBoxContainer/Fast
		1:
			textSpeed = 0.03
			dialogueLabel = $VBoxContainer/Medium
		2:
			textSpeed = 0.06
			dialogueLabel = $VBoxContainer/Slow
	
	# LOCALIZATION Code change: Disable animation if the text speed label is too short
	# (Only 3 characters or less in certain languages)
	if !_isAnimationWorthIt():
		dialogueLabel.percent_visible = 1
		finished = true
	else:
		dialogueLabel.percent_visible = 0
		finished = false


func _isAnimationWorthIt():
	return len(tr($VBoxContainer/Fast.text)) > 3 \
		and len(tr($VBoxContainer/Medium.text)) > 3 \
		and len(tr($VBoxContainer/Slow.text)) > 3
