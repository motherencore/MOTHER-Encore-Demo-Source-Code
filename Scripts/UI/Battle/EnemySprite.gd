extends TextureRect

onready var transitionTween = $TransitionTween

signal apply_damage

func _ready():
	rect_pivot_offset = rect_size/2
	$AnimationPlayer.play("appear")
	$AnimationPlayer.advance(0)
	$AnimationPlayer.stop()

func appear():
	rect_pivot_offset = rect_size/2
	$AnimationPlayer.play("appear")

func flash():
	$AnimationPlayer.play("flash")

func disappear():
	$AnimationPlayer.play_backwards("appear")

func select():
	material.set_shader_param("flash_color", Color.white)
	material.set_shader_param("glow_modifier", 0.25)

func deselect():
	material.set_shader_param("glow_modifier", 0.0)

func attack():
	$Tween.interpolate_property(self, "rect_position:y",
		rect_position.y, rect_position.y -10, 0.1,
		Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:y",
		rect_position.y - 12, rect_position.y, 0.1,
		Tween.TRANS_QUART, Tween.EASE_IN, 0.1)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	emit_signal("apply_damage")

func dodge():
	var movement = 8
	if (randi()%2+0) == 1:
		movement = -8
	$Tween.interpolate_property(self, "rect_position:x", \
		rect_position.x, rect_position.x + movement, 0.1,\
		Tween.TRANS_QUART,Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:x", \
		rect_position.x + movement, rect_position.x, 0.1,\
		Tween.TRANS_QUART,Tween.EASE_IN, 0.1)
	$Tween.start()

func hit():
	$AnimationPlayer.play("hit")

func defeat(boss = false):
	if boss:
		$AnimationPlayer.play("bossDefeat")
	else:
		$AnimationPlayer.play("defeat")
	$AnimationPlayer.connect("animation_finished", self, "hide", [], CONNECT_ONESHOT)

func hide(anim = ""):
	.hide()
