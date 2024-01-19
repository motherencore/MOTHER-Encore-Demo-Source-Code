extends Sprite


export var flag = ""

func _ready():
	if flag != null or flag != "":
		if globaldata.flags.has(flag):
			if globaldata.flags[flag] == true:
				queue_free()

func _on_Area2D_body_entered(body):
	if body == global.persistPlayer and !$AudioStreamPlayer.playing:
		if global.currentScene.name in globaldata.keys:
			globaldata.keys[global.currentScene.name] += 1
			globaldata.flags[flag] = true
		$AudioStreamPlayer.playing = true
		self.visible = false
		$Area2D/CollisionShape2D.set_deferred("disabled", true)
		uiManager.key.update()
		if uiManager.check_keys(global.currentScene.name) == 1:
			uiManager.key.open()

func _on_AudioStreamPlayer_finished():
	queue_free()

func _on_AnimationPlayer_animation_finished(anim_name):
	queue_free()
