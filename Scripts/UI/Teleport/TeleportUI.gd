extends CanvasLayer

signal entered

const TeleportOrb = preload("res://Scripts/UI/Teleport/TeleportOrb.gd")
const ReusableOptionList = preload("res://Scripts/UI/Options/ReusableOptionList.gd")
const Door = preload("res://Scripts/Main/Door.gd")

const DESTINATIONS_LIST = ["podunk", "Magicant", "Merrysville", "Reindeer", "Spookane", "Snowman", "Yucca", "Youngtown", "Ellay", "MtItoi"] #, "Changed"]
const DESTINATIONS_SCENES = {} #{"Changed": "Testing/Changed"}

export (NodePath) onready var _ui_layer = get_node(_ui_layer) as Node
export (NodePath) onready var _destination_list_view = get_node(_destination_list_view) as ReusableOptionList
export (NodePath) onready var _door = get_node(_door) as Door
export (NodePath) onready var _orbs_parent = get_node(_orbs_parent) as Node

var fade

func _init():
	fade = uiManager.fade
	uiManager.clearOnScreenEnemies()

func _ready():
	_destination_list_view.connect("selected", self, "_on_destination_selected")
	_destination_list_view.hide()
	_door.connect("entered", self, "_on_door_entered")
	_do_on_orbs("connect_signal", ["entered", self, "_on_entering_animation_done"])
	_do_on_orbs("connect_signal", ["left", self, "_on_leaving_animation_done"])
	_appearing_sequence()

func _appearing_sequence():
	_ui_layer.hide()
	_turn_off_music_changers()
	fade.fade_in()
	yield(fade, "fade_in_done")
	emit_signal("entered")
	audioManager.stop_all_music()
	uiManager.toggle_black_bars(true)
	_prepare_orbs()
	_do_on_orbs("play_enter_animation")
	_ui_layer.show()
	fade.fade_out("Cut")

func _prepare_orbs():
	var party_member_count = global.party.size()
	for i in _orbs_parent.get_child_count():
		var child = _orbs_parent.get_child(i)
		child.visible = (i < party_member_count)

func _do_on_orbs(action, params = []):
	var party_member_count = global.party.size()
	for child in _orbs_parent.get_children():
		var f = funcref(child as TeleportOrb, action)
		f.call_funcv(params)

func _on_entering_animation_done():
	_do_on_orbs("disconnect_signal", ["entered", self, "_on_entering_animation_done"])
	_destination_list_view.open(_get_destinations_list(), "", funcref(self, "_dest_name_cb"), funcref(self, "_is_destination_allowed"))
	_destination_list_view.show()

func _get_destinations_list():
	var ret = []
	for dest in DESTINATIONS_LIST:
		if _is_destination_allowed(dest) or OS.is_debug_build():
			ret.append(dest)
	return ret

func _dest_name_cb(dest):
	return "DEST_" + dest.to_upper()

func _is_destination_allowed(dest):
	return globaldata.flags.get("visited_" + dest.to_lower(), false)

func _on_destination_selected(index, value):
	_door.targetScene = DESTINATIONS_SCENES.get(value, "%s/%s" % [value, value])
	_do_on_orbs("play_leave_animation")

func _on_leaving_animation_done():
	_do_on_orbs("disconnect_signal", ["left", self, "_on_leaving_animation_done"])
	_door.enter()

func _on_door_entered():
	_ui_layer.hide()
	uiManager.toggle_black_bars(false)
	uiManager.remove_ui(self)
	queue_free()

func _turn_off_music_changers():
	for musicChanger in audioManager.musicChangers:
		musicChanger.stop_music_immediately()

