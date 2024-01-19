extends TileMap
class_name BigTileMap

######################################################
#
#	Chroma BigTileMap
#		A tilemap extension that allows for tilemaps to be broken in chunks!
#
######################################################


# A tilemap chunk!
class TilemapChunk:
	var data_tile_id : Array = []
	var data_tile_atlas_index : Array = []

var chunk_size := 16

var chunks : Dictionary = {}

# Saves a chunk.
func save_chunk(chunk_x:int, chunk_y:int) -> void:
	var chunk_tile_position_x = chunk_x * chunk_size
	var chunk_tile_position_y = chunk_y * chunk_size
	var chunk = TilemapChunk.new()
	chunk.data_tile_id = []
	chunk.data_tile_atlas_index = []
	
	for y in range(0, chunk_size):
		for x in range(0, chunk_size):
			var tx = chunk_tile_position_x + x
			var ty = chunk_tile_position_y + y
			chunk.data_tile_id.append(get_cell(tx,ty))
			chunk.data_tile_atlas_index.append(get_cell_autotile_coord(tx, ty))
	chunks[Vector2(chunk_x, chunk_y)] = chunk
	
	#
	# Implement more stuff to save things like objects, events, sprites, etc.
	#

# Loads the whole chunk back.
# Returns true if the chunk loading succeded!
func load_chunk(chunk_x:int, chunk_y:int) -> bool:
	# So you can catch errors if you wanna ;)
	if not chunks.has(Vector2(chunk_x, chunk_y)):
		return false
	
	var chunk : TilemapChunk = chunks[Vector2(chunk_x, chunk_y)] as TilemapChunk
	
	var chunk_tile_position_x = chunk_x * chunk_size
	var chunk_tile_position_y = chunk_y * chunk_size
	
	var x := 0
	var y := 0
	for i in range(0, chunk_size * chunk_size):
		var tile_id = chunk.data_tile_id[i]
		var tile_atlas_index = chunk.data_tile_atlas_index[i]
		
		# Set the cell!
		set_cell(
			chunk_tile_position_x + x,
			chunk_tile_position_y + y,
			tile_id,
			false,
			false,
			false,
			tile_atlas_index
		)
		
		# Update coordinates for the next tile!
		x += 1
		if x >= chunk_size:
			x = 0
			y += 1
	
	#
	# You can add more code to load other things like entities, characters, etc.
	#
	
	return true

# Clears a whole chunk (turns into non-tiles)
func erase_chunk(chunk_x:int, chunk_y:int) -> void:
	# Clears tiles
	for y in range(0, chunk_size):
		for x in range(0, chunk_size):
			set_cell(chunk_x * chunk_size + x, chunk_y * chunk_size + y, -1)
	#
	# You can add more code here to dispose of non-tile objects.
	#
