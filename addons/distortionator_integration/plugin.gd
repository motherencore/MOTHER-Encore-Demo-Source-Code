tool
extends EditorPlugin

var distortionator_format_importer = preload("res://addons/distortionator_integration/scene_importer.gd")

func _enter_tree():
	distortionator_format_importer = distortionator_format_importer.new()
	
	add_scene_import_plugin(distortionator_format_importer)
	
	#export_icon("Play", "res://assets/icons/Play.png")
	#export_icon("Pause", "res://assets/icons/Pause.png")

func _exit_tree():
	remove_scene_import_plugin(distortionator_format_importer)

func export_icon(icon_name : String, path : String):
	var icon : Texture = get_editor_interface().get_base_control().get_icon(icon_name, "EditorIcons")
	icon.get_data().save_png(path)
