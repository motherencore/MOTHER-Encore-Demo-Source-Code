tool
extends EditorSceneImporter

var DEFAULT_SHADER = preload("default_shader.tres")
var DEFAULT_TEXTURE = preload("background.png")
var emptyStylebox = StyleBoxEmpty.new()

func _get_extensions():
	return ["dsp", "bbg"]

func _get_import_flags():
	return IMPORT_SCENE

func _import_scene(path : String, flags : int, bake_fps : int):
	var file := ConfigFile.new()
	var node := PanelContainer.new()
	node.add_stylebox_override("panel", emptyStylebox)
	node.name = "BBG"
	node.anchor_top = 0
	node.anchor_bottom = 1
	node.anchor_left = 0
	node.anchor_right = 1
	
	var err = file.load(path)
	
	if err != OK:
		return null
	
	var layer_sections : PoolStringArray = file.get_sections()
	layer_sections.remove(0)
	
	var shader_path_prefix = file.get_value("", "shader_folder", "res://")
	var texture_path_prefix = file.get_value("", "texture_folder", "res://")
	
	for layer_section in layer_sections:
		var keys : Array = file.get_section_keys(layer_section)
		
		if not "shader" in keys:
			push_error("Layer %s doesn't contain a shader." % layer_section)
			continue
		
		var shader_entry = str(file.get_value(layer_section, "shader", "[DEFAULT]"))
		var shader_path : String
		var shader : Shader
		
		print("Loading Shader ", shader_entry)
		if shader_entry == "[DEFAULT]":
			shader = DEFAULT_SHADER
		else:
			shader_path = (
				shader_path_prefix + "/" +
				shader_entry
			).simplify_path()
			shader = load(shader_path)
		
		keys.erase("shader")
		
		if not shader:
			push_error("Error loading shader at %s." % shader_path)
			continue
		
		var material := ShaderMaterial.new()
		material.shader = shader
		
		var layer_node := TextureRect.new()
		layer_node.stretch_mode = TextureRect.STRETCH_SCALE
		layer_node.material = material
		layer_node.name = layer_section
		node.add_child(layer_node, true)
		layer_node.owner = node
		
		if "texture" in keys:
			var texture_entry = str(file.get_value(layer_section, "texture", "res://icon.png"))
			var texture_path : String
			var new_texture : Texture
			if texture_entry == "[DEFAULT]":
				new_texture = DEFAULT_TEXTURE
			else:
				texture_path = (
					shader_path_prefix + "/" +
					texture_entry
				).simplify_path()
				keys.erase("texture")
				new_texture = load(texture_path)
			if new_texture:
				layer_node.texture = new_texture
			else:
				push_error("Error loading texture at %s." % texture_path)
		if "texture_stretch" in keys:
			var stretch_modes = [
				"STRETCH_SCALE_ON_EXPAND",
				"STRETCH_SCALE",
				"STRETCH_TILE",
				"STRETCH_KEEP"
			]
			keys.erase("texture_stretch")
			var texture_stretch : String = file.get_value(layer_section,"texture_stretch","STRETCH_SCALE")
			layer_node.stretch_mode = stretch_modes.find(texture_stretch)
		
		# Set the values for the uniforms!
		for key in keys:
			var uniform_value = file.get_value(layer_section, key, null)
			
			if uniform_value is String:
				if uniform_value.begins_with("[Resource]"):
					uniform_value = load(
						("res://" + uniform_value.trim_prefix("[Resource]")).simplify_path()
					)
			
			material.set_shader_param(
				key,
				uniform_value
			)
	
	return node
