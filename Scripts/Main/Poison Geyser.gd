extends Area2D


onready var animationPlayer = $AnimationPlayer

func _ready():
	animationPlayer.play("Spewing")
	global.persistPlayer.connect("paused", self, "pause")
	global.persistPlayer.connect("unpaused", self, "unpause")

func _process(delta):
	if global.inBattle or global.cutscene or global.gameover:
		$AudioStreamPlayer2D.volume_db = -80
	else:
		$AudioStreamPlayer2D.volume_db = 0

func pause():
	$AnimationPlayer.playback_active = false
	$AudioStreamPlayer2D.stream_paused = true

func unpause():
	$AnimationPlayer.playback_active = true
	$AudioStreamPlayer2D.stream_paused = false

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()

func _on_Poison_Geyser_body_entered(body):
	if body.has_method("damage"):
		if global.persistPlayer.paused == false:
			body.damage(5, 2, Vector2.ZERO, globaldata.ailments.Poisoned)

func _on_Poison_Geyser_body_exited(body):
	if body.has_method("damage"):
		body.undamage()

func play_rumble():
	if $VisibilityNotifier2D.is_on_screen() and !global.inBattle and !global.gameover and !global.cutscene:
		if audioManager.get_sfx("geyser") == null:
			audioManager.play_sfx(load("res://Audio/Sound effects/shrekrumble.mp3"), "geyser")
		elif !audioManager.get_sfx(("geyser")).playing:
			audioManager.play_sfx(load("res://Audio/Sound effects/shrekrumble.mp3"), "geyser")
