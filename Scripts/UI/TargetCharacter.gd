extends NinePatchRect

signal back (to_inventory)
signal show_statsbar (character)
signal hide_statsbar
signal next

onready var item_label_template = preload("res://Nodes/Ui/HighlightLabel.tscn")

const arrow_move_offset_y = 14

#onready var arrow = $MarginContainer
#onready var ConfirmationSelect = $ConfirmationSelect
#onready var arrow_init_pos = arrow.position

var current_character = "ninten"
var current_item = -1
var other_characters_list = []
var other_characters_nickname_list = []
var max_item_rows = 4

onready var arrow = $arrow2
var active = false
var selected_item_nb = 0

var character_list = []

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false
	arrow.connect("selected", self, "_on_select")
	arrow.connect("cancel", self, "_on_cancel")
	arrow.connect("moved", self, "_on_move")
	

#clear the list before filling it again
func _empty_list():
	var labels = $MarginContainer/VBoxContainer.get_children()
	for label in labels:
		label.queue_free()

func set_list(characters):
	character_list = characters

#process data to update the available character list	
func _update_character_list():
	#get the current party list
	var full_list = character_list # sorted list is needed here
	var party = global.party
	var name_list = []
	other_characters_list.clear()
	other_characters_nickname_list.clear()
	#creating the character list by comparing the party with the full ordered list
	for name in full_list:
		for character in party:
			if character["name"].to_lower() == name or name == "all":
				name_list.append(character.name.to_lower())
				other_characters_nickname_list.append(character.nickname)
	#remove current character which is giving something
	
	other_characters_list = name_list
	max_item_rows = other_characters_list.size()
	
	
	_empty_list()
	
	yield(get_tree(), "idle_frame")
	
	#display the list as several labels
	for chara_name in other_characters_nickname_list:
		var label = item_label_template.instance()
		label.text = chara_name
		$MarginContainer/VBoxContainer.add_child(label)
	
	arrow.on = true
	arrow.set_cursor_from_index(0, false)
	arrow.turn_on_highlight()
#	rect_size = Vector2(rect_size.x, sizeOffset + $MarginContainer/VBoxContainer.rect_size.y)

#used to make the box appear with the right parameters
func Show_target_chara_select(pos, cur_char):
	selected_item_nb = 0
	current_character = cur_char
	_update_character_list()
	visible = true
	active = true
	
	emit_signal("show_statsbar", other_characters_list[selected_item_nb])


func _on_move(dir):
	if !active:
		return
	if dir.y == -1:
		selected_item_nb -=1
		if selected_item_nb < 0:
			selected_item_nb = max_item_rows-1
		emit_signal("show_statsbar", other_characters_list[selected_item_nb])
	elif dir.y == 1:
		selected_item_nb +=1
		if selected_item_nb == max_item_rows:
			selected_item_nb = 0
		emit_signal("show_statsbar", other_characters_list[selected_item_nb])

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
	emit_signal("next")

func _on_VBoxContainer_resized():
	$MarginContainer.set_size(Vector2(0, 0))
	rect_size.y = $MarginContainer.rect_size.y

func get_character():
	return other_characters_list[selected_item_nb]
