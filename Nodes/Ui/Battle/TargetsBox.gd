extends "res://Scripts/UI/Battle/BattleMenuBox.gd"

export(NodePath) var nameBox
export(NodePath) var bgDarkinator

enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

const targetables = []
var partyBPs = []
var enemyBPs = []

var targetAll = false
var targetingEnemy = false
onready var pointer = get_node("TargetPointer")
var pointerIndex = 0

var soundEffects = {
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3")
}

func _ready():
	nameBox = get_node_or_null(nameBox)
	bgDarkinator = get_node_or_null(bgDarkinator)

func _input(event):
	if visible:
		if !targetAll and targetables.size() > 1:
			var direction = 0
			if Input.is_action_just_pressed("ui_left"):
				get_tree().set_input_as_handled()
				direction = -1
			elif Input.is_action_just_pressed("ui_right"):
				get_tree().set_input_as_handled()
				direction = 1
			
			if direction != 0 and pointer.get_node("Timer").time_left == 0:
				pointerMove(direction)
				pointer.get_node("Timer").start()
				return
		if event.is_action_pressed("ui_accept"):
			get_tree().set_input_as_handled()
			pointerSelect()

func enter(reset = false, _action = null):
	.enter(reset, _action)
	targetables.clear()
	targetAll = false
	match(int(_action.targetType)):
		TargetType.ENEMY:
			targetables.append_array(get_conscious_of_array(enemyBPs))
			nameBox.get_child(0).text = targetables.front().stats.nickname
		TargetType.ALL_ENEMIES:
			targetAll = true
			targetables.append_array(get_conscious_of_array(enemyBPs))
			nameBox.get_child(0).text = "All Enemies"
		TargetType.SELF:
			targetables.append_array([action.user])
			nameBox.get_child(0).text = action.user.stats.nickname
		TargetType.ALLY:
			targetables.append_array(get_conscious_of_array(partyBPs))
			nameBox.get_child(0).text = targetables.front().stats.nickname
		TargetType.ALL_ALLIES:
			print(partyBPs)
			targetAll = true
			targetables.append_array(get_conscious_of_array(partyBPs))
			nameBox.get_child(0).text = "All Allies"
	if reset:
		pointerIndex = 0
		nameBox.show()
		darken_bg()
		if targetAll:
			var i = 0
			for target in targetables:
				var nextPointer = createOrGetPointer(i)
				nextPointer.show()
				nextPointer.get_node("AnimationPlayer").play("point")
				pointer.rect_position = target.battleSprite.rect_global_position - pointer.rect_size/2
				target.select()
				i += 1
			get_parent().tilt_bars(targetables[i - 1].battleSprite.rect_global_position + targetables[i - 1].battleSprite.rect_size/2)
		else:
			targetables.front().select()
			pointer.show()
			pointer.get_node("AnimationPlayer").play("point")
			pointer.rect_position = targetables[0].battleSprite.rect_global_position - pointer.rect_size/2
			get_parent().tilt_bars(targetables[0].battleSprite.rect_global_position + targetables[0].battleSprite.rect_size/2)

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
	for target in targetables:
		target.deselect()
	get_parent().tilt_bars(Vector2(160, 90))

func createOrGetPointer(num):
	if num >= get_child_count():
		var newPointer = pointer.duplicate()
		add_child(newPointer)
		return newPointer
	else:
		return get_child(num)

func get_conscious_of_array(bpArray):
	var arr = []
	for bp in bpArray:
		if bp.isConscious():
			arr.append(bp)
	return arr

func pointerMove(dir):
	if dir != 0:
		audioManager.play_sfx(soundEffects["cursor1"], "cursor")
	targetables[pointerIndex].deselect()
	if dir == -1 and pointerIndex == 0:
		pointerIndex = targetables.size() - 1
	elif dir == 1 and pointerIndex == targetables.size() - 1:
		pointerIndex = 0
	else:
		pointerIndex = clamp(pointerIndex + dir, 0, targetables.size() - 1)
	var selected = targetables[pointerIndex]
	selected.select()
	get_parent().tilt_bars(selected.battleSprite.rect_global_position + selected.battleSprite.rect_size/2)
	pointer.get_node("Tween").interpolate_property(pointer, "rect_position",
		pointer.rect_position, selected.battleSprite.rect_global_position - pointer.rect_size/2, 0.2,
		Tween.TRANS_QUART,Tween.EASE_OUT)
	pointer.get_node("Tween").start()
	nameBox.get_child(0).text = selected.stats.nickname

func pointerSelect():
	audioManager.play_sfx(soundEffects["cursor2"], "cursor")
	if targetAll:
		action.targets = targetables
	else:
		action.targets = [targetables[pointerIndex]]
	emit_signal("next")
