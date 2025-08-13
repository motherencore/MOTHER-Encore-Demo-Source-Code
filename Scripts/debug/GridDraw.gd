tool
extends Node2D

export var beacon_position := Vector2.ZERO
export var beacon_radius := 256
export var grid_size := 0
export(Font) var font

export var grid_span_x = 1
export var grid_span_y = 1

func _process(_delta):
	update()

func _draw():
	# Draw the chunk seam lines
	var bx = int(beacon_position.x/grid_size)
	var by = int(beacon_position.y/grid_size)
	
	for y in range(by-grid_span_y, by+grid_span_y+1):
		for x in range(bx-grid_span_y, bx+grid_span_y+1):
			var p = Vector2(x, y) * grid_size
			draw_rect(
				Rect2 (
					p,
					Vector2(grid_size, grid_size)
				), Color.white, false
			)
			draw_string(font, p + Vector2(2, 6), "["+str(x)+"; "+str(y)+"]", Color.white)
	
	# Draw the character beacon circle
	draw_rect(
		Rect2(
			beacon_position - Vector2(beacon_radius, beacon_radius),
			Vector2(beacon_radius, beacon_radius)*2
		), Color(0.470588, 0.921569, 0.192157, 0.25098), false, 1.2
	)







