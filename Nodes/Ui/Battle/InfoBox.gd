extends NinePatchRect

export (NodePath) onready var desc_label = get_node(desc_label) as Control
export (NodePath) onready var tween = get_node(tween) as Tween

export var _hide_offset := Vector2(0, 60)

var _is_active := false
var _is_visible := true
var _init_pos: Vector2

func _ready():
	_init_pos = rect_position

func _input(event):
	if _is_active and event.is_action_pressed("ui_scope"):
		if _is_visible:
			hide_info()
		else:
			show_info()
		_is_visible = !_is_visible

func activate():
	show()
	_is_active = true
	if _is_visible:
		show_info()

func deactivate():
	_is_active = false
	hide_info()

func is_visible() -> bool:
	return _is_visible

func hide_info():
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "rect_position", \
		rect_position, _init_pos + _hide_offset, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func show_info():
	tween.stop_all()
	tween.remove_all()
	tween.interpolate_property(self, "rect_position", \
		rect_position, _init_pos, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func update_info(text: String):
	desc_label.set_text(text)

func update_item(item):
	if item:
		desc_label.set_item_from_inv(item)
	else:
		desc_label.set_item_from_inv(null)
