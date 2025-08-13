extends Control

onready var bubble = $Bubble
export var fps = 5
export var loopsBeforeCycle = 4
var status = []
var index = 0

var t = 0.0
var frame = 0
var loops = 0

func _ready():
	bubble.hide()

func _process(delta):
	t += delta
	while(t >= 1.0/fps):
		t -= 1.0/fps
		frame += 1
		if frame == 3:
			frame = 0
			loops += 1
			#rotate status, if we have any
			if loops >= loopsBeforeCycle:
				loops = 0
				if !status.empty():
					rotate_status()
		bubble.frame_coords.x = frame

func set_status_shown(status_to_show):
	var dir = StatusManager.get_ailment_info(status_to_show).get("status_bubble")
	if dir != null:
		bubble.texture = load("res://Graphics/UI/Battle/StatusBubble/" + dir + ".png")
		bubble.show()

func add_status(new_status):
	# we dont deal with unconscious
	if new_status == StatusManager.AILMENT_UNCONSCIOUS:
		return
	var i = status.find(new_status)
	if i > -1:
		return
	status.append(new_status)
	set_status_shown(status[index])

func remove_status(new_status):
	# we dont deal with unconscious
	if new_status == StatusManager.AILMENT_UNCONSCIOUS:
		return
	var i = status.find(new_status)
	if i == -1:
		return
	status.remove(i)
	if status.empty():
		index = 0
		bubble.hide()
	elif i == index:
		index -= 1
		rotate_status()

func rotate_status():
	index = wrapi(index + 1, 0, status.size())
	set_status_shown(status[index])
