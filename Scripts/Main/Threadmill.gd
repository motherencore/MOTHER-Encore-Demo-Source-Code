extends Area2D

export var movement_direction = Vector2.ZERO
var wasRunning = false
var movingActors = []

func _ready():
	set_physics_process(false)

func _physics_process(delta):
	var oldpos = global.persistPlayer.position
	for actor in movingActors:
		actor.position += movement_direction
		if actor.get("direction") != null:
			actor.direction = movement_direction
		elif actor.get("inputVector") != null:
			actor.inputVector = movement_direction
		actor.blend_position(movement_direction)
	if global.persistPlayer.substantialMovement == false or global.persistPlayer.paused:
		global.partySpace.push_front(global.persistPlayer.position.round())
		global.partySpace.pop_back()

func _on_Threadmill_body_entered(body):
	if movingActors.size() == 0:
		set_physics_process(true)
	movingActors.append(body)
	if body == global.persistPlayer:
		wasRunning = global.persistPlayer.tap_run
		global.persistPlayer.pause()
	else:
		body.animationState.travel("Idle")
		body.set_physics_process(false)

func _on_Threadmill_body_exited(body):
	movingActors.erase(body)
	if movingActors.size() == 0:
		set_physics_process(false)
	if body == global.persistPlayer:
		global.persistPlayer.tap_run = wasRunning
		global.persistPlayer.unpause()
		global.persistPlayer.direction = movement_direction.round()
	else:
		body.set_physics_process(true)
		body.find_path()
	
