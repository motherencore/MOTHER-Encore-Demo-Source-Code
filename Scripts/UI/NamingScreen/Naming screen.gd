extends Control

const favFoodStep = 5
const finalStep = 6
const dontCareChoices = 7
const blinkDuration = .3

var maxCharacters := len(tr("LONGEST_POSSIBLE_NAME"))
var is_highlight_played := false
const KEYBOARD_ROWS = 5
var keyboardPanel = 0
var blacklist = tr("BLACKLISTED_NAMES").split(",")
var step = -1
var text = ""
var dontCare = [
	"NAME_NINTEN", 
	"NAME_ANA",
	"NAME_LLOYD",
	"NAME_PIPPI",
	"NAME_TEDDY",
	"FAVFOOD"]

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
var menuFlavor

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
onready var grid4 = $CanvasLayer/NamingBox/CommandGrid/GridContainer4
onready var grid5 = $CanvasLayer/NamingBox/CommandGrid/GridContainer5
onready var changePanelLabel = $CanvasLayer/NamingBox/PressButton/Label
onready var flavorsMenu = $CanvasLayer/Flavors
onready var textSpeedMenu = $CanvasLayer/TextSpeed
onready var buttonPromptsMenu = $CanvasLayer/ButtonPrompts
onready var charAnims = $CharAnims
onready var menuAnims = $MenuAnims
onready var tween = $Tween



# Called when the node enters the scene tree for the first time.
func _ready():
	# LOCALIZATION Code change: Use of csv keys instead of id
	$CanvasLayer / Others / VBoxContainer2 / Flavor.text = "FLAVOR_" + globaldata.menuFlavor.to_upper()
		
	# LOCALIZATION Code change: Use of csv keys instead of id
	$CanvasLayer / Others / VBoxContainer2 / Prompts.text = "MENU_" + globaldata.buttonPrompts.to_upper()
	
	blacklist.append("")
	currentOtherOption = textSpeedMenu
	global.cutscene = true
	global.persistPlayer.pause()
	global.persistPlayer.hide()
	refresh_keys()
	set_dots()

	# LOCALIZATION Useful to debug language stuff
	global.connect("locale_changed", self, "_update_locale")
	
	charAnims.play("Start")
	audioManager.add_audio_player()
	audioManager.play_music_from_id("", "Mother_Earth_Piano.mp3", audioManager.get_audio_player_count() - 1)
	audioManager.set_audio_player_volume(audioManager.get_audio_player_count() - 1, 8)
	yield(get_tree().create_timer(0.5), "timeout")
	step = 0

func _process(delta):
	if step < 6:
		if step > 0:
			$CanvasLayer/NameBox/Indicator.show()
		else:
			$CanvasLayer/NameBox/Indicator.hide()
		if text == "":
			$CanvasLayer/NameBox/Indicator2.hide()
		else:
			$CanvasLayer/NameBox/Indicator2.show()
	
# LOCALIZATION Code change: Instead of switching to lower case, now the method refreshes the keys
# according to current keyboard panel: caps/small, but also hiragana/katakana/romaji, etc.
func refresh_keys():
	var gridId = 0
	for parent in topGrid.get_children():
		if parent is GridContainer && !parent in [grid4, grid5]:
			var letters = tr("KEYBOARD_PANEL%s_GRID%s" % [keyboardPanel,gridId])
			# In case we need to set a different number of columns for different languages
			#parent.columns = len(letters) / KEYBOARD_ROWS
			for i in parent.get_child_count():
					var label = parent.get_child(i)
					var lowerLabel
					if label.get_child_count() == 0:
						lowerLabel = label.duplicate()
						label.add_child(lowerLabel)
						label.percent_visible = 0
						lowerLabel.rect_position = Vector2.ZERO
					else:
						lowerLabel = label.get_child(0)
					var letter = letters[i] if i < len(letters) else ""
					letter = letter.replace("_", "")
					lowerLabel.text = letter
					label.text = "A" if letter != "" else ""
			gridId += 1

	var nextKeyboardPanel = fmod(keyboardPanel + 1, _count_keyboard_panels())
	changePanelLabel.text = "KEYBOARD_PANEL%s_NAME" % nextKeyboardPanel

# LOCALIZATION Code change: Now switches to the next keyboard panel (caps/small, hiragana/katakana/romaji, etc.)
# Adapted so that we can have more than two panels
func toggle_keyboard_panel(dir = 1):
	keyboardPanel = fmod(keyboardPanel + dir, _count_keyboard_panels())
	refresh_keys()
	if arrow.menu_parent.get_child(arrow.cursor_index).text == "":
		set_info() # Resets cursor if selected keyboard key is empty
	if dir != 0:
		if keyboardPanel == _count_keyboard_panels() - 1:
			audioManager.play_sfx(soundEffects["set_lower"], "casing")
		else:
			audioManager.play_sfx(soundEffects["set_upper"], "casing")

# LOCALIZATION Code added: Returns the number of keyboard panels, based on the csv keys
# (Too bad there’s no way to know if one csv entry is empty in a certain language)
func _count_keyboard_panels():
	var i = 0
	while tr("KEYBOARD_PANEL%s_GRID1" % i) != "KEYBOARD_PANEL%s_GRID1" % i:
		i += 1
	return i

# LOCALIZATION Code added: Appends new character to the current name,
# and also merges characters together in languages that require it (specifically Korean)
func _keyboard_char_addition(character):
	var hangul_addition = globaldata.hangul.compose_addition(text, character)
	if hangul_addition:
		text = hangul_addition
		return true
	else:
		if len(text) < maxCharacters:
			text += character
			return true

	return false

# LOCALIZATION Code added: Removes last character from the current name,
# and also remerges characters together in languages that require it (specifically Korean)
func _keyboard_char_removal():
	var hangul_removal = globaldata.hangul.compose_removal(text)
	if hangul_removal:
		text = hangul_removal
	else:
		text = text.left(text.length()-1)

# LOCALIZATION Code added: View refresh when the locale changes
func _update_locale():
	toggle_keyboard_panel(0)
	refresh_keys()
	set_info()

func backspace():
	if text != "":
		# LOCALIZATION Code change: Calls the new method for character removal
		_keyboard_char_removal()
		set_dots()
		arrow.play_sfx("back")
	elif step != 0:
		set_prev_step()
		set_info()
	else:
		arrow.on = false
		audioManager.stop_all_music()
		global.cutscene = false
		
		$Objects/Door.enter()

func set_prev_step():
	if !tween.is_active():
		information[step] = text
		step -= 1
		text = information[step]
		set_info()
		tween.interpolate_property($Objects/Actors, "position:x", 
			$Objects/Actors.position.x, $Objects/Actors.position.x + 320, 1.0,
			Tween.TRANS_QUART, Tween.EASE_IN_OUT)
		tween.start()
		audioManager.play_sfx(soundEffects["prev"], "swish")
		if charAnims.current_animation == "FavFoodLoop":
			charAnims.play("FavFoodEnd")
		
		if step == favFoodStep:
			charAnims.play("FavFoodStart")
			yield(charAnims, "animation_finished")
			charAnims.play("FavFoodLoop")

func is_blocked(name):
	var checkname = name.to_lower().strip_edges()
	if checkname in blacklist:
		return 0
	for index in range(len(information)):
		if index != step and name.strip_edges() == information[index].strip_edges():
			return 1

func highlight_color():
	is_highlight_played = true
	for i in range(2):
		var temporal = bioLabel.text
		if temporal != bioLabel.text:
			break
		bioLabel.modulate = Color(globaldata.dialogHintColor)
		yield(get_tree().create_timer(blinkDuration), "timeout")
		bioLabel.modulate = Color(Color.white)
		yield(get_tree().create_timer(blinkDuration), "timeout")
		if temporal != bioLabel.text:
			break
	is_highlight_played = false

func set_next_step():
	if !tween.is_active():
		match is_blocked(text):
			0:
				bioLabel.text = "NAME_BLOCKED"
				$BlockName.play()
				if !is_highlight_played:
					highlight_color()
					yield(get_tree().create_timer(2), "timeout")
					set_bios()
			1:
				bioLabel.text = "NAME_DUPLICATED"
				$BlockName.play()
				if !is_highlight_played:
					highlight_color()
					yield(get_tree().create_timer(2), "timeout")
					set_bios()
			_:
				information[step] = text
				$OkDesuka.play()
				tween.interpolate_property($Objects/Actors, "position:x", 
					$Objects/Actors.position.x, $Objects/Actors.position.x - 320, 1.0,
					Tween.TRANS_QUART, Tween.EASE_IN_OUT)
				tween.start()
			# LOCALIZATION Code change: Refactored a bit, used constants
				step += 1
				text = information[step]
				match step:
					favFoodStep:
						set_info()
						charAnims.play("FavFoodStart")
						yield(charAnims, "animation_finished")
						charAnims.play("FavFoodLoop")
					finalStep:
						charAnims.play("FavFoodEnd")
						show_others()
					_:
						set_info()
			

func set_info():
	# LOCALIZATION Code change: maxCharacters now depends on the language (Japanese characters are bigger and tell more stuff)
	# + some refactoring here, moved maxCharacters reaffectations into this method
	if step == favFoodStep:
		maxCharacters = len(tr("LONGEST_POSSIBLE_FOOD"))
	else:
		maxCharacters = len(tr("LONGEST_POSSIBLE_NAME"))
	arrow.change_parent(grid, false)
	arrow.cursor_index = 0
	arrow.set_cursor_from_index(0, true)
	set_dots()
	set_bios()

func set_dots():
	nameLabel.text = text
	if len(nameLabel.text) < maxCharacters:
		# LOCALIZATION Code change: To handle the Japanese full-width bullet character as well
		nameLabel.text += tr("SYMBOL_BULLET_NAMING")
		for i in maxCharacters - len(nameLabel.text):
			# LOCALIZATION Code change: To handle the Japanese full-width dot character as well
			nameLabel.text += tr("SYMBOL_DOT")

func set_bios():
	bioLabel.text = "NAME_BIO" + str(step)

# LOCALIZATION Code change due to the use of csv keys
func set_dont_care():
	var index = 0
	for i in dontCareChoices:
		if text == tr(dontCare[step] + str(i)):
			index = fmod(i + 1, dontCareChoices)
			break
	text = tr(dontCare[step] + str(index))
	set_dots()

func show_others():
	arrow.on = false
	menuAnims.play("OthersOpen")
	othersArrow.hide()
	show_other_option(textSpeedMenu)
	if tween.is_active():
		yield(tween, "tween_all_completed")
		othersArrow.set_cursor_from_index(0, false)
		othersArrow.on = true
		othersArrow.show()

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
	confirmArrow.hide()
	$CanvasLayer/ConfirmationLeft/Ninten/Label.text = information[0]
	$CanvasLayer/ConfirmationLeft/Ana/Label.text = information[1]
	$CanvasLayer/ConfirmationLeft/Lloyd/Label.text = information[2]
	$CanvasLayer/ConfirmationLeft/Pippi/Label.text = information[3]
	$CanvasLayer/ConfirmationLeft/Teddy/Label.text = information[4]
	$CanvasLayer/ConfirmationRight/Food/Label.text = information[5]
	menuAnims.play("ConfirmationOpen")
	hide_all_other_options()
	yield(menuAnims, "animation_finished")
	confirmArrow.set_cursor_from_index(0, false)
	confirmArrow.show()
	confirmArrow.on = true

func restart_sequence():
	arrow.on = true
	confirmArrow.on = false
	step = 0
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
	global.cutscene = false
	$OkDesuka.play()
	$Objects/Door2.enter()

func _input(event):
	if step < 6 and step >= 0:
		if event.is_action_pressed("ui_cancel"):
			backspace()
		if event.is_action_pressed("ui_scope"):
			toggle_keyboard_panel()
		if event.is_action_pressed("ui_select"):
			arrow.change_parent(grid4)
		if event.is_action_pressed("ui_focus_next") and text != "":
			set_next_step()
		if event.is_action_pressed("ui_focus_prev") and step != 0:
			set_prev_step()
	elif step == 7:
		if event.is_action_pressed("ui_cancel"):
			restart_sequence()

func _on_arrow_selected(cursor_index):
	match arrow.menu_parent.get_child(cursor_index).name:
		"Don't care":
			set_dont_care()
			arrow.play_sfx("cursor2")
		"Backspace":
			backspace()
		"OK":
			if text != "":
				set_next_step()
		_:
			var character = ""
			if arrow.menu_parent.get_child(cursor_index).percent_visible == 1:
				# LOCALIZATION Code change: added tr() for editable keyboard keys
				character = tr(arrow.menu_parent.get_child(cursor_index).text)
			else :
				# LOCALIZATION Code change: added tr() for editable keyboard keys
				character = tr(arrow.menu_parent.get_child(cursor_index).get_child(0).text)
			
			# LOCALIZATION Code change: Calls the new method for character addition
			var has_text_changed = _keyboard_char_addition(character)
			if has_text_changed:
				set_dots()
				arrow.play_sfx("cursor2")

func _on_arrow_failed_move(dir):
	var index = 0
	match arrow.menu_parent:
		grid:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid3)
					arrow.set_cursor_from_index(arrow.cursor_index + grid3.columns - 1)
				Vector2(1, 0):
					arrow.change_parent(grid2)
				Vector2(0, -1):
					arrow.change_parent(grid4)
				Vector2(0, 1):
					arrow.change_parent(grid4)
		grid2:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid)
				Vector2(1, 0):
					arrow.change_parent(grid3)
				Vector2(0, -1):
					if arrow.cursor_index % grid2.columns > grid2.columns/2:
						arrow.change_parent(grid5)
						arrow.set_cursor_from_index(0)
					else:
						arrow.change_parent(grid4)
						arrow.set_cursor_from_index(0)
				Vector2(0, 1):
					if arrow.cursor_index > 25:
						arrow.change_parent(grid5)
					else:
						arrow.change_parent(grid4)
		grid3:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid2)
				Vector2(1, 0):
					arrow.change_parent(grid)
					arrow.set_cursor_from_index(arrow.cursor_index - grid.columns + 1)
				Vector2(0, -1):
					arrow.change_parent(grid5)
				Vector2(0, 1):
					arrow.change_parent(grid5)
		grid4:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid5)
					arrow.set_cursor_from_index(arrow.cursor_index + grid5.columns - 1)
				Vector2(1, 0):
					arrow.change_parent(grid5)
				Vector2(0, -1):
					arrow.change_parent(grid)
				Vector2(0, 1):
					arrow.change_parent(grid)
					arrow.set_cursor_from_index(0)
		grid5:
			match dir:
				Vector2(-1, 0):
					arrow.change_parent(grid4)
				Vector2(1, 0):
					arrow.change_parent(grid4)
					arrow.set_cursor_from_index(arrow.cursor_index - grid4.columns + 1)
				Vector2(0, -1):
					arrow.change_parent(grid3)
				Vector2(0, 1):
					arrow.change_parent(grid3)
					if arrow.cursor_index == 0:
						arrow.set_cursor_from_index(0)
					else:
						arrow.set_cursor_from_index(grid3.columns - 1)

func _on_OthersArrow_moved(dir):
	match othersArrow.cursor_index:
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
	if tween.is_active():
		yield(tween, "tween_all_completed")
		if tween.is_active():
			yield(tween, "tween_all_completed")
	match cursor_index:
		0:
			textSpeedArrow.on = true
			textSpeedArrow.show()
			match globaldata.textSpeed:
				0.02:
					textSpeedArrow.set_cursor_from_index(0, false)
				0.035:
					textSpeedArrow.set_cursor_from_index(1, false)
				0.05:
					textSpeedArrow.set_cursor_from_index(2, false)
			textSpeedMenu._on_TextSpeedArrow_moved(null)
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
			buttonPromptsArrow.on = true
			buttonPromptsArrow.show()
			match globaldata.buttonPrompts:
				"Both":
					buttonPromptsArrow.set_cursor_from_index(0, false)
				"Objects":
					buttonPromptsArrow.set_cursor_from_index(1, false)
				"NPCs":
					buttonPromptsArrow.set_cursor_from_index(2, false)
				"None":
					buttonPromptsArrow.set_cursor_from_index(3, false)
			buttonPromptsMenu._on_ButtonPromptsArrow_moved(null)
		3:
			step += 1
			show_confirmation()

func _on_OthersArrow_cancel():
	hide_all_other_options()
	othersArrow.on = false
	arrow.on = true
	arrow.hide()
	arrow.set_cursor_from_index(0, false)
	menuAnims.play("OthersClose")
	if tween.is_active():
		yield(tween, "tween_all_completed")
	set_prev_step()
	
	


func _on_TextSpeedArrow_selected(cursor_index):
	othersArrow.on = true
	textSpeedArrow.on = false
	textSpeedArrow.hide()
	# LOCALIZATION Code change: Use of csv keys here
	match cursor_index:
		0:
			globaldata.textSpeed = 0.02
			$CanvasLayer/Others/VBoxContainer2/Speed.text = "MENU_FAST"
		1:
			globaldata.textSpeed = 0.035
			$CanvasLayer/Others/VBoxContainer2/Speed.text = "MENU_MEDIUM"
		2:
			globaldata.textSpeed = 0.05
			$CanvasLayer/Others/VBoxContainer2/Speed.text = "MENU_SLOW"


func _on_TextSpeedArrow_cancel():
	othersArrow.on = true
	textSpeedArrow.on = false
	textSpeedArrow.hide()
	textSpeedArrow.get_current_item().percent_visible = 1


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
	# LOCALIZATION Code changed: Use of csv keys here
	$CanvasLayer/Others/VBoxContainer2/Flavor.text = "FLAVOR_" + globaldata.menuFlavor.to_upper()
	flavorsArrow.hide()

func _on_FlavorsArrow_cancel():
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	othersArrow.on = true
	flavorsArrow.on = false
	flavorsArrow.hide()

func _on_ButtonPromptsArrow_selected(cursor_index):
	# LOCALIZATION Code change: Relying on cursor position instead of node text
	match cursor_index:
		0:
			globaldata.buttonPrompts = "Both"
		1:
			globaldata.buttonPrompts = "Objects"
		2:
			globaldata.buttonPrompts = "NPCs"
		3:
			globaldata.buttonPrompts = "None"
	$CanvasLayer/Others/VBoxContainer2/Prompts.text = buttonPromptsArrow.get_current_item().text
	othersArrow.on = true
	buttonPromptsArrow.on = false
	buttonPromptsArrow.hide()

func _on_ButtonPromptsArrow_cancel():
	othersArrow.on = true
	buttonPromptsArrow.on = false
	buttonPromptsArrow.hide()
	match globaldata.buttonPrompts:
		"Both":
			buttonPromptsMenu._on_ButtonPromptsArrow_moved(Vector2.ZERO)
		"Objects":
			buttonPromptsMenu._on_ButtonPromptsArrow_moved(Vector2.ZERO)
		"NPCs":
			buttonPromptsMenu._on_ButtonPromptsArrow_moved(Vector2.ZERO)
		"None":
			buttonPromptsMenu._on_ButtonPromptsArrow_moved(Vector2.ZERO)

func _on_ConfirmationArrow_selected(cursor_index):
	confirmArrow.on = false
	match cursor_index:
		0:
			end_sequence()
		1:
			restart_sequence()


func _on_ConfirmationArrow_cancel():
	restart_sequence()
