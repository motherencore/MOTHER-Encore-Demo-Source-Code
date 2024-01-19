extends CanvasLayer

onready var colorRect = $Path2D/PathFollow2D/ColorRect
onready var animPlayer = $Path2D/PathFollow2D/ColorRect/AnimationPlayer

signal fade_in_done
signal fade_out_done
signal cut_done

func toggle_spin(speed = 1.0):
	if $PathAnim.is_playing():
		$PathAnim.stop()
		$Path2D/PathFollow2D.unit_offset = 0
	else:
		$PathAnim.play("Rotate", -1, float(speed))

func set_spin(enabled, speed = 1.0):
	if enabled:
		$PathAnim.play("Rotate", -1, float(speed))
	else:
		if $PathAnim.is_playing():
			$PathAnim.stop()
		$Path2D/PathFollow2D.unit_offset = 0
		

func set_cut(size, speed = 1.0, type = 1, tweenEase = Tween.EASE_IN_OUT):
	colorRect.material.set_shader_param("fade", type)
	$Tween.interpolate_property(colorRect.material, "shader_param/cut",
		colorRect.material.get_shader_param("cut"), size, speed,
		Tween.TRANS_QUAD, tweenEase)
	$Tween.start()
	
	yield($Tween, "tween_completed")
	
	emit_signal("cut_done")

func focus_object(object = global.persistPlayer):
	colorRect.rect_position = -colorRect.rect_size/4
	colorRect.rect_position = object.global_position - global.currentCamera.get_camera_screen_center() - colorRect.rect_size/4

func set_color(color = Color.black):
	colorRect.modulate = color

func fade_in(anim_name = "Fade", color = Color.black, animation_speed = 1):
	set_color(color)
	if anim_name == "Circle Focus":
		focus_object()
		anim_name = "Circle"
	else:
		colorRect.rect_position = -colorRect.rect_size/4
	animPlayer.play(anim_name + " In", -1, animation_speed)
	yield(animPlayer, "animation_finished")
	colorRect.rect_position = -colorRect.rect_size/4
	emit_signal("fade_in_done")

func fade_out(anim_name = "Fade", color = Color.black, animation_speed = 1.0):
	if colorRect.modulate != color:
		$Tween.interpolate_property(colorRect, "modulate",
			colorRect.modulate, color, animation_speed / 4)
		$Tween.start()
		animation_speed = animation_speed * 0.75
		yield($Tween, "tween_completed")
	if anim_name == "Circle Focus":
		focus_object()
		anim_name = "Circle"
	else:
		colorRect.rect_position = -colorRect.rect_size/4
	animPlayer.play(anim_name + " Out", -1, animation_speed)
	yield(animPlayer, "animation_finished")
	colorRect.rect_position = -colorRect.rect_size/4
	emit_signal("fade_out_done")
