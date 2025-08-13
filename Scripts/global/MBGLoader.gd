extends Node

# Never used??

#var material = preload("res://Shaders/MBGMaterial.tres")

#func load_bg(path): # Never called??
#	var f = File.new()
#	if f.open_compressed(path,1,3) == OK:
#		var json = f.get_as_text()
#		f.close()
##		var bg = create_background(str2var(json))
#		return str2var(json)
#	else:
#		print_debug("error! could not open mpg file")
#		return null
#
#func create_background(layers): # Never called??
#	
#	var canvasLayer = CanvasLayer.new()
#	for layer in layers:
#		var texRect = TextureRect.new()
#		texRect.expand = true
#		texRect.stretch_mode = TextureRect.STRETCH_TILE
#		texRect.rect_position = Vector2()
#		texRect.rect_size = get_viewport().size
#		texRect.material = material.duplicate()
#		
#		# set opacity (not a shader param)
#		texRect.modulate.a = layer.opacity
#		
#		var fuck = false
#		# set shader params
#		texRect.material.set_shader_param("move", layer.move)
#		if fuck:
#			texRect.material.set_shader_param("ping_pong_speed", layer.ping_pong_speed)
#			texRect.material.set_shader_param("oscillation_amplitude", layer.oscillation_amplitude)
#			texRect.material.set_shader_param("oscillation_frequency", layer.oscillation_frequency)
#			texRect.material.set_shader_param("oscillation_speed", layer.oscillation_speed)
#			texRect.material.set_shader_param("osc_amp_ping_pong", layer.osc_amp_ping_pong)
#			texRect.material.set_shader_param("osc_trans_ping_pong", layer.osc_trans_ping_pong)
#			
#			texRect.material.set_shader_param("compression_amplitude", layer.compression_amplitude)
#			texRect.material.set_shader_param("compression_frequency", layer.compression_frequency)
#			texRect.material.set_shader_param("compression_speed", layer.compression_speed)
#			texRect.material.set_shader_param("comp_amp_ping_pong", layer.comp_amp_ping_pong)
#			texRect.material.set_shader_param("comp_trans_ping_pong", layer.osc_trans_ping_pong)
#			
#			texRect.material.set_shader_param("interlaced_amplitude", layer.interlaced_amplitude)
#			texRect.material.set_shader_param("interlaced_frequency", layer.interlaced_frequency)
#			texRect.material.set_shader_param("interlaced_speed", layer.interlaced_speed)
#			texRect.material.set_shader_param("inter_amp_ping_pong", layer.inter_amp_ping_pong)
#			texRect.material.set_shader_param("inter_trans_ping_pong", layer.inter_trans_ping_pong)
#			
#		texRect.material.set_shader_param("palette_shifting", layer.palette_shifting)
#		texRect.material.set_shader_param("palette_shifting_speed", layer.palette_shifting_speed)
#		#texRect.material.set_shader_param("interleaved", Vector2(layer.Xinterleaved, layer.Yinterleaved))
#		
#		if layer.image != null:
#			texRect.texture = str2var(layer.image)
#		#idk how to handle palettes yet lol
#		if layer.palette != null:
#			texRect.material.set_shader_param("palette", str2var(layer.palette))
#		texRect.name = layer.name
#		canvasLayer.add_child(texRect)
#	return canvasLayer
	
