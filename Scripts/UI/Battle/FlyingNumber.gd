extends Label


signal done()

func _ready():
	$AnimationPlayer.play("start")
#	pass

# sets tween to move number, as if bouncing off of a point
func run():
	# move left or right, depending on this vector
	var dir = 1
	var distance = rand_range(32, 64)
	if (randi()%2+0) == 1:
		dir = -1
	
	$Tween.interpolate_property(self, "rect_position:x", \
		rect_position.x, rect_position.x + (distance * dir), 0.8, \
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, rect_position.y - 20, 0.4, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y - 20, rect_position.y + 180, 0.4, \
		Tween.TRANS_CIRC, Tween.EASE_IN, 0.4)
	$Tween.connect("tween_all_completed", self, "finishTween")
	$Tween.start()

func finishTween():
	emit_signal("done")
	queue_free()
