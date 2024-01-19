extends Node

const endValue = 1

var start_time
var length_ms
var start_value

func _ready():
	set_process(false)
	Engine.time_scale = 1

func start_slowmo(speed, length):
	start_time = OS.get_ticks_msec()
	length_ms = length * 1000
	start_value = speed
	Engine.time_scale = start_value
	set_process(true)

func _process(delta):
	var current_time = OS.get_ticks_msec() - start_time
	var value = circl_ease_in(current_time, start_value, endValue, length_ms)
	if current_time >= length_ms:
		set_process(false)
		value = endValue
	Engine.time_scale = value
	audioManager.set_audio_pitch(value)

func circl_ease_in(t, b, c, d):
	t /= d
	return -c * (sqrt(1 - t * t) - 1) + b
