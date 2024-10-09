extends Sprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var size = float($Shadow.texture.get_width())/5
	print(float(size/10))
	$Shadow.scale.x = $Shadow.scale.x + float(size/10)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
