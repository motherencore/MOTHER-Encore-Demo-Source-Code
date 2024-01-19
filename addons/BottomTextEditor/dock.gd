tool
extends Control

var tedit:TextEdit
var _file_dialog: FileDialog

var keywords :Dictionary
var colors   :Dictionary
var txttab_scene = preload("text_editor_tab.tscn")

func load_json (n) -> Dictionary:
	var path = self.get_script().get_path().get_base_dir() + "/" + n + ".json"
	return parse_json(load_file(path))

func load_file (path) -> String:
	var f = File.new()
	f.open(path, File.READ)
	var raw = f.get_as_text()
	f.close()
	return raw

func save_text (text:String, path) -> void:
	var f = File.new()
	f.open(path, File.WRITE)
	f.store_string(text)
	f.close()

func _ready():
	colors = load_json("settings/syntax_colors")
	keywords = load_json("settings/syntax_keywords")
	
	create_new_tab()

func _process(delta):
	if $Tabs.get_child_count() <= 0:
		create_new_tab()

func setup_dialogs():
	_file_dialog.add_filter("*.sson;Inner Voices Cutscenes")
	_file_dialog.add_filter("*.json;JSON")
	_file_dialog.add_filter("*.txt;Text Files")
	_file_dialog.add_filter("*.md;Markdown")
	_file_dialog.add_filter("*.csv;Comma Separated Values")
	_file_dialog.add_filter("*.cfg;Configuration Files")
	_file_dialog.add_filter("*.shader;Shaders")
	_file_dialog.add_filter("*.html;HTML")
	_file_dialog.add_filter("*.md;Markdown")
	_file_dialog.add_filter("*.gd;GDScript")
	_file_dialog.add_filter("*.js;JavaScript")
	_file_dialog.add_filter("*.py;Python Script")
	_file_dialog.add_filter("*.lua;LUA")
	_file_dialog.add_filter("*.cpp;C++")
	_file_dialog.add_filter("*.c;C")
	_file_dialog.add_filter("*.h;C Header")

signal _decided_closing
func create_new_tab():
	var new_tab = txttab_scene.instance()
	$Tabs.add_child(new_tab)
	$Tabs.current_tab = $Tabs.get_child_count() - 1
	$Tabs.set_tab_title($Tabs.get_child_count() - 1, "[empty]")
	return new_tab

func _on_FileDialog_file_selected(path:String):
	match _file_dialog.mode:
		FileDialog.MODE_OPEN_FILE:
			var new_tab = create_new_tab()
			$Tabs.set_tab_title($Tabs.get_child_count() - 1, path.get_file())
			tedit = new_tab.tedit
			tedit.text = load_file(path)
			tedit.fold_all_lines()
			new_tab.editing_path = path
		FileDialog.MODE_SAVE_FILE:
			save_text(tedit.text, path)
			tedit.get_parent().editing_path = path
			tedit.get_parent().content_is_saved = true
			tedit.get_parent().refresh_tab_name()
