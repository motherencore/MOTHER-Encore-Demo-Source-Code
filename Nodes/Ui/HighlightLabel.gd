extends Label


onready var highlighter = get("custom_styles/normal")
var oldColor
var oldModulate
var blinking := false
var blink_state := 0.5

var uid := 0


# Called when the node enters the scene tree for the first time.
func _ready():
	oldColor = highlighter.bg_color
	oldModulate = self_modulate
	uiManager.connect("menuFlavorUpdated", self, "setColor")
	highlighter = highlighter.duplicate()
	self.set('custom_styles/normal', highlighter)
	setColor()
	highlighter.bg_color.a = 0

func setColor():
	var highlightValue = highlighter.bg_color.a
	for i in ["1", "2", "3", "4", "5"]:
		if str(oldModulate) == str(uiManager.menuFlavorShader.get_shader_param("OLDCOLOR" + i)):
			self_modulate = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR" + i)
		if str(oldColor) == str(uiManager.menuFlavorShader.get_shader_param("OLDCOLOR" + i)):
			highlighter.bg_color = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR" + i)
	highlight(highlightValue)

func set_self_modulate(color):
	self_modulate = color
	for i in ["1", "2", "3", "4", "5"]:
		if str(color) == str(uiManager.menuFlavorShader.get_shader_param("OLDCOLOR" + i)):
			self_modulate = uiManager.menuFlavorShader.get_shader_param("NEWCOLOR" + i)

func highlight(val):
	highlighter.bg_color.a = val

func blink(val):
	blinking = val
	if val:
		start_blinking()
	else:
		$Tween.stop_all()
		highlighter.bg_color.a = 0

func start_blinking():
	if blinking and !$Tween.is_active():
		$Tween.interpolate_property(highlighter, "bg_color:a",
			0.8, 0.5, 0.3,
			Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		$Tween.interpolate_property(highlighter, "bg_color:a",
			0.5, 0.8, 0.3,
			Tween.TRANS_LINEAR,Tween.EASE_IN_OUT, 0.3)
		$Tween.start()

func show_equiped(val: bool):

	if get_node_or_null("Equiped_spr"):
		$Equiped_spr.visible = val

