tool
extends Control

onready var dock := get_parent().get_parent()
onready var tedit := get_node("TextEdit")

var editing_path := ""
var content_is_saved := true

func _ready():
	dock.colors = dock.load_json("settings/syntax_colors")
	dock.keywords = dock.load_json("settings/syntax_keywords")
	
	setup_colors()
	setup_menus()

func setup_colors():
	tedit.set("custom_colors/function_color", dock.colors.function)
	tedit.set("custom_colors/number_color", dock.colors.number)
	tedit.set("custom_colors/member_variable_color", dock.colors.member_variable)
	
	for group in dock.keywords.groups:
		for word in group.words:
			tedit.add_keyword_color(word, dock.colors[group.color])
	
	for area in dock.keywords.areas:
		tedit.add_color_region (
				area.char_A,
				area.char_B,
				dock.colors[area.color],
				not area.multiline
			)

func _on_BtnNew_pressed():
	get_parent().get_parent().create_new_tab()

func _on_BtnLoad_pressed():
	dock._file_dialog.mode = FileDialog.MODE_OPEN_FILE
	dock._file_dialog.popup_centered(Vector2(800, 700))

func _on_BtnClose_pressed():
	#if content_is_saved:
		$TextEdit/CloseUnsavedPopup.dialog_text = "The file \""+(editing_path.get_file() if editing_path else "Untitled")+"\".\nAre you really, really sure you want to close it?"
		$TextEdit/CloseUnsavedPopup.popup_centered(Vector2(100,64))
		yield($TextEdit/CloseUnsavedPopup, "popup_hide")
		get_parent().get_parent().emit_signal("_decided_closing")
	#else:
	#	get_parent().get_parent().emit_signal("_decided_closing")
	#	get_parent().remove_child(self)
	#	queue_free()

func _on_CloseUnsavedPopup_confirmed():
	get_parent().remove_child(self)
	queue_free()

func _on_BtnSave_pressed():
	if editing_path == "":
		_on_BtnSaveAs_pressed()
		return
	get_parent().get_parent().save_text(tedit.text, editing_path)
	content_is_saved = true
	refresh_tab_name()

func _on_BtnSaveAs_pressed():
	dock.tedit = tedit
	dock._file_dialog.mode = FileDialog.MODE_SAVE_FILE
	dock._file_dialog.popup_centered(Vector2(800, 700))

func get_index() -> int:
	var index = 0
	for i in get_parent().get_children():
		if i == self:
			break
		index += 1
	return index

func refresh_tab_name() -> void:
	var file_name = editing_path.get_file()
	set_tab_name(file_name if file_name else "Unsaved", not content_is_saved)

func set_tab_name(tab_name:String, unsaved:bool) -> void:
	var tabs = get_parent() as TabContainer
	tabs.set_tab_title(get_index(), "(!) " + tab_name if unsaved else tab_name)

func _on_TextEdit_text_changed():
	if content_is_saved:
		content_is_saved = false
		refresh_tab_name()

var menu_file:MenuButton
var menu_text:MenuButton
var menu_powr:MenuButton

func setup_menus():
	menu_file = get_node("HBoxContainer/MenuFile")  as MenuButton
	menu_text = get_node("HBoxContainer/MenuText")  as MenuButton
	menu_powr = get_node("HBoxContainer/MenuPower") as MenuButton
	
	menu_file.get_popup().connect("id_pressed", self, "menu_file_pressed")
	menu_text.get_popup().connect("id_pressed", self, "menu_text_pressed")
	menu_powr.get_popup().connect("id_pressed", self, "menu_powr_pressed")


func menu_file_pressed(id):
	match id:
		0:
			# Create New Empty Tab
			_on_BtnNew_pressed()
		1:
			# Open File
			_on_BtnLoad_pressed()
		2:
			# Close
			_on_BtnClose_pressed()
		3:
			# Save As
			_on_BtnSave_pressed()
		4:
			# Save As
			_on_BtnSaveAs_pressed()
		
var show_find_replace_bar := false

func menu_text_pressed(id):
	match id:
		0:
			show_find_replace_bar = not show_find_replace_bar
			menu_text.get_popup().set_item_checked(id, show_find_replace_bar)
			$FindReplaceBar.visible = show_find_replace_bar
		1:
			tedit.fold_all_lines()
		2:
			tedit.unfold_all_lines()
		3:
			var t = tedit.get_selection_text()
			var x = Expression.new()
			x.parse(t)
			var r = x.execute()
			tedit.get_sele

func menu_powr_pressed(id):
	match id:
		0:
			# Power Closing
			var parent = get_parent()
			var all_tabs = get_parent().get_children()
			print("Attempting to close "+str(all_tabs.size())+" tabs.")
			for tab in all_tabs:
				tab._on_BtnClose_pressed()
				yield(parent.get_parent(), "_decided_closing")
			parent.get_child(0).queue_free()
			parent.get_parent().create_new_tab()


func _on_TimerDestroy():
	queue_free()
