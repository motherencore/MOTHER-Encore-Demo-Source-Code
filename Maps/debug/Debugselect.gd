extends Control


var files = []


# Called when the node enters the scene tree for the first time.
func _ready():
	list_files_in_directory("res://Graphics/Battle Sprites/")

func _process(delta):
	if Input.is_action_just_pressed("ui_down"):
		$CanvasLayer/ScrollContainer.scroll_vertical += 13 #130

func list_files_in_directory(path):
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()
	
	for i in range(files.size()):
		#$CanvasLayer/RichTextLabel.text = $CanvasLayer/RichTextLabel.text + "\n" + files[i]
		var label = Label.new()
		label.set_name("enemy " + var2str(i))
		label.set("custom_fonts/font", load("res://Fonts/EB0.tres"))
		label.text = files[i]
		global.currentScene.get_node("CanvasLayer").get_node("ScrollContainer").get_node("VBoxContainer").add_child(label)
	return files
