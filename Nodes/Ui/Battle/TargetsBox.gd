extends BattleMenuBox

export(NodePath) var nameBox
export(NodePath) var bgDarkinator

enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

var partyBPs = []
var enemyBPs = []

const _targetables = []
var _target_type
var _target_all = false
onready var _pointer = get_node("TargetPointer")
var _pointer_index = 0

var _sound_effects = {
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3")
}

func _ready():
	nameBox = get_node_or_null(nameBox)
	bgDarkinator = get_node_or_null(bgDarkinator)

func _process(delta):
	if visible:
		if !_target_all and _targetables.size() > 1:
			var direction = controlsManager.get_controls_vector(true).x
			
			if direction != 0 and _pointer.get_node("Timer").time_left == 0:
				pointer_move(direction)
				_pointer.get_node("Timer").start()
				return

func _input(event):
	if visible:
		if event.is_action_pressed("ui_accept"):
			get_tree().set_input_as_handled()
			_pointer_select()

func enter(reset = false, _action = null):
	.enter(reset, _action)
	_targetables.clear()
	_target_all = _action.targetType in [TargetType.ALL_ENEMIES, TargetType.ALL_ALLIES]
	_target_type = _action.targetType
	match(_action.targetType):
		TargetType.ENEMY:
			_targetables.append_array(_get_all_targetable(enemyBPs, _action.targetUnconscious))
		TargetType.ALL_ENEMIES:
			_targetables.append_array(_get_all_targetable(enemyBPs, _action.targetUnconscious))
		TargetType.SELF:
			_targetables.append_array([action.user])
		TargetType.ALLY:
			_targetables.append_array(_get_all_targetable(partyBPs, _action.targetUnconscious))
		TargetType.ALL_ALLIES:
			_targetables.append_array(_get_all_targetable(partyBPs, _action.targetUnconscious))
	
	_targetables.sort_custom(self, "_sort_targetables")

	if reset:
		if _action.targetType == TargetType.ENEMY:
			_pointer_index = (_targetables.size() - 1) / 2
		else:
			_pointer_index = 0
		nameBox.show()
		darken_bg()
		if _target_all:
			var i = 0
			for target in _targetables:
				var nextPointer = _create_or_get_pointer(i)
				nextPointer.show()
				nextPointer.get_node("AnimationPlayer").play("point")
				nextPointer.rect_position = target.battleSprite.rect_global_position - _pointer.rect_size/2
				target.select()
				i += 1
			get_parent().tilt_bars(_targetables[i - 1].battleSprite.rect_global_position + _targetables[i - 1].battleSprite.rect_size/2)
		else:
			_targetables[_pointer_index].select()
			_pointer.show()
			_pointer.get_node("AnimationPlayer").play("point")
			_pointer.rect_position = _targetables[_pointer_index].battleSprite.rect_global_position - _pointer.rect_size/2
			get_parent().tilt_bars(_targetables[_pointer_index].battleSprite.rect_global_position + _targetables[0].battleSprite.rect_size/2)

	_name_box_refresh()

func _sort_targetables(bp1, bp2):
	return bp1.battleSprite.rect_global_position < bp2.battleSprite.rect_global_position

func darken_bg():
	bgDarkinator.play("darken")

func undarken_bg():
	bgDarkinator.play("undarken")

func hide():
	.hide()
	nameBox.hide()
	undarken_bg()
	for p in get_children():
		if p.has_method("hide"):
			p.hide()
	for target in _targetables:
		target.deselect()
	get_parent().tilt_bars(Vector2(160, 90))

func _create_or_get_pointer(num):
	if num >= get_child_count():
		var newPointer = _pointer.duplicate()
		add_child(newPointer)
		return newPointer
	else:
		return get_child(num)

func _get_all_targetable(bpArray, target_unconscious):
	var arr = []
	for bp in bpArray:
		if target_unconscious or bp.isConscious():
			arr.append(bp)
	return arr

func pointer_move(dir):
	if dir != 0:
		audioManager.play_sfx(_sound_effects["cursor1"], "cursor")
	_targetables[_pointer_index].deselect()
	if dir == -1 and _pointer_index == 0:
		_pointer_index = _targetables.size() - 1
	elif dir == 1 and _pointer_index == _targetables.size() - 1:
		_pointer_index = 0
	else:
		_pointer_index = clamp(_pointer_index + dir, 0, _targetables.size() - 1)
	var selected = _targetables[_pointer_index]
	selected.select()
	get_parent().tilt_bars(selected.battleSprite.rect_global_position + selected.battleSprite.rect_size/2)
	_pointer.get_node("Tween").interpolate_property(_pointer, "rect_position",
		_pointer.rect_position, selected.battleSprite.rect_global_position - _pointer.rect_size/2, 0.2,
		Tween.TRANS_QUART,Tween.EASE_OUT)
	_pointer.get_node("Tween").start()
	_name_box_refresh()

func _pointer_select():
	audioManager.play_sfx(_sound_effects["cursor2"], "cursor")
	if _target_all:
		action.targets = _targetables
	else:
		action.targets = [_targetables[_pointer_index]]
	emit_signal("next")

func _name_box_refresh():
	match _target_type:
		TargetType.ENEMY:
			nameBox.get_child(0).text = _targetables[_pointer_index].get_name()
		TargetType.ALL_ENEMIES:
			nameBox.get_child(0).text = "BATTLE_TARGET_ALL_ENEMIES"
		TargetType.SELF:
			nameBox.get_child(0).text = action.user.get_name()
		TargetType.ALLY:
			nameBox.get_child(0).text = _targetables[_pointer_index].get_name()
		TargetType.ALL_ALLIES:
			nameBox.get_child(0).text = "BATTLE_TARGET_ALL_ALLIES"
