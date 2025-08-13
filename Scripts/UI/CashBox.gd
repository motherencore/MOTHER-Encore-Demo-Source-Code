extends CanvasLayer

export var _source_value := "cash"
export (NodePath) onready var _container = get_node(_container) as Node
export (NodePath) onready var _anim_player = get_node(_anim_player) as AnimationPlayer
export (NodePath) onready var _amount_label = get_node(_amount_label) as Label

var _is_open := false

func open():
	update()
	if !_is_open:
		_container.margin_left = _container.margin_right
		_anim_player.play("Open")
		_is_open = true

func update():
	_amount_label.text = var2str(globaldata.get(_source_value))

func close():
	if _is_open:
		_anim_player.play("Close")
		_is_open = false
