extends Control

export (NodePath) onready var _anim_player = get_node(_anim_player) as AnimationPlayer
export (NodePath) onready var _door = get_node(_door) as Area2D
export (NodePath) onready var _container = get_node(_container) as Control
export (NodePath) onready var _player_container_path: NodePath
export (NodePath) onready var _player_label_path: NodePath

func _enter_tree():
	if globaldata.playerName:
		get_node(_player_label_path).text = globaldata.playerName
	else:
		get_node(_player_container_path).hide()

func _ready():
	global.stop_playtime()
	yield(get_tree().create_timer(3), "timeout")
	global.persistPlayer.hide()
	global.persistPlayer.pause()
	_set_scrolling_amount()
	_anim_player.play("Scroll")
	play_music()

func _set_scrolling_amount():
	var credits_height = _container.rect_size.y
	var credits_start_pos = _container.rect_position.y
	var scroll_amount = credits_height + credits_start_pos - 180/2 - 3
	var scroll_animation = _anim_player.get_animation("Scroll")
	print("Credits scroll height: %s" % scroll_amount)
	scroll_animation.track_set_key_value(0, 2, Vector2(0, -scroll_amount))

func play_music():
	audioManager.stop_all_music()
	audioManager.add_audio_player()
	audioManager.play_music_on_latest_player("DemoCredits.mp3", "")
	audioManager.set_audio_player_volume(audioManager.get_latest_audio_player_index(), 12)

func _on_AnimationPlayer_animation_finished(anim_name):
	_door.enter()
