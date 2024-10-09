extends Node

onready var AfterImage = preload("res://Nodes/Reusables/Effects/After Image.tscn")
onready var timer = $Timer

export var spritePath : NodePath
onready var sprite = get_node_or_null(spritePath)

func create_after_image(): #use sprite.duplicate()
	var after_image = AfterImage.instance()
	after_image.set_texture(sprite.duplicate())
	after_image.global_position = sprite.global_position
	get_parent().get_parent().add_child(after_image)


func set_interval(time):
	timer.wait_time = time

func start_creating():
	timer.start()

func stop_creating():
	timer.stop()

func _on_Timer_timeout():
	create_after_image()
	timer.start()
