extends Sprite

export (String) var affected_object = ""
export (bool) var perm
export var flag = ""

signal switch_hit
var active = false
var jammed = false

onready var animationPlayer = $AnimationPlayer

func _ready():
	$interact/CollisionShape2D2.disabled = true
	$Timer.start()
	if flag != null or flag != "":
		if globaldata.flags.has(flag):
			if globaldata.flags[flag] == true:
				active = true
				$AnimationPlayer.play("Right")
				if perm:
					jammed = true
				if global.currentScene.get_node_or_null(affected_object) != null:
					var mirror = global.currentScene.get_node("Objects/Mirror")
					mirror.reflect = mirror.reflect.rotated(45).round().normalized()

func _on_Timer_timeout():
	$interact/CollisionShape2D2.disabled = false

func interact():
	if !jammed and !global.persistPlayer.paused:
		if $Timer.time_left == 0:
			if flag != null or flag != "":
				if globaldata.flags.has(flag):
					globaldata.flags[flag] = true
			if active == false:
				active = true
				$AnimationPlayer.play("Right")
			else:
				active = false
				$AnimationPlayer.play("Left")
			if "block" in global.currentScene:
				if global.currentScene.block == true:
					global.currentScene.block = false
				else:
					global.currentScene.block = true
			$AudioStreamPlayer.playing = true
			if perm:
				jammed = true
			if global.currentScene.get_node_or_null(affected_object) != null:
				var mirror = global.currentScene.get_node("Objects/Mirror")
				mirror.reflect = mirror.reflect.rotated(45).round().normalized()
			emit_signal("switch_hit")

func _on_interact_area_entered(area):
	interact()
