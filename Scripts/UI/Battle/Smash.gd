extends Sprite

onready var animPlayer = $AnimationPlayer

func _ready():
	$AnimationPlayer.play("Smaaaash!!")
	yield($AnimationPlayer,"animation_finished")
	queue_free()
