extends NinePatchRect



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.



func _process(delta):
	$VBoxContainer/FPS.text = "FPS: " + var2str(Engine.get_frames_per_second())
