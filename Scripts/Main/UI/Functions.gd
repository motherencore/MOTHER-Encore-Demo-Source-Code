extends Node

var del = 1
var curPos = Vector2.ZERO
var moving = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	

func _process(delta):
	del = delta
	if moving:
		global.persistPlayer.position.x = round(curPos.x)
		global.persistPlayer.position.y = round(curPos.y)

func printf(param):
	print(param)

func changeMusic(music,loop):
	if loop != "":
		globaldata.musicLoop = loop 
	else:
		globaldata.musicLoop = null
	
	if music != null:
		
		global.play_music(music)
		

func addMoney(amount, add):
	if add:
		globaldata.cash = globaldata.cash + amount
	else:
		globaldata.cash = globaldata.cash - amount
	print(globaldata.cash)

func addParty(name):
	var member = globaldata.get(str2var(name))
	if member in global.party:
		if member["status"] == globaldata.ailments.Unconcious:
			if global.partyObjects.size() > 1:
				global.party.erase(member)
			else: 
				member["status"] = globaldata.ailments.Normal
		else: 
			member["status"] = globaldata.ailments.Unconcious
	else:
		global.party.append(member) 
		member["status"] = globaldata.ailments.Normal
	global.create_party_followers()
	global.persistPlayer._spritesheet()
	

func move_camera(position_x,position_y, time):
	global.persistPlayer.camera.move_camera(position_x,position_y, time)

func return_camera(time):
	global.persistPlayer.camera.return_camera(time)

func shake_camera(magnitude, time):
	global.persistPlayer.camera.shake_camera(magnitude, time)

func movePlayer(x,y,dirx,diry):
	var oldPos = global.persistPlayer.position
	curPos = oldPos
	var newPos = Vector2(x,y)
	
	var tween = Tween.new()
	
	global.currentScene.add_child(tween)
	
	#global.persistPlayer.direction = oldPos.direction_to(Vector2(x,y))
	var time = oldPos.distance_to(newPos) / global.persistPlayer.speed
	#print(time)
	
	
	tween.interpolate_property(self, "curPos",
	oldPos, newPos, time,
	Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
	moving = true
	
	print(global.persistPlayer.inputVector.angle() - TAU/4)
	global.persistPlayer.blend_position(Vector2(dirx,diry))
	
	if global.persistPlayer.position.x == newPos.x or global.persistPlayer.position.y == newPos.y:
		moving = false
	
	yield(tween,"tween_completed")
	moving = false

func changeSpeed(spd):
	global.persistPlayer.speed = spd

func wait(time) -> bool:
	yield(get_tree().create_timer(time),"timeout")
	return true
