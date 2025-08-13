tool

extends "res://Scripts/Main/ItemHolder.gd"

export (String, "item", "map", "briefcase") var type setget _set_type

func _ready():
	_update_sprite()
	if !Engine.is_editor_hint():
		if _get_flag_status():
			$Sprite.frame = 4
			_update_state()
		if dialog == "":
			dialog = "ItemDescriptions/presentcheck"
		if dialog_full == "":
			dialog_full = "ItemDescriptions/presentfull"
		if dialog_empty == "":
			dialog_empty = "ItemDescriptions/presentempty"

func _set_type(sprite):
	type = sprite
	_update_sprite()

func _update_sprite():
	if is_inside_tree():
		match type:
			"item":
				get_node("Sprite").texture = load("res://Graphics/Objects/Present Box.png")
			"map":
				get_node("Sprite").texture = load("res://Graphics/Objects/Present Box Blue.png")
			"briefcase":
				get_node("Sprite").texture = load("res://Graphics/Objects/Briefcase.png")

# Override
func _update_state():
	if _get_flag_status():
		$Sparkles.stop()
		$Sparkles.hide()
	else:
		$Sparkles.show()
		$Sparkles.play()

# Override
func _play_interact():
	$AnimationPlayer.play("Unwrapped")

# Override
func _play_collect_item():
	pass

# Override
func _play_revert():
	yield($AnimationPlayer,"animation_finished")
	$AnimationPlayer.play("Wrapped")
