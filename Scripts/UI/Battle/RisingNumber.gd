extends Label

# move left or right, depending on this vector
var dir = 1
signal done()

# sets tween to move number, as if bouncing off of a point
func run():
	if text == "Miss":
		$Miss.show()
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, rect_position.y - 16, 0.6, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	$AnimationPlayer.play("start")
	$AnimationPlayer.connect("animation_finished", self, "finishTimer")
	
	$Tween.start()

func finishTimer(anim):
	emit_signal("done")
	queue_free()
