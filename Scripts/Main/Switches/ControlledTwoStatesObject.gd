class_name ControlledTwoStatesObject
extends ControlledObject

signal state_changed (state, silent)

onready var _state_anim_player = get_node_or_null(_state_anim_player) as AnimationPlayer

var _switches: Array = []

export (bool) var _is_synced_with_room := false
export (bool) var _initially_on := false

func _init():
	_state_anim_player = ""

func _ready():
	update_state(true)
	if _is_synced_with_room:
		global.currentScene.connect("synced_switches_changed", self, "_on_synced_switches_changed")

func register_switch(switch: TwoStatesSwitch):
	if !switch in _switches:
		_switches.append(switch)

func _get_state() -> bool:
	var state := _initially_on
	if _is_synced_with_room:
		state = (state != global.currentScene.get_switches_state())
	else:
		for switch in _switches:
			state = (state != switch.is_on())
	return state

func _on_synced_switches_changed(emitter: TwoStatesSyncedSwitch, value: bool, silent: bool):
	update_state(silent)

# Override
func update_state(silent: bool = false):
	var is_on = _get_state()
	if _state_anim_player:
		var prefix = "Stay" if silent else ""
		if is_on:			
			_state_anim_player.play("%sOn" % prefix)
		else:
			_state_anim_player.play("%sOff" % prefix)
		yield(_state_anim_player, "animation_finished")
	emit_signal("state_changed", is_on, silent)

# Override
func get_update_order() -> int:
	return _update_order * (1 if _get_state() else -1)
