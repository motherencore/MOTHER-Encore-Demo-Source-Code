extends Position2D

export (String, "Podunk", "Swamp") var sprite = "Podunk"
export (int, 1, 1000) var grass_types = 1

onready var grass = preload("res://Nodes/Overworld/grass.tscn")

var currentGrass = null
var flipped = false
var texturePath = ""

func _ready():
	$Sprite.queue_free()
	texturePath = ("res://Graphics/Objects/Grass/" + sprite + "/"+ var2str(randi()%grass_types+0) + ".png")
	if (randi()%2+0) == 1:
		flipped = true
	else:
		flipped = false

func _on_VisibilityNotifier2D_screen_entered():
	if currentGrass == null:
		var newGrass = grass.instance()
		newGrass.global_position = position
		get_parent().add_child(newGrass)
		newGrass.set_grass(sprite, texturePath, flipped)
		currentGrass = newGrass

func _on_VisibilityNotifier2D_screen_exited():
	if currentGrass != null:
		currentGrass.queue_free()
		currentGrass = null
