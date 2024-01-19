extends Sprite

func _ready():
	if globaldata.flags["hidden_entrance_opened"]:
		$AnimationPlayer.play("Opened")
