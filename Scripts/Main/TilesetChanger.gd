extends TileMap
class_name TileMapChanger

export var tile : Texture
export var tile2 : Texture
# var b = "text"




func _process(delta):
	if Input.is_action_just_pressed("ui_w"):
		_change_textures()

func _change_textures():
	for i in tile_set.get_tiles_ids():
		
		tile_set.call_deferred("tile_set_texture", i, tile2)
		yield(get_tree(), "idle_frame")
