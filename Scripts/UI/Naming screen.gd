extends Control

const maxNameCharacters := 7
const maxFoodCharcter := 13
const finalStep = 5

var maxCharacters := 7

var step = 0
var text = ""
var dontCare = [
	["Ninten", "Ken", "Douglas", "Jeremy", "Mark", "Ryu", "Colin"],
	["Ana", "Jill", "Sylvia", "Catrine", "Carrie", "Nina", "Emily"],
	["Lloyd", "Brian", "Albert", "Louis", "Kenny", "Jean", "Maxwell"],
	["Pippi", "Alex", "Penny", "Ferris", "Natalie", "Katt", "Ashley"],
	["Teddy", "Joe", "Leo", "Jeb", "Alec", "Rand", "Dallas"],
	["Prime Rib", "Bean Paste", "Creme Cookies", "Pasta", "Omelets", "Custard", "Salmon"],
]

var biographies = [
	"What is this boy's name?",
	"What is this girl's name?",
	"This other boy's name?",
	"This other girl's name?",
	"This last boy's name?",
	"What is your favorite homemade food?"
]

var information = [
	"", #ninten
	"", #ana
	"", #lloyd
	"", #pippi
	"", #teddy
	"", #favorite food
	"", #favorite thing
]

var soundEffects = {
	"set_upper": load("res://Audio/Sound effects/M3/menu_open2.wav"),
	"set_lower": load("res://Audio/Sound effects/M3/menu_close2.wav"),
	"next": load("res://Audio/Sound effects/M3/menu_open.wav"),
	"prev": load("res://Audio/Sound effects/M3/menu_close.wav")
}

var currentOtherOption = null

var t = 0
var textSpeed = 0.08
var finished = false
var currentScrollingLabel = null


onready var bioLabel = $CanvasLayer/NameBox/Label
onready var nameLabel = $CanvasLayer/NameBox/name/Label
onready var arrow = $CanvasLayer/NamingBox/arrow
onready var othersArrow = $CanvasLayer/Others/OthersArrow
onready var textSpeedArrow = $CanvasLayer/TextSpeed/TextSpeedArrow
onready var flavorsArrow = $CanvasLayer/Flavors/FlavorsArrow
onready var buttonPromptsArrow = $CanvasLayer/ButtonPrompts/ButtonPromptsArrow
onready var confirmArrow = $CanvasLayer/ConfirmationRight/Surely/ConfirmationArrow
onready var topGrid = $CanvasLayer/NamingBox/Grid
onready var grid = $CanvasLayer/NamingBox/Grid/GridContainer
onready var grid2 = $CanvasLayer/NamingBox/Grid/GridContainer2
onready var grid3 = $CanvasLayer/NamingBox/Grid/GridContainer3
onready var grid4 = $CanvasLayer/NamingBox/Grid/GridContainer4
onready var grid5 = $CanvasLayer/NamingBox/Grid/GridContainer5
onready var flavorsMenu = $CanvasLayer/Flavors
onready var textSpeedMenu = $CanvasLayer/TextSpeed
onready var buttonPromptsMenu = $CanvasLayer/ButtonPrompts
onready var charAnims = $CharAnims
onready var menuAnims = $MenuAnims
onready var tween = $Tween



# Called when the node enters the scene tree for the first time.
func _ready():
	$CanvasLayer/Others/VBoxContainer2/Flavor.text = globaldata.menuFlavor
	currentOtherOption = textSpeedMenu
	global.cutscene = true
	global.persistPlayer.position = Vector2(160, 90)
	global.persistPlayer.pause()
	global.persistPlayer.hide()
	set_dots()
	charAnims.play("Start")
	audioManager.play_music("", "Mother_Earth_Piano.mp3")
	audioManager.set_audio_player_volume(0, 12)

func _process(delta):
	if step > 0:
		$CanvasLayer/NameBox/Indicator.show()
	else:
		$CanvasLayer/NameBox/Indicator.hide()
	if text == "":
		$CanvasLayer/NameBox/Indicator2.hide()
	else:
		$CanvasLayer/NameBox/Indicator2.show()
	
	

func create_lower():
	for parent in topGrid.get_children():
		if !parent in [grid4, grid5]:
			for i in parent.get_child_count():
				var label = parent.get_child(i)
				if label.text.to_lower() != label.text:
					var lowerLabel = label.duplicate()
					
					lowerLabel.text = label.text.to_lower()
					label.add_child(lowerLabel)
					label.percent_visible = 0
					lowerLabel.rect_position = Vector2.ZERO

func erase_lower():
	for parent in topGrid.get_children():
		for i in parent.get_child_count():
			var label = parent.get_child(i)
			if label.get_child_count() != 0:
				label.get_child(0).queue_free()
				label.percent_visible = 1

func toggle_lower_upper():
	if grid.get_child(0).get_child_count() == 0:
		create_lower()
		audioManager.play_sfx(soundEffects["set_lower"], "casing")
	else:
		erase_lower()
		audioManager.play_sfx(soundEffects["set_upper"], "casing")
			
func backspace():
	if text != "":
		text = text.left(text.length()-1)
		set_dots()
		arrow.play_sfx("back")
	elif step != 0:
		set_prev_step()
		set_info()
	else:
		arrow.on = false
		audioManager.stop_all_music()
		$Objects/Door.enter()

func set_prev_step():
	if !tween.is_active():
		information[step] = text
		step -= 1
		text = information[step]
		if step < 5:
			maxCharacters = maxNameCharacters
		set_info()
		tween.interpolate_property($Objects/Actors, "position:x", 
			$Objects/Actors.position.x, $Objects/Actors.position.x + 320, 1.0,
			Tween.TRANS_QUART, Tween.EASE_IN_OUT)
		tween.start()
		audioManager.play_sfx(soundEffects["prev"], "swish")
		if charAnims.current_animation == "FavFoodLoop":
			charAnims.play("FavFoodEnd")

func set_next_step():
	if !tween.is_active():
		$OkDesuka.play()
		tween.interpolate_property($Objects/Actors, "position:x", 
			$Objects/Actors.position.x, $Objects/Actors.position.x - 320, 1.0,
			Tween.TRANS_QUART, Tween.EASE_IN_OUT)
		tween.start()
		information[step] = text
		match step:
			4:
				maxCharacters = maxFoodCharcter
				step += 1
				text = information[step]
				set_info()
				charAnims.play("FavFoodStart")
				yield(charAnims, "animation_finished")
				charAnims.play("FavFoodLoop")
			5:
				step += 1
				charAnims.play("FavFoodEnd")
				show_others()
			_:
				maxCharacters = maxNameCharacters
				step += 1
				text = information[step]
				set_info()
		

func set_info():
	arrow.change_parent(grid, false)
	arrow.cursor_index = 0
	arrow.set_cursor_from_index(0, true)
	set_dots()
	set_bios()

func set_dots():
	nameLabel.text = text
	if len(nameLabel.text) != maxCharacters:
		nameLabel.text += "@"
		for i in maxCharacters - len(nameLabel.text):
			nameLabel.text += "`"

func set_bios():
	bioLabel.text = biographies[step]

func set_dont_care():
	if text in dontCare[step]:
		var index = dontCare[step].find(text) + 1
		if index >= dontCare[step].size():
			index = 0
		text = dontCare[step][index]
	else:
		text = dontCare[step][0]
	set_dots()

func show_others():
	arrow.on = false
	othersArrow.on = true
	menuAnims.play("OthersOpen")
	show_other_option(textSpeedMenu)

func show_other_option(menu):
	hide_all_other_options()
	currentOtherOption = menu
	if tween.is_active():
		yield(tween, "tween_all_completed")
	if currentOtherOption == menu:
		tween.interpolate_property(menu, "rect_position:x",
			menu.rect_position.x, 184, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()

func hide_all_other_options():
	currentOtherOption = null
	tween.stop_all()
	for i in [textSpeedMenu, flavorsMenu, buttonPromptsMenu]:
		tween.interpolate_property(i, "rect_position:x",
			i.rect_position.x, 328, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()

func show_confirmation():
	othersArrow.on = false
	confirmArrow.on = true
	$CanvasLayer/ConfirmationLeft/Ninten/Label.text = information[0]
	$CanvasLayer/ConfirmationLeft/Ana/Label.text = information[1]
	$CanvasLayer/ConfirmationLeft/Lloyd/Label.text = information[2]
	$CanvasLayer/ConfirmationLeft/Pippi/Label.text = information[3]
	$CanvasLayer/ConfirmationLeft/Teddy/Label.text = information[4]
	$CanvasLayer/ConfirmationRight/Food/Label.text = information[5]
	menuAnims.play("ConfirmationOpen")
	hide_all_other_options()

func restart_sequence():
	arrow.on = true
	confirmArrow.on = false
	step = 0
	maxCharacters = maxNameCharacters
	text = information[step]
	set_info()
	menuAnims.play("Naming Open")
	tween.interpolate_property($Objects/Actors, "position:x", 
		$Objects/Actors.position.x, 0, 1.5,
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()

func end_sequence():
	arrow.on = false
	global.cutscene = false
	globaldata.ninten.nickname = information[0]
	globaldata.ana.nickname = information[1]
	globaldata.lloyd.nickname = information[2]
	globaldata.pippi.nickname = information[3]
	globaldata.teddy.nickname = information[4]
	globaldata.favoriteFood = information[5]
	menuAnims.play("ConfirmationClose")
	$Objects/Door2.enter()

func _input(event):
	if step < 6:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
			backspace()
		if event.is_action_pressed("ui_ctrl"):
			toggle_lower_upper()
		if event.is_action_pressed("ui_select"):
			arrow.change_parent(grid4)
		if event.is_action_pressed("ui_focus_next") and text != "":
			set_next_step()
		if event.is_action_pressed("ui_focus_prev") and step != 0:
			set_prev_step()
	elif step == 7:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
			restart_sequence()

func _on_arrow_selected(cursor_index):
	match arrow.menu_parent.get_child(cursor_index).text:
		"Don't care":
			set_dont_care()
			arrow.play_sfx("cursor2")
		"Backspace":
			backspace()
		"OK":
			if text != "":
				set_next_step()
		_:
			if len(text) != maxCharacters:
				var character = ""
				if arrow.menu_parent.get_child(cursor_index).percent_visible == 1:
					character = arrow.menu_parent.get_child(cursor_index).text
				else:
					character = arrow.menu_parent.get_child(cursor_index).get_child(0).text
				text += character
				set_dots()
				arrow.play_sfx("cursor2")

func _on_arrow_failed_move(dir):
	var index = 0
	match arrow.menu_parent:
		grid:
			match dir:
				Vector2(1, 0):
					arrow.change_parent(grid2)
				Vector2(0, 1):
					arrow.change_parent(grid4)
		grid2:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid)
				Vector2(1, 0):
					arrow.change_parent(grid3)
				Vector2(0, 1):
					if arrow.cursor_index > 25:
						arrow.change_parent(grid5)
					else:
						arrow.change_parent(grid4)
		grid3:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid2)
				Vector2(0, 1):
					arrow.change_parent(grid5)
		grid4:
			match dir:
				Vector2(1, 0):
					arrow.change_parent(grid5)
				Vector2(0, -1):
					arrow.change_parent(grid)
		grid5:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid4)
				Vector2(0, -1):
					arrow.change_parent(grid3)

func _on_OthersArrow_moved(dir, cursor_index):
	match cursor_index:
		0:
			show_other_option(textSpeedMenu)
		1:
			show_other_option(flavorsMenu)
		2:
			show_other_option(buttonPromptsMenu)
		3:
			hide_all_other_options()

func _on_OthersArrow_selected(cursor_index):
	othersArrow.on = false
	match cursor_index:
		0:
			textSpeedArrow.on = true
			textSpeedArrow.show()
			match globaldata.textSpeed:
				0.2:
					textSpeedArrow.set_cursor_from_index(0, false)
				0.35:
					textSpeedArrow.set_cursor_from_index(1, false)
				0.5:
					textSpeedArrow.set_cursor_from_index(2, false)
		1:
			flavorsArrow.on = true
			flavorsArrow.show()
			match globaldata.menuFlavor:
				"Plain":
					flavorsArrow.set_cursor_from_index(0, false)
				"Mint":
					flavorsArrow.set_cursor_from_index(1, false)
				"Strawberry":
					flavorsArrow.set_cursor_from_index(2, false)
				"Banana":
					flavorsArrow.set_cursor_from_index(3, false)
				"Peanut":
					flavorsArrow.set_cursor_from_index(4, false)
				"Grape":
					flavorsArrow.set_cursor_from_index(5, false)
				"Melon":
					flavorsArrow.set_cursor_from_index(6, false)
		2:
			pass
		3:
			step += 1
			show_confirmation()

func _on_TextSpeedArrow_moved(dir, new_index):
	match new_index:
		0:
			currentScrollingLabel = $CanvasLayer/TextSpeed/VBoxContainer/Fast
		1:
			currentScrollingLabel = $CanvasLayer/TextSpeed/VBoxContainer/Medium
		2:
			currentScrollingLabel = $CanvasLayer/TextSpeed/VBoxContainer/Slow



func _on_TextSpeedArrow_selected(cursor_index):
	othersArrow.on = true
	textSpeedArrow.on = false
	textSpeedArrow.hide()
	$CanvasLayer/Others/VBoxContainer2/Speed.text = textSpeedArrow.get_menu_item_at_index(cursor_index).text
	match cursor_index:
		0:
			globaldata.textSpeed = 0.02
		1:
			globaldata.textSpeed = 0.035
		2:
			globaldata.textSpeed = 0.05


func _on_TextSpeedArrow_cancel():
	othersArrow.on = true
	textSpeedArrow.on = false
	textSpeedArrow.hide()


func _on_FlavorsArrow_moved(dir, new_index):
	match new_index:
		0:
			uiManager.set_menu_flavors("Plain")
		1:
			uiManager.set_menu_flavors("Mint")
		2:
			uiManager.set_menu_flavors("Strawberry")
		3:
			uiManager.set_menu_flavors("Banana")
		4:
			uiManager.set_menu_flavors("Peanut")
		5:
			uiManager.set_menu_flavors("Grape")
		6:
			uiManager.set_menu_flavors("Melon")

func _on_FlavorsArrow_selected(cursor_index):
	match cursor_index:
		0:
			globaldata.menuFlavor = "Plain"
		1:
			globaldata.menuFlavor = "Mint"
		2:
			globaldata.menuFlavor = "Strawberry"
		3:
			globaldata.menuFlavor = "Banana"
		4:
			globaldata.menuFlavor = "Peanut"
		5:
			globaldata.menuFlavor = "Grape"
		6:
			globaldata.menuFlavor = "Melon"
	othersArrow.on = true
	flavorsArrow.on = false
	$CanvasLayer/Others/VBoxContainer2/Flavor.text = globaldata.menuFlavor
	flavorsArrow.hide()
	


func _on_FlavorsArrow_cancel():
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	othersArrow.on = true
	flavorsArrow.on = false
	flavorsArrow.hide()


func _on_ConfirmationArrow_selected(cursor_index):
	match cursor_index:
		0:
			end_sequence()
		1:
			restart_sequence()




