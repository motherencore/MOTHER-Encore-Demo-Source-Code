extends NinePatchRect

signal back (accept, current_action, current_character, target_character, current_item)

onready var arrow = $arrow
onready var confirmation_label = $ConfirmationLabel

var current_character = "ninten"
var target_character = "ninten"
var current_action = "give"
var back_action = "back"
var current_item = -1

var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	
func Show_confirmation_select(pos, curr_action, back_act, cur_char, target_char, item_idx):
	# LOCALIZATION Code added: Moving all these boxes to the left if it gets out of screen
	var offscreen_part = rect_global_position.x + rect_size.x - get_viewport_rect().size.x
	if offscreen_part > 0:
		var tween = Tween.new()
		var parentMenu = find_parent("ActionSelect")
		parentMenu.add_child(tween)
		tween.interpolate_property(parentMenu, "rect_position:x", null, parentMenu.rect_position.x - offscreen_part, .1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()

	current_action = curr_action
	# LOCALIZATION Code change: Made it translatable
	# LOCALIZATION Use of csv keys
	if curr_action == "equipgive":
		confirmation_label.text = "INVENTORY_ACTION_EQUIP_CONFIRM"
	else:
		confirmation_label.text = "INVENTORY_ACTION_%s_CONFIRM" % curr_action.to_upper()

	current_item = item_idx
	back_action = back_act
	current_character = cur_char
	target_character = target_char
	visible = true
	active = true
	arrow.on = true
	
	

func _physics_process(_delta):
	if active:
		_inputs()


func _inputs():
	if Input.is_action_just_pressed("ui_cancel"):
		Input.action_release("ui_cancel")
		visible = false
		active = false
		arrow.on = false
		emit_signal("back", false, back_action, current_character, target_character, current_item)
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		visible = false
		active = false
		arrow.on = false
		emit_signal("back", arrow.cursor_index == 0, current_action, current_character, target_character, current_item)
		
