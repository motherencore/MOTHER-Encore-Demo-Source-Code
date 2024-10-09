extends NinePatchRect

signal back (to_inventory)
signal show_statsbar (character)
signal hide_statsbar
signal next (character)

onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

var _char_list = []

onready var arrow = $arrow2
var active = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	arrow.connect("selected", self, "_on_select")
	arrow.connect("cancel", self, "_on_cancel")
	arrow.connect("moved", self, "_on_move")
	

#clear the list before filling it again
func _empty_list():
	var labels = $MarginContainer/VBoxContainer.get_children()
	if labels.empty():
		yield(get_tree(), "idle_frame") # to always return an object
	else:
		for label in labels:
			label.queue_free()
		for label in labels:
			yield(label, "tree_exited")

#process data to update the available character list	
func _refresh_list_view():
	var nickname_list = []
	for name in _char_list:
		if name == "all":
			nickname_list.append("INVENTORY_ACTION_TARGET_ALL")
		else:
			for character in global.party:
				if character["name"] == name:
					nickname_list.append(character.nickname)
			
	yield(_empty_list(), "completed")
	
	#display the list as several labels
	for chara_name in nickname_list:
		var label = item_label_template.instance()
		label.text = chara_name
		$MarginContainer/VBoxContainer.add_child(label)
	
	arrow.on = true
	arrow.set_cursor_from_index(0, false)

#used to make the box appear with the right parameters
func show_target_chara_select(pos, char_list):
	_char_list = char_list
	visible = true
	active = true
	yield(_refresh_list_view(), "completed")
	
	emit_signal("show_statsbar", _char_list[arrow.cursor_index])


func _on_move(dir):
	if active:
		emit_signal("show_statsbar", _char_list[arrow.cursor_index])

func _on_cancel():
	Input.action_release("ui_cancel")
	arrow.on = false
	visible = false
	active = false
	emit_signal("back")
	return
		
func _on_select(idx):
	Input.action_release("ui_accept")
	arrow.on = false
	visible = false
	active = false
	emit_signal("next", _char_list[idx])

# LOCALIZATION Code change: The box also changes size horizontally; yield makes it more reliable
func _on_VBoxContainer_resized():
	yield(get_tree(), "idle_frame")
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.x = $MarginContainer.rect_size.x
	rect_size.y = $MarginContainer.rect_size.y
