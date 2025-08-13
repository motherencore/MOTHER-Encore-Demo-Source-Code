extends Area2D

export (String) var _music_intro: String
export (String) var _music_loop: String
export (bool) var _start_when_idle := false
export var max_distance: float

const IDLE_DURATION_BEFORE_PLAYING = 0.5
const MAIN_MUSIC_VOLUME_BASE = -20
const MAIN_MUSIC_VOLUME_REDUCTION = -5

var _audio_player_name: String
var _is_playing := false
var _time_idle := 0.0

func _ready():
	$AudioStreamPlayer2D.stream = load("res://Audio/Music/" + _music_loop)
	$AudioStreamPlayer2D.max_distance = max_distance * 1.5
	set_process(false)
	$AudioStreamPlayer2D.volume_db = -80
	$AudioStreamPlayer2D.play()
	

func _on_body_entered(body):
	if _start_when_idle:
		set_process(true)
	else:
		_start_music()

func _on_body_exited(body):
	if _start_when_idle:
		set_process(false)
		_time_idle = 0.0
	if _is_playing:
		_stop_music()

func _process(delta):
	if global.persistPlayer.substantialMovement:
		_time_idle = 0.0
		if _is_playing:
			_stop_music()
	else:
		if !_is_playing:
			_time_idle += delta
			if _time_idle > IDLE_DURATION_BEFORE_PLAYING and !_is_playing:
				_start_music()

func _start_music():
	var main_volume =  min(MAIN_MUSIC_VOLUME_BASE - MAIN_MUSIC_VOLUME_BASE * (global_position.distance_to(global.persistPlayer.global_position) / max_distance), MAIN_MUSIC_VOLUME_REDUCTION)
	print("volume " + str(main_volume))
	print((global_position.distance_to(global.persistPlayer.global_position) / max_distance))
	audioManager.music_fadeto(0, main_volume, 1.5)
	$Tween.stop_all()
	$Tween.interpolate_property($AudioStreamPlayer2D, "volume_db", $AudioStreamPlayer2D.volume_db, 0, 1)
	$Tween.start()
	_is_playing = true

func _stop_music():
	audioManager.music_fadeto(0, 0)
	$Tween.stop_all()
	$Tween.interpolate_property($AudioStreamPlayer2D, "volume_db", $AudioStreamPlayer2D.volume_db, -80, 1)
	$Tween.start()
	_is_playing = false
