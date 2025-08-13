extends Control

enum { MUSIC, FILTER, MORE_FILTER }

const BUSES = ["Music", "Filter", "More Filter"]
const SILENT_SOUND_THRESHOLD = -80

onready var _tween := $Tween

var musicChangers := []
var overworldBattleMusic := false

func _ready():
	_add_at_zero()

func set_overworld_battle_music(enabled):
	overworldBattleMusic = enabled

func _get_audio_player_count() -> int:
	return $AudioPlayers.get_child_count()

func add_audio_player():
	var music_player = AudioStreamPlayer.new()
	music_player.bus = BUSES[MUSIC]
	$AudioPlayers.add_child(music_player)

func get_audio_player(id: int) -> AudioStreamPlayer:
	if id >= $AudioPlayers.get_child_count():
		return null 
	return $AudioPlayers.get_child(id) as AudioStreamPlayer

func get_audio_player_name(id: int = get_latest_audio_player_index()):
	var music_player = get_audio_player(id)
	if music_player:
		return music_player.name

func get_audio_player_from_song(song, excludedChanger = null):
	if song != "":
		if excludedChanger != null:
			for musicChanger in musicChangers:
				var audioPlayer = musicChanger.attachedPlayer
				if audioPlayer.stream == load("res://Audio/Music/" + song) and musicChanger != excludedChanger:
					return audioPlayer
		else:
			for audioPlayer in audioManager.get_audio_player_list():
				if audioPlayer.stream == load("res://Audio/Music/" + song):
					return audioPlayer
	return null

func get_audio_player_index(node) -> int:
	return get_audio_player_list().find(node)

func get_audio_player_list() -> Array:
	return $AudioPlayers.get_children()

#remove a music player with an id
func remove_audio_player(id: int):
	var music_player = get_audio_player(id)
	_remove_audio_player_obj(music_player)

func remove_audio_player_by_name(name: String):
	var music_player = $AudioPlayers.get_node_or_null(name)
	_remove_audio_player_obj(music_player)

func _remove_audio_player_obj(music_player: AudioStreamPlayer):
	if music_player != null:
		music_player.queue_free()
		yield(music_player, "tree_exited")
		_add_at_zero()

func _add_at_zero():
	if _get_audio_player_count() == 0:
		add_audio_player()

func get_latest_audio_player_index():
	return _get_audio_player_count() - 1

#track is the song's name, loop is the song to play on loop, music_player is which audioPlayer to play the song from and start is the position to start the song from.
func play_music(track, loop = "", index = 0, start = 0.0):
	var music_player = get_audio_player(index)
	if music_player != null:
		var path = ""
		if track == "":
			path = "res://Audio/Music/" + loop
		elif track == "AoOni.mp3":
			path = "res://Nodes/Overworld/Enemies/AoOni.mp3"
		else:
			path = "res://Audio/Music/" + track
		var musicFile = load(path)
		music_player.stream = musicFile
		music_player.play(start)
		
		if music_player.is_connected("finished", self, "play_music"):
			music_player.disconnect("finished", self, "play_music")
		if loop != "" and !music_player.is_connected("finished", self, "play_music"):
			music_player.connect("finished", self, "play_music", ["", loop, index, 0.0], CONNECT_DEFERRED)
		else:
			music_player.connect("finished", self, "_remove_audio_player_obj", [music_player], CONNECT_ONESHOT)

func play_music_on_latest_player(track, loop = "", start = 0.0, name = ""):
	play_music(track, loop, get_latest_audio_player_index(), start)

func music_muffle(index, level):
	var music_player = get_audio_player(index)
	if music_player != null:
		music_player.bus = BUSES[level]

func set_audio_pitch(speed):
	for soundEffect in $Sfx.get_children():
		soundEffect.pitch_scale = speed

func music_fadeout(index, duration = 1):
	var music_player = get_audio_player(index)
	_music_fadeout_obj(music_player, duration)

func music_fadeout_by_name(name: String, duration = 1):
	var music_player = $AudioPlayers.get_node_or_null(name)
	_music_fadeout_obj(music_player, duration)

func _music_fadeout_obj(music_player: AudioStreamPlayer, duration = 1):
	if music_player != null:
		if music_player.playing:
			_tween.remove(music_player)
			_tween.interpolate_property(music_player, "volume_db", 
				music_player.volume_db, SILENT_SOUND_THRESHOLD, duration,
				_tween.TRANS_QUART, _tween.EASE_IN)
			_tween.start()
			yield(_tween, "tween_all_completed")
			_remove_all_unplaying()


func music_fadein_by_name(name: String, volume, duration = 1):
	var music_player = $AudioPlayers.get_node_or_null(name)
	_music_fadein_obj(music_player, volume, duration)

func music_fadein(index, volume, duration = 1):
	var music_player = get_audio_player(index)
	_music_fadein_obj(music_player, volume, duration)

func _music_fadein_obj(music_player: AudioStreamPlayer, volume, duration = 1):
	if music_player != null:
		_tween.remove(music_player)
		_tween.interpolate_property(music_player, "volume_db", 
		SILENT_SOUND_THRESHOLD, volume, duration,
		_tween.TRANS_QUART,_tween.EASE_OUT)
		_tween.start()

func music_fadeto(index, volume = 0, duration = 1):
	var music_player = get_audio_player(index)
	if music_player != null:
		if music_player.volume_db != volume:
			_tween.remove(music_player)
			_tween.interpolate_property(music_player,"volume_db", 
				music_player.volume_db, volume, duration,
				_tween.TRANS_LINEAR,_tween.EASE_IN_OUT)
			_tween.start()

func set_audio_player_volume(index, volume):
	var music_player = get_audio_player(index)
	_set_audio_player_volume_obj(music_player, volume)

func set_audio_player_volume_by_name(name: String, volume):
	var music_player = $AudioPlayers.get_node_or_null(name)
	_set_audio_player_volume_obj(music_player, volume)

func _set_audio_player_volume_obj(music_player: AudioStreamPlayer, volume):
	if music_player != null:
		music_player.volume_db = volume

func fadeout_all_music(duration):
	_tween.remove_all()
	for i in _get_audio_player_count():
		music_fadeout(i, duration)

func stop_audio_player(index):
	var music_player = get_audio_player(index)
	if music_player != null:
		_stop_audio_player_obj(music_player)
	else:
		push_warning("Audio player %s was not found" % index)

func stop_audio_player_by_name(name: String):
	var music_player = $AudioPlayers.get_node_or_null(name)
	_stop_audio_player_obj(music_player)

func _stop_audio_player_obj(music_player: AudioStreamPlayer):
	if music_player.is_connected("finished", self, "play_music"):
		music_player.disconnect("finished", self, "play_music")
	music_player.playing = false

func stop_all_music():
	for music_player in get_audio_player_list():
		music_player.playing = false
	_remove_all_unplaying()

func pause_all_music():
	if _tween.is_active():
		_tween.seek(_tween.tell() + _tween.get_runtime())
		_remove_all_unplaying(true)
		_tween.stop_all()
	for music_player in get_audio_player_list():
		music_player.stream_paused = true

func resume_all_music():
	for music_player in get_audio_player_list():
		music_player.stream_paused = false

func _remove_all_unplaying(wait_for_tween = false):
	for i in _get_audio_player_count():
		var music_player = get_audio_player(i)
		if music_player:
			if music_player and !music_player.playing or music_player.volume_db <= SILENT_SOUND_THRESHOLD:
				_remove_player_after_tween(music_player, wait_for_tween)

func _remove_player_after_tween(music_player: AudioStreamPlayer, wait_for_tween = false):
	if wait_for_tween and _tween.is_active():
		yield(_tween, "tween_all_completed")
	_remove_audio_player_obj(music_player)

func get_playing(song) -> bool:
	var is_song_playing = false
	if get_audio_player_from_song(song) != null:
		is_song_playing = true
	return is_song_playing

func add_sfx(stream, name) -> AudioStreamPlayer:
	var sfx_node: AudioStreamPlayer = get_sfx(name)
	if !sfx_node:
		sfx_node = AudioStreamPlayer.new()
		sfx_node.bus = "SFX"
		sfx_node.name = name
		$Sfx.add_child(sfx_node)
	sfx_node.stream = stream
	return sfx_node

func play_sfx(stream, name) -> AudioStreamPlayer:
	var sfx_node: AudioStreamPlayer = add_sfx(stream, name)
	sfx_node.play()
	return sfx_node

func get_sfx(name) -> AudioStreamPlayer:
	return $Sfx.get_node_or_null(name) as AudioStreamPlayer
