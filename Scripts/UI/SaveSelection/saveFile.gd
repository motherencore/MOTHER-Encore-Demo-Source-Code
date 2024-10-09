extends NinePatchRect

signal deactivate
signal show_delete
signal show_copy
signal show_textSpeed
signal show_menuFlavor
signal show_buttonPrompts

onready var arrow = $arrow

var party = global.party
var fileNum = 0
var saveData = null
var state = 0


func _ready():
	_reset()
	global.connect("locale_changed", self, "set_info")

func _reset():
	arrow.hide()
	global.persistPlayer.pause()
	$FileNum.text = str(fileNum)
	load_data(fileNum)
	if saveData != null:
		set_info()
	else:
		$NoData.show()
		set_menu_flavor("Plain")

func set_type(stateType):
	state = stateType
	if state == 1:
		$HBoxContainer.hide()
	_reset()

func set_info():
	$NoData.hide()
	if saveData.has("menuflavor"):
		set_menu_flavor(saveData["menuflavor"])
	else:
		set_menu_flavor("Plain")
	
	var pindex = 0 
	var picons = [
		$icons/Control1/picon1, #ninten
		$icons/Control2/picon2, #lloyd
		$icons/Control3/picon3, 
		$icons/Control4/picon4, 
		$icons/Control5/picon5
		] #loading icons from scene tree
	
	#getting nickname of first party member
	$Name.text = saveData["party"][0].nickname 
	#getting level of first party member
	$Level.text = (tr("MENU_LV") + str(saveData["party"][0]["level"]))
	
	#scene name
	if saveData.has("scenename"):
		$Title.text = globaldata.replaceText("LOC_" + saveData["scenename"].to_upper().replace(" ", "_"), saveData)

	
	#playtime
	if saveData.has("playtime"):
		var hours = str(int(saveData["playtime"]/3600))
		var minutes = int(saveData["playtime"]/60)
		
		if minutes >= 60:
			minutes -= (60 * int(minutes/60))
		
		minutes = str(minutes)
	
		if len(hours) < 2:
			hours = "0" + hours
		if len(minutes) < 2:
			minutes = "0" + minutes
		
		var time_str = "[color=#f8f800]" + tr("SAVE_TIME") + "[/color]"
		if len(hours) > 4:
			$Time.bbcode_text = tr("SAVE_TIME_TOO_MUCH").format({"time": time_str})
		else:
			$Time.bbcode_text = time_str + " " + hours + " : " + minutes
	
	for icon in $icons.get_children():
		icon.hide()
	if saveData.has("party"):
		for i in saveData["party"]:
			picons[pindex].texture = load("res://Graphics/UI/Inventory/characters/" + i.name + ".png")
			picons[pindex].get_parent().show()
			pindex += 1
	if saveData.has("partyNpcs"):
		for i in saveData["partyNpcs"]:
			picons[pindex].texture = load("res://Graphics/UI/Inventory/characters/canarychick.png")
			picons[pindex].get_parent().show()
			pindex += 1

func activate(reset = false):
	arrow.show()
	arrow.on = true
	if reset:
		arrow.set_cursor_from_index(0, false)

func deactivate():
	arrow.on = false
	arrow.hide()
	emit_signal("deactivate")

func load_data(num): #benichi code
	var saveGame = File.new()
	if not saveGame.file_exists("user://saveFile" + var2str(num) + ".save"):
		return 
	
	saveGame.open_encrypted_with_pass("user://saveFile" + var2str(num) + ".save", File.READ,"ENCORE")

	saveData = parse_json(saveGame.get_line())


func set_menu_flavor(flavor):
	material.set_shader_param("NEWCOLOR1", Color(uiManager.menuFlavors[flavor][0]))
	material.set_shader_param("NEWCOLOR2", Color(uiManager.menuFlavors[flavor][1]))
	material.set_shader_param("NEWCOLOR3", Color(uiManager.menuFlavors[flavor][2]))
	material.set_shader_param("NEWCOLOR4", Color(uiManager.menuFlavors[flavor][3]))
	material.set_shader_param("NEWCOLOR5", Color(uiManager.menuFlavors[flavor][4]))
	$ColorRect.color = Color(uiManager.menuFlavors[flavor][1])
	$ColorRect2.color = Color(uiManager.menuFlavors[flavor][1])
	$Options.color = Color(uiManager.menuFlavors[flavor][3])
	$NoData.color = Color(uiManager.menuFlavors[flavor][3])

func _on_arrow_cancel():
	if !$Options.visible:
		deactivate()
	else:
		$Options.hide()
		arrow.cursor_offset.y = 3
		arrow.change_parent($HBoxContainer, false)
		arrow.set_cursor_from_index(6, true)

func _on_arrow_selected(cursor_index):
	if not $Options.visible:
		# LOCALIZATION Code change: Matching on name ids because index is not relevant anymore (there are spacers between elements)
		match arrow.menu_parent.get_child(cursor_index).name:
			"Play":
				arrow.on = false
				uiManager.fade.fade_in("Fade", Color.black, 1)
				audioManager.fadeout_all_music(0.5)
				yield(uiManager.fade, "fade_in_done")
				globaldata.saveFile = fileNum
				global.save_settings()
				global.persistPlayer.unpause()
				global.load_game(fileNum)
				uiManager.fade.fade_out("Circle Focus", Color.black, 1)
			"Copy":
				global.load_game(fileNum, false)
				deactivate()
				emit_signal("show_copy")
			"Delete":
				global.load_game(fileNum, false)
				deactivate()
				emit_signal("show_delete")
			"Options":
				$Options.show()
				arrow.cursor_offset.y = 1
				arrow.change_parent($Options/VBoxContainer, false)
				arrow.set_cursor_from_index(0, true)
	else:
		global.load_game(fileNum, false)
		deactivate()
		match cursor_index:
			0:
				emit_signal("show_textSpeed")
			1:
				emit_signal("show_menuFlavor")
			2:
				emit_signal("show_buttonPrompts")
