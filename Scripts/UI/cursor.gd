extends AnimatedSprite

export var menu_parent_path : NodePath
export var cursor_offset : Vector2
export var cursor_size = Vector2(8, 8)
export var on = false
export var consume_input_events = false
export var loop_around = false
export var skip_empty_labels = false
export var skip_hidden_items = false
export var highlight = false
export var move_sfx = false
export var select_sfx = false
export var cancel_sfx = false
export var cancel_on = false
export var reset_on_show = true

onready var menu_parent = get_node_or_null(menu_parent_path)
var audioPlayerId = -1

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
}

var cursor_index : int = 0
var input := Vector2.ZERO

signal moved(dir)
signal failed_move(dir)
signal selected(cursor_index)
signal cancel()

func _ready():
	menu_parent = get_node_or_null(menu_parent_path)
	set_cursor_from_index(0, false)
	if highlight:
		if visible:
			turn_on_highlight()
		connect("visibility_changed", self, "turn_on_highlight")
		connect("visibility_changed", self, "unhighlight")
		

func _input(event):
	if is_active():
		if event.is_action_pressed("ui_accept"):
			var current_menu_item := get_menu_item_at_index(cursor_index)
			if current_menu_item != null:
				if select_sfx:
					play_sfx('cursor2')
				emit_signal("selected", cursor_index)
			if consume_input_events:
				Input.action_release("ui_accept")
				get_tree().set_input_as_handled()
		
		elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
			if cancel_on:
				if cancel_sfx:
					play_sfx('back')
				emit_signal("cancel")
				if consume_input_events:
					Input.action_release("ui_cancel")
					Input.action_release("ui_toggle")
					get_tree().set_input_as_handled()
		
func _physics_process(delta):
	if is_active():
		input = Vector2.ZERO
		if Input.is_action_just_pressed("ui_left") \
		or Input.is_action_just_pressed("ui_dpad_left") \
		or Input.is_action_just_pressed("ui_lstick_left") \
		or Input.is_action_just_pressed("ui_rstick_left") \
		or Input.is_action_just_pressed("ui_key_left"):
			input.x -= 1
		if Input.is_action_just_pressed("ui_right") \
		or Input.is_action_just_pressed("ui_dpad_right") \
		or Input.is_action_just_pressed("ui_lstick_right") \
		or Input.is_action_just_pressed("ui_rstick_left") \
		or Input.is_action_just_pressed("ui_key_right"):
			input.x += 1
		if Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_dpad_up") \
		or Input.is_action_just_pressed("ui_lstick_up") \
		or Input.is_action_just_pressed("ui_rstick_up") \
		or Input.is_action_just_pressed("ui_key_up"):
			input.y -= 1
		if Input.is_action_just_pressed("ui_down") \
		or Input.is_action_just_pressed("ui_dpad_down") \
		or Input.is_action_just_pressed("ui_lstick_down") \
		or Input.is_action_just_pressed("ui_rstick_down") \
		or Input.is_action_just_pressed("ui_key_down"):
			input.y += 1
		
		if input != Vector2.ZERO and $Timer.time_left == 0:
			var old_index = cursor_index
			var index: int
			var dir: int
			# assign index and input dir based on container
			if menu_parent is VBoxContainer:
				input.x = 0
				index = int(cursor_index + input.y)
				dir = int(input.y)
			elif menu_parent is HBoxContainer:
				input.y = 0
				index = int(cursor_index + input.x)
				dir = int(input.x)
			elif menu_parent is GridContainer:
				var row = int(cursor_index/menu_parent.columns)
				var column = cursor_index - row * menu_parent.columns
				if column == menu_parent.columns - 1 and input.x == 1:
					if loop_around:
						index = cursor_index - menu_parent.columns + 1
						input.x = -1
						dir = int(input.x + input.y)
				elif column == 0 and input.x == -1:
					if loop_around:
						index = cursor_index + menu_parent.columns - 1
						input.x = 1
						dir = int(input.x + input.y)
				else:
					index = cursor_index + input.x + input.y * menu_parent.columns
					dir = int(input.x + input.y)
			# process direction to validate idx
			if dir != 0:
				if dir > 0:
					index = _idx_or_next_valid_idx(index)
				elif dir < 0:
					index = _idx_or_prev_valid_idx(index)
				set_cursor_from_index(index)
			
			
			if cursor_index != old_index:
				if move_sfx:
					play_sfx('cursor1')
				emit_signal("moved", input)
			else:
				emit_signal("failed_move", input)

func is_active():
	return on and (menu_parent is VBoxContainer or menu_parent is HBoxContainer or menu_parent is GridContainer)

func turn_on_highlight():
	if highlight and get_menu_item_at_index(cursor_index) != null:
		if get_menu_item_at_index(cursor_index).has_method("highlight") and visible:
			get_menu_item_at_index(cursor_index).highlight(1)

func unhighlight():
	if highlight:
		for i in menu_parent.get_child_count():
			if get_menu_item_at_index(i)!= null:
				if get_menu_item_at_index(i).has_method("highlight"):
					get_menu_item_at_index(i).highlight(0)

func get_visible_menu_items():
	var visible_items = []
	for i in menu_parent.get_children():
		if i.visible:
			visible_items.append(i)
	return visible_items

func get_menu_item_at_index(index : int) -> Control:
	if menu_parent == null:
		return null
	
	if index >= menu_parent.get_child_count() or index < 0:
		return null
	
	# next, we check if there is valid indexes ahead
	var validIdx = _idx_or_next_valid_idx(index)
	if validIdx == -1:
		#last, we check if there is valid indexes behind
		validIdx = _idx_or_next_valid_idx(index)
		if validIdx == -1:
			return null
	
	return menu_parent.get_child(validIdx) as Control

func set_cursor_from_index(index : int, transition = true) -> void:
	
	if menu_parent == null:
		return
	# try to fix index preemptively lol
	
	index = _idx_or_next_valid_idx(index)
	if index >= menu_parent.get_child_count():
		return
	if index < 0:
		return
	var menu_item := get_menu_item_at_index(index)
	# if there is any problem, try to recalculate the idx
	if menu_item == null:
		return
	cursor_index = index
	
	var size = cursor_size
	size.y = size.y/2.0
	size.x = -size.x/6.0
	
	unhighlight()
	turn_on_highlight()
	
	var new_position = menu_item.rect_global_position + cursor_offset + size
#	var size = menu_item.rect_size
	
	if transition:
		$Tween.interpolate_property(self, "global_position",
			global_position, new_position, 0.1,
			Tween.TRANS_QUART,Tween.EASE_OUT)
		if frames == null:
			$Tween.interpolate_property(self, "scale",
				Vector2(0.8,1.2), Vector2(1.3,0.7), 0.1,
				Tween.TRANS_QUART,Tween.EASE_OUT)
			$Tween.interpolate_property(self, "scale",
				Vector2(1.3,0.7), Vector2(0.8, 1.2), 0.03,
				Tween.TRANS_QUART,Tween.EASE_OUT, 0.1)
			$Tween.interpolate_property(self, "scale",
				Vector2(0.8, 1.3), Vector2(1,1), 0.03,
				Tween.TRANS_QUART,Tween.EASE_OUT, 0.13)
		$Tween.start()
		$Timer.start()
	else:
		$Tween.remove_all()
		scale = Vector2.ONE
		global_position = new_position

func get_max():
	var i = 0
	for child in menu_parent.get_children():
		var toAdd = 1
		if skip_hidden_items:
			if "visible" in child and !child.visible:
				toAdd = 0
		if skip_empty_labels:
			if child is Label and child.text == "":
				toAdd = 0
		i += toAdd
	return i

func set_cursor_to_front():
	var j = -1
	for i in menu_parent.get_child_count():
		if skip_hidden_items:
			var item = menu_parent.get_child(i)
			if "visible" in item and !item.visible:
				continue
		if skip_empty_labels:
			var label = menu_parent.get_child(i)
			if label is Label and label.text == "":
				continue
		j = i
		break
	
	if j == -1:
		return
	set_cursor_from_index(j, false)
	if menu_parent != null:
		var size = cursor_size
		size.y = size.y/2.0
		size.x = -size.x/6.0
		global_position = menu_parent.rect_global_position + cursor_offset + size

func _idx_or_next_valid_idx(index):
	if menu_parent == null:
		return -1
	elif index >= menu_parent.get_child_count() or index < 0:
		return -1
	else:
		for i in range(index, menu_parent.get_child_count()):
			var item = menu_parent.get_child(i)
			if skip_hidden_items:
				if "visible" in item and !item.visible:
					continue
			if skip_empty_labels:
				if item is Label and item.text == "":
					continue
			return i
	return -1

func _idx_or_prev_valid_idx(index):
	if menu_parent == null:
		return -1
	elif index >= menu_parent.get_child_count() or index < 0:
		return -1
	else:
		for i in range(index, -1, -1):
			var item = menu_parent.get_child(i)
			if skip_hidden_items:
				if "visible" in item and !item.visible:
					continue
			if skip_empty_labels:
				if item is Label and item.text == "":
					continue
			return i
	return -1

func play_sfx(sfx):
	var stream = soundEffects[sfx]
	audioManager.play_sfx(stream, "cursor")


func get_closest_menu_item_index(newParent):
	var closest = 0
	for i in newParent.get_child_count():
		var closestItem = newParent.get_child(closest)
		var newItem = newParent.get_child(i)
		if global_position.distance_to(closestItem.rect_global_position + closestItem.rect_size / 2) > global_position.distance_to(newItem.rect_global_position + closestItem.rect_size / 2 ):
			closest = i
	return closest

func get_farthest_menu_item_index(newParent):
	var farthest = 0
	for i in newParent.get_child_count():
		var farthestItem = newParent.get_child(farthest)
		var newItem = newParent.get_child(i)
		if global_position.distance_to(farthestItem.rect_global_position + farthestItem.rect_size / 2) < global_position.distance_to(newItem.rect_global_position + farthestItem.rect_size / 2 ):
			farthest = i
	return farthest

func change_parent(newParent, play_sfx = true, closest_index = true):
	var index
	if closest_index:
		index = get_closest_menu_item_index(newParent)
	else:
		index = get_farthest_menu_item_index(newParent)
	menu_parent = newParent
	set_cursor_from_index(index, true)
	if play_sfx:
		play_sfx('cursor1')

func _on_arrow_visibility_changed():
	if reset_on_show:
		cursor_index = 0
		set_cursor_from_index(0, false)
