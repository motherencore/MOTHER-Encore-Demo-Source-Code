extends Area2D

export var horizontal = true
export var northeast_southwest = true
export var step_length = 1
var step_distance = 0
var direction = 1
var movingActors = []

func _ready():
	if northeast_southwest:
		direction *= -1

func _physics_process(delta):
	if global.persistPlayer.substantialMovement and global.persistPlayer.walk:
		var speed = global.persistPlayer.velocity
		for actor in movingActors:
			if is_instance_valid(actor):
				var inputVector = Vector2.ZERO
				if actor.get("direction") != null:
					inputVector = actor.direction
				else:
					inputVector = actor.inputVector
				if horizontal:
					if global.persistPlayer.running:
						actor.move_and_slide(Vector2(0, speed.x / step_length * direction))
					else:
						if actor == global.persistPlayer:
							step_distance += inputVector.x
						if abs(step_distance) >= step_length:
							if actor == global.persistPlayer:
								step_distance -= step_length * inputVector.x
								actor.position.y += inputVector.x * direction
								global.partySpace[0].y += inputVector.x * direction
				else:
					if global.persistPlayer.running:
						actor.move_and_slide(Vector2(speed.y / step_length * direction, 0))
					else:
						if actor == global.persistPlayer:
							step_distance += inputVector.y
						if abs(step_distance) >= step_length:
							if actor == global.persistPlayer:
								step_distance -= step_length * inputVector.y
								actor.position.x += inputVector.y * direction
								global.partySpace[0].x += inputVector.y * direction
			else:
				movingActors.erase(actor)



func _on_Stairs_area_entered(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if movingActors.size() == 0:
			set_physics_process(true)
		movingActors.append(object)
		if object.get("directionMultiplier") != null:
			if horizontal:
				object.directionMultiplier.y = 0
			else:
				object.directionMultiplier.x = 0

func _on_Stairs_area_exited(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if object.get("directionMultiplier") != null:
			object.directionMultiplier = Vector2.ONE
		movingActors.erase(object)
		if movingActors.size() == 0:
			set_physics_process(false)
