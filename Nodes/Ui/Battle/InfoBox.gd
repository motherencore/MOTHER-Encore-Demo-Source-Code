extends NinePatchRect

export (NodePath) onready var desc_label = get_node(desc_label) as RichTextLabel
export (NodePath) onready var tween = get_node(tween) as Tween

export var hideOffset = Vector2(0, 60)

var active = false
var infoOnScreen = true
var infoScreenPosition

func _ready():
	infoScreenPosition = rect_position

func _input(event):
	if active and event.is_action_pressed("ui_scope"):
		if infoOnScreen:
			# go off screen
			hide_info()
		else:
			#go on screen
			show_info()
		infoOnScreen = !infoOnScreen

func activate():
	show()
	active = true
	if infoOnScreen:
		show_info()

func deactivate():
	active = false
	hide_info()

func hide_info():
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "rect_position", \
		rect_position, infoScreenPosition + hideOffset, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func show_info():
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "rect_position", \
		rect_position, infoScreenPosition, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func update_info(text):
	desc_label.bbcode_text = text 
