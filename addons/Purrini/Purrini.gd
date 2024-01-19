tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/Purrini/main.tscn").instance()
	add_control_to_bottom_panel(dock, "Purrini")


func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
