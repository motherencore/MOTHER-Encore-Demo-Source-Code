extends Node2D

export(Array, NodePath) var tilemap_paths
var tilemaps : Array = []

# The Chunk Beacon is the object that's in the center of the screen,
# and serves as the reference for chunks to spawn or be despawned.
var chunk_beacon : Node2D
export var chunk_size = 2

# The GridDraw is the object that draws grids.
export var grid_draw_path : NodePath
var grid_draw

var chunk_beacon_radius = 64

func _ready():
	for i in tilemap_paths:
		tilemaps.append(get_node(i))
	chunk_beacon = global.persistPlayer
	grid_draw = get_node(grid_draw_path)
	grid_draw.grid_size = chunk_size * tilemaps[0].cell_size.x
	save_all()

func save_section(x0,y0,x1,y1):
	for t in tilemaps:
		for y in range(y0, y1):
			for x in range(x0, x1):
				t.save_chunk(x, y)
		t.clear()

func save_all():
	if tilemaps.empty():
		return
	var t0 = tilemaps[0]
	var used_rect = t0.get_used_rect()
	var chunk_start_position = used_rect.position / chunk_size
	var chunk_end_position = (used_rect.position + used_rect.size) / chunk_size
	
	var x0 = int(chunk_start_position.x-1)
	var y0 = int(chunk_start_position.y-1)
	var x1 = int(chunk_end_position.x+1)
	var y1 = int(chunk_end_position.y+1)
	
	for t in tilemaps:
		t.chunk_size = chunk_size
		for y in range(y0, y1):
			for x in range(x0, x1):
				t.save_chunk(x, y)
		t.clear()

func _process(_delta):
	grid_draw.beacon_position = global.persistPlayer.global_position
	if Input.is_action_just_pressed("ui_test") and OS.is_debug_build():
		var t = Thread.new()
		update_chunks()

func update_chunks():
	# Update the grid renderer with the beacon position!
	
	grid_draw.beacon_radius = chunk_beacon_radius
	if tilemaps.empty():
		return
	
	var t0 := tilemaps[0] as BigTileMap
	var chunk_position_x = int(chunk_beacon.position.x / (tilemaps[0].chunk_size*tilemaps[0].cell_size.x))
	var chunk_position_y = int(chunk_beacon.position.y / (tilemaps[0].chunk_size*tilemaps[0].cell_size.x))
	
	var ccbr := int(chunk_beacon_radius / (chunk_size * t0.cell_size.x))
	var player_rect = Rect2(
		chunk_beacon.global_position - Vector2(chunk_beacon_radius, chunk_beacon_radius),
		Vector2(chunk_beacon_radius,chunk_beacon_radius)*2
	)
	
	# This goes trough all the "nearby" chunks and check if they are inside the rectangle.
	# then load and unload accordingly.
	for dy in range(-ccbr-2, ccbr+3):
		for dx in range(-ccbr-2, ccbr+3):
			var chunk_rect : Rect2 = Rect2(
				Vector2(chunk_position_x+dx, chunk_position_y+dy)*chunk_size*t0.cell_size.x,
				Vector2.ONE * chunk_size * t0.cell_size.x
			)
			
			var inside_radius : bool = chunk_rect.intersects(player_rect, true)
			
			for t in tilemaps:
				if inside_radius:
					t.load_chunk(chunk_position_x+dx, chunk_position_y+dy)
				else:
					t.erase_chunk(chunk_position_x+dx, chunk_position_y+dy)
