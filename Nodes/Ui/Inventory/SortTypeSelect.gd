extends NinePatchRect

signal back (accept, current_action, current_character, target_character, current_item)


onready var arrow = $arrow
onready var SortTypeLabel = $SortTypeLabel

var current_character = "ninten"
var target_character = "ninten"
var current_action = "give"
var current_item = -1

var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	pass
	
func Show_confirmation_select(pos, curr_action, cur_char, target_char, item_idx):
	current_action = curr_action
	current_item = item_idx
	current_character = cur_char
	target_character = target_char
	visible = true
	active = true
	arrow.on = true
	_on_VBoxContainer_resized()
	

func _physics_process(_delta):
	if active:
		_inputs()


func _inputs():
	if Input.is_action_just_pressed("ui_cancel"):
		Input.action_release("ui_cancel")
		visible = false
		active = false
		arrow.on = false
		emit_signal("back", false, "back", current_character, target_character, current_item)
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		visible = false
		active = false
		arrow.on = false
		if arrow.cursor_index == 0:
			emit_signal("back", true, "SortManual", current_character, target_character, current_item)
		else:
			emit_signal("back", false, "SortAuto", current_character, target_character, current_item)
		
	
func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.x = $MarginContainer.rect_size.x
	#rect_size.y = $MarginContainer.rect_size.y
	_move_to_fit()

func _move_to_fit():
	var offscreen_part = rect_global_position.x + rect_size.x - get_viewport_rect().size.x
	if offscreen_part > 0:
		var tween = Tween.new()
		var parentMenu = find_parent("ActionSelect")
		parentMenu.add_child(tween)
		tween.interpolate_property(parentMenu, "rect_position:x", null, parentMenu.rect_position.x - offscreen_part, .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
