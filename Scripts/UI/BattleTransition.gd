extends Node

onready var animationPlayer = $AnimationPlayer
onready var box = $ColorRect
var battleui = null
signal done

# Called when the node enters the scene tree for the first time.
func _ready():
	remove_child(box)
	global.currentScene.add_child(box)
	global.currentScene.move_child(box, 0)
	box.rect_position = global.currentCamera.get_camera_screen_center() - Vector2(160, 90)
	animationPlayer.play("Start")

func set_color(color):
	var material = $Sprite.get_material()
	material.set_shader_param("NEWCOLOR", color)
	print(color)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "Start":
		box.queue_free()
		queue_free()
		emit_signal("done")
