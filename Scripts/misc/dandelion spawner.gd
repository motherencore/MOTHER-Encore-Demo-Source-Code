extends Position2D

onready var dandelion = preload("res://Nodes/Overworld/dandelion.tscn")
var currentDandelion = null

func _ready():
	$Sprite.queue_free()

func _on_VisibilityNotifier2D_screen_entered():
	if currentDandelion == null:
		var newDandelion = dandelion.instance()
		newDandelion.global_position = position
		get_parent().add_child(newDandelion)
		currentDandelion = newDandelion

func _on_VisibilityNotifier2D_screen_exited():
	if currentDandelion != null:
		currentDandelion.queue_free()
		currentDandelion = null
