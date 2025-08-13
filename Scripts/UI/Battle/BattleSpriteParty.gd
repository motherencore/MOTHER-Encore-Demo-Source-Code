extends Control

signal apply_damage

export (int) var hits = 0
export var distanceToShown = 20
var shownPos = Vector2()
var hidePos = Vector2()
enum states {HIDDEN, SHOWN, BOUNCING}
var state = states.HIDDEN
var dead = false

onready var animationPlayer = $AnimationPlayer

func _ready():
	hidePos = rect_position.y
	shownPos = rect_position.y - distanceToShown
	animationPlayer.play("lookIntoYourSoul")
	

func play(anim:String, override := false):
	if !animationPlayer.is_playing() or override:
		animationPlayer.clear_queue()
		animationPlayer.play(anim)
	elif !override:
		animationPlayer.queue(anim)
	if !"psi" in anim:
		$Sprite.material.set_shader_param("width", 0)
		
func set_psi_colors(colors: Array):
	var animation = animationPlayer.get_animation("psiPrep2")
	for i in range(3):
		animation.track_set_key_value(1, i, Color(colors[i]))

func apply_damage():
	emit_signal("apply_damage")

func showIn():
	$Tween.reset_all()
	for connection in $Tween.get_incoming_connections():
		$Tween.disconnect(connection.signal_name, connection.source, connection.method_name)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, shownPos, 0.16)
	$Tween.start()
	state = states.SHOWN

func showAndPlay(anim):
	showIn()
	play(anim)
	#$Tween.connect("tween_all_completed", animationPlayer, "play", [anim], CONNECT_ONESHOT)

func hideAway(anim = "", override = false):
	if anim != "":
		play(anim, override)
	$Tween.reset_all()
	for connection in $Tween.get_incoming_connections():
		$Tween.disconnect(connection.signal_name, connection.source, connection.method_name)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, hidePos, 0.16)
	$Tween.start()
	state = states.HIDDEN

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
	if state == states.HIDDEN:
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
	
	var prev_state = state
	state = states.BOUNCING
	
	var prev_anim
	var prev_anim_colors = []
	if !animationPlayer.get_queue().empty():
		prev_anim = animationPlayer.get_queue()[-1]
	else:
		prev_anim = animationPlayer.assigned_animation
		if prev_anim == "psiPrep2":
			for i in range(3):
				prev_anim_colors.append(animationPlayer.get_animation("psiPrep2").track_get_key_value(1, i))
	
	var hitAnim = "hit"
	if hits > 0:
		hitAnim = "hit" + var2str(int(round(rand_range(1, hits))))
	play(hitAnim, true)
	if prev_anim == "psiPrep2":
		set_psi_colors(prev_anim_colors)
	$Tween.connect("tween_all_completed", self, "playAfterHit", [prev_anim, prev_state], CONNECT_ONESHOT)

func playAfterHit(prev, prevState):
	if dead:
		play("lookIntoYourSoul", true)
	else:
		animationPlayer.clear_queue()
		play(prev, true)
		var anim = animationPlayer.get_animation(prev)
		if prev != "psiPrep2":
			animationPlayer.seek(anim.length, true)
		if prevState == states.SHOWN:
			showIn()
