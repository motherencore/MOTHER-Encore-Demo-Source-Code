extends TileMap


var tile = load("res://Tilesets/Reindeer.tres")
var tile2 = load("res://Tilesets/Snowman.tres")
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass



func _process(delta):
	if Input.is_action_just_pressed("ui_home"):
		if self.tile_set == tile:
			self.tile_set = tile2
		else:
			self.tile_set = tile
