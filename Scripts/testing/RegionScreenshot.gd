extends ReferenceRect
class_name RegionScreenshot

var viewport : Viewport
var texture : Texture

func _input(event):
	if event.is_action_pressed("ui_F1"):
		get_parent().get_node("NinePatchRect/Label").text = "Screenshotting..."
		take_screenshot(get_parent().get_node("Control"))

func take_screenshot(parent : Node):
	yield(get_tree(), "idle_frame")
	
	var subparent = Node2D.new()
	var children = parent.get_children().duplicate()
	
	viewport = Viewport.new()
	viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	viewport.size = rect_size
	
	# Borrow the nodes to screenshot
	for child in children:
		if child == self: continue
		parent.remove_child(child)
		subparent.add_child(child)
	
	get_parent().add_child(viewport)
	viewport.add_child(subparent)
	
	if "global_position" in parent:
		subparent.position = - rect_global_position + parent.global_position
	else:
		subparent.position = - rect_global_position + parent.rect_global_position
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
		
	texture = viewport.get_texture()
	var img = texture.get_data()
	img.flip_y()
	img.save_png("res://screenshot.png")
	
	# Give the notes back, politely.
	for child in children:
		if child == self: continue
		subparent.remove_child(child)
		parent.add_child(child)
	
	subparent.queue_free()
	viewport.queue_free()
	
	get_parent().get_node("NinePatchRect/Label").text = "Done!"
	print("Screenshot taken!")
	audioManager.play_sfx(load("res://Audio/Sound effects/Save.mp3"), "menu")
	
	yield(get_tree().create_timer(1),"timeout")
	
	get_parent().get_node("NinePatchRect/Label").text = "Press F1 to screenshot"
