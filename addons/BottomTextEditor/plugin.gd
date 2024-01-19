tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("dock.tscn").instance()
	
	add_control_to_bottom_panel(dock, "TextEditor")
	#add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_UR, dock)
	
	setup_dialogs()

func _exit_tree():
	remove_control_from_bottom_panel(dock)
	#remove_control_from_docks(dock)
	
	dock._file_dialog.queue_free()
	dock.queue_free()

func setup_dialogs():
	dock._file_dialog = FileDialog.new()
	dock._file_dialog.mode = FileDialog.MODE_OPEN_FILE
	dock._file_dialog.access = FileDialog.ACCESS_RESOURCES
	# ... more config
	dock._file_dialog.connect("file_selected", dock, "_on_FileDialog_file_selected")
	dock.setup_dialogs()

	var editor_interface = get_editor_interface()
	var base_control = editor_interface.get_base_control()
	base_control.add_child(dock._file_dialog)
