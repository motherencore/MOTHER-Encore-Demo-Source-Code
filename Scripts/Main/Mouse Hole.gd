extends Sprite

export var infinite_mouse = false

var mouse = load("res://Nodes/Overworld/Enemies/Basic Enemy.tscn")
var is_mouse
var the_mouse
var mouse_respawn = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.frame = 0
	$Sprite.visible = false

func _on_Area2D_body_entered(body):
	if body == global.persistPlayer:
		is_mouse = global.currentScene.get_node_or_null("Objects/" + self.name)
		if is_mouse == null and mouse_respawn == true and $Timer.time_left == 0:
			$AnimationPlayer.play("Come out")
			if infinite_mouse == false:
				mouse_respawn = false

func create_mouse():
	var new_parent = global.currentScene.get_node("Objects")
	var Mouse = mouse.instance()
	Mouse.enemy = "rat"
	Mouse.name = self.name
	Mouse.global_position = self.global_position
	Mouse.inputVector = Vector2(0,1)
	Mouse.walk_frequency = 0.6
	new_parent.add_child(Mouse)
	$Tween.interpolate_property(Mouse, "global_position",
		Mouse.global_position, Vector2(self.global_position.x, self.global_position.y + 3), 0.1,
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	$Tween.start()
	yield($Tween,"tween_completed")
	Mouse.start_pos = Mouse.global_position
	$Timer.start()
