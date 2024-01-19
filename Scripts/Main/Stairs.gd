extends Area2D

export var horizontal = true
export var northeast_southwest = true
var movingActors = []

func _physics_process(delta):
	if global.persistPlayer.substantialMovement and global.persistPlayer.walk:
		var speed = 1
		if global.persistPlayer.running:
			speed = 2
		else:
			speed = 1
		for actor in movingActors:
			if is_instance_valid(actor):
				var inputVector = Vector2.ZERO
				if actor.get("direction") != null:
					inputVector = actor.direction
				else:
					inputVector = actor.inputVector
				if horizontal:
					if northeast_southwest:
						if actor == global.persistPlayer:
							actor.position.y -= inputVector.x * speed
							global.partySpace[0].y -= inputVector.x * speed
							
							print("a"+ str(actor.position.y))
							print("s"+ str(global.partySpace[0].y))
						elif actor.get("directionMultiplier") != null:
							actor.directionMultiplier.y = 0
					else:
						if actor == global.persistPlayer:
							actor.position.y += inputVector.x * speed
							global.partySpace[0].y += inputVector.x * speed
						elif actor.get("directionMultiplier") != null:
							actor.directionMultiplier.y = 0
				else:
					if northeast_southwest:
						if actor == global.persistPlayer:
							actor.position.x += inputVector.y * speed
						elif actor.get("directionMultiplier") != null:
							actor.directionMultiplier.x = 0
					else:
						if actor == global.persistPlayer:
							actor.position.x -= inputVector.y * speed
						elif actor.get("directionMultiplier") != null:
							actor.directionMultiplier.x = 0
			else:
				movingActors.erase(actor)



func _on_Stairs_area_entered(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if movingActors.size() == 0:
			set_physics_process(true)
		movingActors.append(object)

func _on_Stairs_area_exited(area):
	var object = area.get_parent()
	if global.partyObjects.has(object):
		if object.get("directionMultiplier") != null:
			object.directionMultiplier = Vector2.ONE
		movingActors.erase(object)
		if movingActors.size() == 0:
			set_physics_process(false)
