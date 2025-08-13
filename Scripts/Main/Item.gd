tool

extends "res://Scripts/Main/ItemHolder.gd"

export (bool) var reset_when_consumed := false

func _ready():
	hide()
	if is_inside_tree():
		_update_sprite()
	if !Engine.is_editor_hint():
		if _get_flag_status():
			queue_free()
			return
		global.persistPlayer.connect("paused", self, "_on_player_paused")
		global.persistPlayer.connect("unpaused", self, "_on_player_unpaused")
	yield(get_tree(), "idle_frame")
	show()
	
func _set_item(t_item):
	item = t_item
	_update_sprite()

func _update_sprite():
	if is_inside_tree():
		var path := str("res://Graphics/Objects/Items/%s.png" % item)
		var directory = Directory.new()
		var doesFileExist = directory.file_exists(path)
		if doesFileExist or !Engine.is_editor_hint():
			$Sprite.texture = load(path)
		else:
			$Sprite.texture = load("res://Graphics/Objects/Items/Error.png")

func _unparent_button_prompt():
	var button_prompt_node = get_node(button_prompt)
	button_prompt_node.show_button()
	if button_prompt_node.visible:
		button_prompt_node.press_button()
		button_prompt_node.connect("hide", button_prompt_node, "queue_free")
		$interact.remove_child(button_prompt_node)
		get_parent().add_child(button_prompt_node)
		button_prompt_node.position = position + button_prompt_node.offset
	else:
		button_prompt_node.queue_free()
	
# Override
func _check_item():
	._check_item()
	$Tween.start()

func disappear():
	$Timer.start(5)
	if global.persistPlayer.paused:
		_on_player_paused()
	yield($Timer,"timeout")
	$AnimationPlayer.play("blink")
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 2
	$Timer.start(2)
	yield($Timer,"timeout")
	$AnimationPlayer.playback_speed = 3
	$Timer.start(3)
	yield($Timer,"timeout")
	queue_free()

func _on_player_paused():
	$Timer.paused = true

func _on_player_unpaused():
	$Timer.paused = false

# Override
func _play_collect_item():
	_unparent_button_prompt()
	$Tween.interpolate_property(self, "global_position",
		global_position, global.persistPlayer.global_position, 0.3, 
		Tween.TRANS_QUART,Tween.EASE_OUT,0.045)
	$Tween.interpolate_property(self, "scale",
		Vector2(0.7,1.3), Vector2(0.5,0), 0.20, 
		Tween.TRANS_QUAD,Tween.EASE_IN)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	queue_free()

# Override
func _play_revert():
	if item:
		$Tween.interpolate_property($Sprite, "rotation_degrees", 30, 0, 1, Tween.TRANS_ELASTIC,Tween.EASE_OUT)

func _exit_tree():
	if reset_when_consumed:
		_set_flag_status(false)
		
