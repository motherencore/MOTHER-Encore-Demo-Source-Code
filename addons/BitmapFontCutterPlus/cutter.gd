tool
extends BitmapFont

var index = 0
export(Vector2) var GlyphSize = Vector2(8,8) setget changeGlyphSize
export(Texture) var TextureToCut = null setget changeTexture
export(int,255) var StartChar = 32 setget changeStartChar
export(float) var Spacing = 1 setget changeSpacing
export(bool) var Monospaced = true setget changeMonospaced

func changeStartChar(value):
	StartChar = value
	update()

func changeGlyphSize(value):
	GlyphSize = value
	height = GlyphSize.y
	update()
	
func changeTexture(value):
	TextureToCut = value
	index = 0
	if TextureToCut:
		update()
	
func changeSpacing(value):
	Spacing = value
	update()

func changeMonospaced(value):
	Monospaced = value
	update()

func update():
	print("Cut texture to font")
	if TextureToCut != null:
		if GlyphSize.x > 0 and GlyphSize.y > 0:
			
			var w  = TextureToCut.get_width()
			var h  = TextureToCut.get_height()
			var tx = w / GlyphSize.x
			var ty = h / GlyphSize.y

			var font = self
			var i = 0  #Iterator for char index

			clear()

			#Begin cutting..... so edgy
			font.add_texture(TextureToCut)
			font.height = GlyphSize.y
			for y in range(ty):
				for x in range(tx+1):
					var l = 0
					var character_width = GlyphSize.x
					
					if !Monospaced:
						var data = TextureToCut.get_data()
						data.lock()
						
						var found = false
						for xx in range(0,GlyphSize.x):
							if found: break
							for yy in range(0,GlyphSize.y):
								var pixel = data.get_pixel(x*GlyphSize.x + xx, y*GlyphSize.y + yy)
								if pixel.a != 0:
									l = xx
									character_width -= xx
									found = true
									break
						
						found = false
						for xx in range(0,GlyphSize.x):
							if found: break
							for yy in range(0,GlyphSize.y):
								var pixel = data.get_pixel(x*GlyphSize.x + GlyphSize.x - xx -1, y*GlyphSize.y + yy)
								if pixel.a != 0:
									character_width -= xx
									found = true
									break
									
						data.unlock()
					
					var region = Rect2(x*GlyphSize.x + l,y*GlyphSize.y,character_width, GlyphSize.y)
					font.add_char(StartChar + i, 0, region, Vector2.ZERO, character_width + Spacing)
						
					i+=1
			update_changes()
	pass #if texture is null
