extends Control

signal apply_damage

export (int) var hits = 0
var shown = false
var shownPos = Vector2()
var hidePos = Vector2()
const distanceToShown = 20

onready var animationPlayer = $AnimationPlayer

func _ready():
	hidePos = rect_position.y
#	shownPos = rect_position.y - 36
	shownPos = rect_position.y - distanceToShown
	animationPlayer.play("idle")

func play(anim, override = false):
	if !animationPlayer.has_animation(anim):
		anim = "idle"
	if !animationPlayer.is_playing() or override:
#		animationPlayer.clear_queue()
		animationPlayer.play(anim)
	else:
		animationPlayer.queue(anim)
	if !"psi" in anim:
		$Sprite.material.set_shader_param("width", 0)

func apply_damage():
	emit_signal("apply_damage")

func showIn():
	$Tween.reset_all()
	for connection in $Tween.get_incoming_connections():
		$Tween.disconnect(connection.signal_name, connection.source, connection.method_name)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, shownPos, 0.16)
	$Tween.start()
	shown = true

func showAndPlay(anim):
	showIn()
	play(anim)
	#$Tween.connect("tween_all_completed", animationPlayer, "play", [anim], CONNECT_ONESHOT)

func hideAway(anim = ""):
	$Tween.reset_all()
	for connection in $Tween.get_incoming_connections():
		$Tween.disconnect(connection.signal_name, connection.source, connection.method_name)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, hidePos, 0.16)
	$Tween.start()
	shown = false

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

func shake(magnitude):
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y + 5, rect_position.y, \
		0.15,Tween.TRANS_SINE,Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:x", \
		rect_position.x + 10, rect_position.x, 0.2,\
		Tween.TRANS_ELASTIC,Tween.EASE_OUT)
	$Tween.start()

func bounceUpHit(intensity = 1):
	$Tween.reset_all()
	for connection in $Tween.get_incoming_connections():
		$Tween.disconnect(connection.signal_name, connection.source, connection.method_name)
	var toAdd = 0
	if !shown:
		toAdd = distanceToShown
	$Tween.interpolate_property($Sprite, "scale", \
		Vector2(0.6,1.6), Vector2(1,1), 0.2, \
		Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, rect_position.y - toAdd - 32 * intensity - 16, 0.2, \
		Tween.TRANS_QUART, Tween.EASE_OUT)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y - toAdd - 32 * intensity - 16, hidePos, 0.2, \
		Tween.TRANS_CIRC, Tween.EASE_IN, 0.32)
	$Tween.start()
	
	var prev_anim
	if !animationPlayer.get_queue().empty():
		prev_anim = animationPlayer.get_queue()[-1]
	else:
		prev_anim = animationPlayer.assigned_animation
	
	var hitAnim = "hit"
	if hits > 0:
		hitAnim = "hit" + var2str(int(round(rand_range(1, hits))))
	play(hitAnim, true)
	$Tween.connect("tween_all_completed", self, "playAfterHit", [prev_anim], CONNECT_ONESHOT)

func playAfterHit(prev):
#	play("hitIdle", true)
	animationPlayer.clear_queue()
	animationPlayer.play(prev)
	var anim = animationPlayer.get_animation(prev)
	animationPlayer.seek(anim.length, true)
	if prev != "idle":
		showIn()
#	play(prev)

