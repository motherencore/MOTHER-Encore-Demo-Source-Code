extends CanvasLayer

const VOLUME_GRADES = 11

export var from_save : = true
export var always_visible : = false
export var include_quit : = true

signal back
signal close_to_title

onready var topMenu = $OptionsMenu/NinePatchRect/VBoxContainer
onready var optionsLabel = $OptionsMenu/NinePatchRect/OptionsLabel
onready var fileSettingsMenu = $OptionsMenu/NinePatchRect/FileSettings
onready var fileSettingsMenuContent = $OptionsMenu/NinePatchRect/FileSettings/VBoxContainer
onready var settingsMenu = $OptionsMenu/NinePatchRect/Settings
onready var settingsMenuContent = $OptionsMenu/NinePatchRect/Settings/VBoxContainer
onready var confirm = $OptionsMenu/Confirm
onready var confirmLabel = $OptionsMenu/Confirm/VBoxContainer/ConfirmLabel
onready var confirmArrow = $OptionsMenu/Confirm/VBoxContainer/ConfirmArrow
onready var arrow = $OptionsMenu/NinePatchRect/arrow
onready var textSpeedMenu = $OptionsMenu/TextSpeed
onready var textSpeedArrow = $OptionsMenu/TextSpeed/TextSpeedArrow
onready var flavorsMenu = $OptionsMenu/Flavors
onready var flavorsArrow = $OptionsMenu/Flavors/FlavorsArrow
onready var genericOptionMenu = $OptionsMenu/GenericOption
onready var buttonPromptsMenu = $OptionsMenu/ButtonPrompts
onready var buttonPromptsArrow = $OptionsMenu/ButtonPrompts/ButtonPromptsArrow
onready var controlsMenu = $OptionsMenu/ControlsUI

var optnCursorIndex = 0
var languageValues
var volumeValues

var confirmationType

func _ready():
	#$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/FullScreenSwitch/ArrowLMargin/ArrowL.playing = true
	#$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/FullScreenSwitch/ArrowRMargin/ArrowR.playing = true

	$OptionsMenu.hide()
	languageValues = global.get_supported_languages().duplicate()
	languageValues.sort_custom(self, "_sort_languages")
	volumeValues = []
	for i in range(VOLUME_GRADES - 1,-1,-1):
		volumeValues.append(_volume_units_to_db(i))
	if not from_save:
		_switch_panel(1)
	if always_visible:
		Show_options()
	if not include_quit:
		$OptionsMenu/NinePatchRect/VBoxContainer/TitleScreenLabel.hide()
		$OptionsMenu/NinePatchRect/VBoxContainer/CloseGameLabel.hide()
	global.connect("settings_changed", self, "_refresh")
	global.connect("locale_changed", self, "_refresh")
	controlsMenu.connect("exited", self, "_on_SubMenuArrow_cancel")
	genericOptionMenu.connect("selected", self, "_on_GenericOption_selected")
	genericOptionMenu.connect("cancel", self, "_on_SubMenuArrow_cancel")

func _sort_languages(a, b):
	return tr(_get_language_as_text(a)) < tr(_get_language_as_text(b))

func _is_language_enabled(lang_code):
	return lang_code in global.LANGUAGES_RELEASE

func Show_options():
	$OptionsMenu.show()
	arrow.on = true
	# LOCALIZATION Code change: Initial view refresh
	_refresh()


# LOCALIZATION Code added: Change options with left/right or prev/next keys

func _on_arrow_selected(cursor_index):
	arrow.on = false
	if arrow.menu_parent == topMenu:
		# LOCALIZATION Code added: Saving cursor position for later
		optnCursorIndex = cursor_index
		_switch_panel(cursor_index)

	# LOCALIZATION Code added: Text speed, flavors, button prompts
	elif arrow.menu_parent == fileSettingsMenuContent:
		match cursor_index:
			0: # Text Speed
				textSpeedMenu.show()
				textSpeedArrow.on = true
				textSpeedMenu._on_TextSpeedArrow_moved(null)
			1: # Menu Flavors
				flavorsMenu.show()
				flavorsArrow.on = true
			2: # Button Prompts
				buttonPromptsMenu.show()
				buttonPromptsArrow.on = true
				buttonPromptsMenu.refresh(true)
		_refresh()
							
	# LOCALIZATION Code added: Toggle fullscreen, language, volume)
	elif arrow.menu_parent == settingsMenuContent:
		match cursor_index:
			0: # Language
				genericOptionMenu.open(languageValues, tr("LANGUAGE_CODE"), funcref(self,"_get_language_as_text"), funcref(self, "_is_language_enabled"))
			1: # Resolution
				var resolutions = _get_resolutions()
				genericOptionMenu.open(resolutions, resolutions[globaldata.winSize - 1])
			2: # Full Screen
				#_show_generic_options(["OPTIONS_ON", "OPTIONS_OFF"], _get_fullscreen_as_text(OS.window_fullscreen))
				global.toggle_fullscreen()
				_refresh()
				arrow.on = true
			3: # Music Volume
				var volumeIdx = volumeValues.find(_discretize_volume(globaldata.musicVolume))
				volumeIdx = max(volumeIdx - 1, 0)
				global.set_music_volume(volumeValues[volumeIdx])
				_refresh()
				arrow.on = true
			4: # SFX Volume
				var volumeIdx = volumeValues.find(_discretize_volume(globaldata.sfxVolume))
				volumeIdx = max(volumeIdx - 1, 0)
				global.set_sfx_volume(volumeValues[volumeIdx])
				_refresh()
				arrow.on = true
			5: # Controls
				controlsMenu.activate()


# -1	Main options menu
# 0		File settings options menu
# 1		General settings options menu
func _switch_panel(panel, set_cursor = true):
	match panel:
		-1: # Main Options
			fileSettingsMenu.hide()
			settingsMenu.hide()
			confirm.hide()
			topMenu.show()
			arrow.on = true
			optionsLabel.text = "MENU_TITLE_OPTIONS"
			_resize_to_fit(topMenu)
			if set_cursor:
				arrow.change_parent(topMenu, false)
				arrow.set_cursor_from_index(optnCursorIndex, true)
		0: # File Settings
			fileSettingsMenu.show()
			topMenu.hide()
			arrow.on = true
			optionsLabel.text = "OPTIONS_FILESETTINGS"
			_resize_to_fit(fileSettingsMenuContent)
			if set_cursor:
				arrow.change_parent(fileSettingsMenuContent, false)
				arrow.set_cursor_from_index(0, true)
		1: # Settings
			settingsMenu.show()
			topMenu.hide()
			arrow.on = true
			optionsLabel.text = "OPTIONS_SETTINGS"
			_resize_to_fit(settingsMenuContent)
			if set_cursor:
				arrow.change_parent(settingsMenuContent, false)
				arrow.set_cursor_from_index(0, true)
		2: # Title Screen
			yield(get_tree(), "idle_frame")
			confirm.show()
			confirmLabel.text = "OPTIONS_TITLESCREEN_CONFIRM"
			confirmationType = "TitleScreen"
			confirmArrow.on = true
			if set_cursor:
				confirmArrow.set_cursor_from_index(0, false)
		3: # Close game
			yield(get_tree(), "idle_frame")
			confirm.show()
			confirmLabel.text = "OPTIONS_QUIT_CONFIRM"
			confirmationType = "Quit"
			confirmArrow.on = true
			if set_cursor:
				confirmArrow.set_cursor_from_index(0, false)

func _on_arrow_cancel():
	if arrow.menu_parent != topMenu and from_save:
		arrow.play_sfx('back')
		_switch_panel(-1)
	else :
		# LOCALIZATION Code added: Saving what's changed in the settings
		global.save_settings()
		arrow.on = false
		Input.action_release("ui_cancel")
		emit_signal("back")
		if always_visible:
			$OptionsMenu/Door.enter()
		else:
			$OptionsMenu.hide()

func _on_ConfirmArrow_selected(cursor_index):
	match cursor_index:
		0:
			match confirmationType:
				"TitleScreen":
					global.save_settings()
					$OptionsMenu/Door.enter()
					$OptionsMenu.hide()
					global.stop_playtime()
					emit_signal("close_to_title")
				"Quit":
					global.save_settings()
					get_tree().quit()
			arrow.on = false
		1:
			_switch_panel(-1)
			arrow.on = true
	confirmArrow.on = false

func _on_ConfirmArrow_cancel():
	arrow.play_sfx('cursor1')
	_switch_panel(-1)
	arrow.on = true
	confirmArrow.on = false

# LOCALIZATION Code added: Duplicated the Text Speed component, handling confirmation here
func _on_TextSpeedArrow_selected(cursor_index):
	arrow.on = true
	textSpeedArrow.on = false
	textSpeedMenu.hide()

	globaldata.textSpeed = globaldata.TEXT_SPEEDS[cursor_index]
	_refresh()

# LOCALIZATION Code added: Duplicated the Flavors component, handling confirmation here
func _on_FlavorsArrow_selected(cursor_index):
	arrow.on = true
	flavorsArrow.on = false
	flavorsMenu.hide()

	globaldata.menuFlavor = globaldata.FLAVORS[cursor_index]
	_refresh()

# LOCALIZATION Code added: Duplicated the Button Prompts component, handling confirmation here
func _on_ButtonPromptsArrow_selected(cursor_index):
	arrow.on = true
	buttonPromptsArrow.on = false
	buttonPromptsMenu.hide()

	globaldata.buttonPrompts = globaldata.BUTTON_PROMPTS[cursor_index]
	_refresh()

# LOCALIZATION Code added: Handling confirmation for the generic submenu here
func _on_GenericOption_selected(cursor_index, value):
	match arrow.cursor_index:
		0: # Language
			global.set_language(languageValues[cursor_index])
		1: # Resolution
			global.set_win_size(cursor_index + 1)
		2: # Full Screen
			global.toggle_fullscreen(cursor_index == 0)
		3: # Music Volume
			global.set_music_volume(volumeValues[cursor_index])
		4: # SFX Volume
			global.set_sfx_volume(volumeValues[cursor_index])
	arrow.on = true
	#_refresh() Already handled with signals

# LOCALIZATION Code added: Handling cancellation for all submenus
func _on_SubMenuArrow_cancel():
	uiManager.set_menu_flavors(globaldata.menuFlavor)
	arrow.on = true
	textSpeedArrow.on = false
	flavorsArrow.on = false
	buttonPromptsArrow.on = false
	textSpeedMenu.hide()
	flavorsMenu.hide()
	buttonPromptsMenu.hide()
	_refresh()

# LOCALIZATION Code added: To refresh the view with all option values
func _refresh():
	# Text Speed
	textSpeedArrow.set_cursor_from_index(globaldata.TEXT_SPEEDS.find(globaldata.textSpeed), false)
	$OptionsMenu/NinePatchRect/FileSettings/VBoxContainer2/TextSpeedLabel.text = "MENU_" + globaldata.TEXT_SPEEDS_NAMES[textSpeedArrow.cursor_index]

	# Menu Flavor
	$OptionsMenu/NinePatchRect/FileSettings/VBoxContainer2/MenuFlavorLabel.text = "FLAVOR_" + globaldata.menuFlavor.to_upper()
	flavorsArrow.set_cursor_from_index(globaldata.FLAVORS.find(globaldata.menuFlavor), false)

	# Button Prompts
	$OptionsMenu/NinePatchRect/FileSettings/VBoxContainer2/ButtonPromptsLabel.text = "MENU_" + globaldata.buttonPrompts.to_upper()
	buttonPromptsArrow.set_cursor_from_index(globaldata.BUTTON_PROMPTS.find(globaldata.buttonPrompts), false)

	$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/WindowSize.text = _get_resolution_as_text(globaldata.winSize)

	# Full Screen
	$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/FullScreenSwitch.text = _get_fullscreen_as_text(OS.window_fullscreen)

	# Language
	# Obtaining the language code the game falls back to (ex: "es" if locale is "es_AR")
	$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/Language.text = _get_language_as_text(tr("LANGUAGE_CODE"))

	# Music Volume
	$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/MusicVolumeContainer/MusicVolumeSlider.value = _volume_db_to_units(globaldata.musicVolume) 

	# SFX Volume
	$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/SFXVolumeContainer/SFXVolumeSlider.value = _volume_db_to_units(globaldata.sfxVolume)


# LOCALIZATION Code added: 4 methods to display option names
func _get_language_as_text(code):
	return "OPTIONS_LANGUAGE_" + code.to_upper()

func _get_resolution_as_text(index):
	return "%s×%s" % [320 * index, 180 * index]

func _get_fullscreen_as_text(value):
	return "OPTIONS_ON" if value else "OPTIONS_OFF"

# LOCALIZATION Code added: To return all available resolutions
func _get_resolutions():
	var resolutions = []
	var i = 1
	while Vector2(320 * i, 180 * i) < OS.get_screen_size():
		resolutions.append(_get_resolution_as_text(i))
		i += 1

	return resolutions

func _volume_units_to_db(volume):
	return 40 * log(float(volume + 1) / VOLUME_GRADES)

func _volume_db_to_units(volume_db):
	var ret = min(volume_db, 0)
	ret = VOLUME_GRADES * exp(float(volume_db) / 40) - 1
	return int(round(ret))

# Chooses the closest volume db value from the selectable range
func _discretize_volume(volume_db):
	return _volume_units_to_db(_volume_db_to_units(volume_db))

func _on_Door_done():
	uiManager.close_commands_menu(true)

func _resize_to_fit(vboxContainer):
	yield(get_tree(), "idle_frame")
	$OptionsMenu/NinePatchRect.rect_size.y = vboxContainer.rect_size.y + vboxContainer.rect_global_position.y - $OptionsMenu/NinePatchRect.rect_global_position.y + 10


func _input(event):
	if arrow.is_active():
		if arrow.menu_parent == settingsMenuContent:
			match arrow.cursor_index:
				0: # Language
					pass
				1: # Resolution
					pass
				2: # Full Screen
					if controlsManager.get_just_released_input_vector().x != 0: # Changed to key release to avoid "fullscreen loop of hell" on Mac
						global.toggle_fullscreen()
						arrow.play_sfx("cursor2")
						_refresh()
				3: # Music Volume
					pass
				4: # SFX Volume
					pass


func _on_arrow_failed_move(dir):
	if arrow.is_active():
		if arrow.menu_parent == settingsMenuContent:
			match arrow.cursor_index:
				0: # Language
					pass
				1: # Resolution
					pass
				2: # Full Screen
					pass
				3: # Music Volume
					var volumeIdx = volumeValues.find(_discretize_volume(globaldata.musicVolume))
					if dir.x < 0:
						volumeIdx = min(volumeIdx + 1, VOLUME_GRADES - 1)
						global.set_music_volume(volumeValues[volumeIdx])
						arrow.play_sfx("cursor2")
						_refresh()
					elif dir.x > 0:
						volumeIdx = max(volumeIdx - 1, 0)
						global.set_music_volume(volumeValues[volumeIdx])
						arrow.play_sfx("cursor2")
						_refresh()
				4: # SFX Volume
					var volumeIdx = volumeValues.find(_discretize_volume(globaldata.sfxVolume))
					if dir.x < 0:
						volumeIdx = min(volumeIdx + 1, VOLUME_GRADES - 1)
						global.set_sfx_volume(volumeValues[volumeIdx])
						arrow.play_sfx("cursor2")
						_refresh()
					elif dir.x > 0:
						volumeIdx = max(volumeIdx - 1, 0)
						global.set_sfx_volume(volumeValues[volumeIdx])
						arrow.play_sfx("cursor2")
						_refresh()


func _on_arrow_moved(dir):
	if arrow.menu_parent == settingsMenuContent:
		# Animate controls when the cursor is over them
		# Fullscreen
		$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/FullScreenSwitch.highlighted = (arrow.cursor_index == 2)
		# Music volume
		$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/MusicVolumeContainer/MusicVolumeSlider.highlighted = (arrow.cursor_index == 3)
		# SFX volume
		$OptionsMenu/NinePatchRect/Settings/VBoxContainer2/SFXVolumeContainer/SFXVolumeSlider.highlighted = (arrow.cursor_index == 4)
