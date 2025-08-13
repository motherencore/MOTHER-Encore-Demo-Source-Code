extends NinePatchRect

signal deactivate
signal show_delete
signal show_copy
signal show_textSpeed
signal show_menuFlavor
signal show_buttonPrompts

onready var _arrow := $arrow

var _file_num := 0
var _save_data = null

func init(embed, file_num):
	$HBoxContainer.visible = !embed
	_file_num = file_num
	load_data(_file_num)
	_refresh()

func _ready():
	_arrow.hide()
	global.persistPlayer.pause()
	global.connect("locale_changed", self, "_refresh")

func _refresh():
	$FileNum.text = str(_file_num)
	if _save_data != null:
		$NoData.hide()
		_set_menu_flavor(_save_data["menuflavor"])
		_refresh_save_info()
	else:
		$NoData.show()
		_set_menu_flavor(globaldata.FLAVORS[0])

func _refresh_save_info():
	var picons = [
		$icons/Control1/picon1, #ninten
		$icons/Control2/picon2, #lloyd
		$icons/Control3/picon3, 
		$icons/Control4/picon4, 
		$icons/Control5/picon5
		] #loading icons from scene tree
	
	var party_lead = _save_data.get(_save_data["party"][0])

	#getting nickname of first party member
	$Name.text = party_lead.nickname 
	#getting level of first party member
	$Level.text = (tr("MENU_LV") + str(party_lead.level))
	
	#scene name
	if _save_data.get("scenename"):
		$Title.text = TextTools.replace_text("LOC_" + _save_data["scenename"].to_upper().replace(" ", "_"), _save_data)

	#playtime
	if _save_data.has("playtime"):
		var hours = str(int(_save_data["playtime"]/3600))
		var minutes = int(_save_data["playtime"]/60)
		
		if minutes >= 60:
			minutes -= (60 * int(minutes/60))
		
		minutes = str(minutes)
	
		if len(hours) < 2:
			hours = "0" + hours
		if len(minutes) < 2:
			minutes = "0" + minutes
		
		var time_str = "[color=#f8f800]%s[/color]" % tr("SAVE_TIME")
		if len(hours) > 4:
			$Time.bbcode_text = tr("SAVE_TIME_TOO_MUCH").format({"time": time_str})
		else:
			$Time.bbcode_text = time_str + " " + hours + " : " + minutes
	
	for icon in $icons.get_children():
		icon.hide()
	
	var full_party = _save_data.get("party", [])
	for i in full_party.size():
		picons[i].texture = load("res://Graphics/UI/Inventory/characters/%s.png" % full_party[i])
		picons[i].get_parent().show()

func activate(reset = false):
	_arrow.show()
	_arrow.on = true
	if reset:
		_arrow.set_cursor_from_index(0, false)

func deactivate():
	_arrow.on = false
	_arrow.hide()
	emit_signal("deactivate")

func load_data(num):
	var dict = global.load_to_dict(num)
	if dict != null:
		_save_data = dict
	_refresh()

func load_game():
	_arrow.on = false
	uiManager.fade.fade_in("Fade", Color.black, 1)
	audioManager.fadeout_all_music(0.5)
	yield(uiManager.fade, "fade_in_done")
	globaldata.saveFile = _file_num
	global.save_settings()
	global.persistPlayer.unpause()
	global.load_game(_file_num)
	uiManager.fade.fade_out("Circle Focus", Color.black, 1)


func clear_data():
	_save_data = null
	_refresh()

func has_data():
	return _save_data != null

func _set_menu_flavor(flavor):
	var flavor_colors = uiManager.menuFlavors[globaldata.FLAVORS.find(flavor)]
	material.set_shader_param("NEWCOLOR1", Color(flavor_colors[0]))
	material.set_shader_param("NEWCOLOR2", Color(flavor_colors[1]))
	material.set_shader_param("NEWCOLOR3", Color(flavor_colors[2]))
	material.set_shader_param("NEWCOLOR4", Color(flavor_colors[3]))
	material.set_shader_param("NEWCOLOR5", Color(flavor_colors[4]))
	$ColorRect.color = Color(flavor_colors[1])
	$ColorRect2.color = Color(flavor_colors[1])
	$Options.color = Color(flavor_colors[3])
	$NoData.color = Color(flavor_colors[3])

func _on_arrow_cancel():
	if !$Options.visible:
		deactivate()
	else:
		$Options.hide()
		_arrow.cursor_offset.y = 3
		_arrow.change_parent($HBoxContainer, false)
		_arrow.set_cursor_from_index(6, true)

func _on_arrow_selected(cursor_index):
	if not $Options.visible:
		# LOCALIZATION Code change: Matching on name ids because index is not relevant anymore (there are spacers between elements)
		match _arrow.get_current_item().name:
			"Play":
				load_game()
			"Copy":
				global.load_game(_file_num, false)
				deactivate()
				emit_signal("show_copy")
			"Delete":
				global.load_game(_file_num, false)
				deactivate()
				emit_signal("show_delete")
			"Options":
				$Options.show()
				_arrow.cursor_offset.y = 1
				_arrow.change_parent($Options/VBoxContainer, false)
				_arrow.set_cursor_from_index(0, true)
	else:
		global.load_game(_file_num, false)
		deactivate()
		match cursor_index:
			0:
				emit_signal("show_textSpeed")
			1:
				emit_signal("show_menuFlavor")
			2:
				emit_signal("show_buttonPrompts")
