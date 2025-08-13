class_name TwoStatesSyncedSwitch
extends AbstractSwitch

func _ready():
	global.currentScene.emit_signal("synced_switches_changed", self, is_on(), true)
	_on_state_changed(is_on())
	global.currentScene.connect("synced_switches_changed", self, "_do_sync_with_room")

func is_on() -> bool:
	return _get_flag_status()

# Override
func _do_switch_action():
	toggle()

func toggle():
	turn_on_off(!is_on())

func _do_sync_with_room(emitter: TwoStatesSyncedSwitch, value: bool, silent: bool):
	if emitter != self:
		turn_on_off(value, false)

func turn_on_off(value: bool, propagate: bool = true):
	_set_flag_status(value)
	_on_state_changed(value)
	if propagate:
		global.currentScene.emit_signal("synced_switches_changed", self, is_on(), false)

func _on_state_changed(state: bool):
	if state:
		_anim_player.play("TurnOn")
	else:
		_anim_player.play("TurnOff")

