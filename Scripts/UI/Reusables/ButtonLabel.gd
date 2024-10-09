extends HBoxContainer

export var show_on_press = false

func _ready():
	if show_on_press:
		modulate = Color.transparent

func _input(event):
	if event.is_action_pressed("ui_accept") and show_on_press:
		fadeIn()

func fadeIn():
	if get_node_or_null("Tween") != null:
		$Tween.stop_all()
		$Tween.interpolate_property(self, "modulate",
			modulate, Color.white, 1,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.interpolate_property(self, "modulate",
			Color.white, Color.transparent, 1,
			Tween.TRANS_QUART, Tween.EASE_IN_OUT, 3)
		$Tween.start()
