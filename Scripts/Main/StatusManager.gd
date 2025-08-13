extends Node

#enum Ailments {Asthma,Blinded,Burned,Cold,Confused,Forgetful,Nausea,Numb,Poisoned,Sleeping,Stone,Sunstroked,Unconscious}

const _ailment_info = {}

const AILMENT_POISONED = "poisoned"
const AILMENT_UNCONSCIOUS = "unconscious"

func _init():
	globaldata.load_data("res://Data/StatusAilments/", _ailment_info)

class Status:
	var ailment: String
	var sunstrokeSteps := 0
	var battleTurns := 0
	var timesAfflicted := 1
	
	func _init(status):
		ailment = status

func add_status(character: Dictionary, status: String):
	if does_ailment_exist(status):
		if !has_status(character, status) and !has_status(character, AILMENT_UNCONSCIOUS):
			if status == AILMENT_UNCONSCIOUS:
				remove_all_statuses(character)
			character.status.append(Status.new(status))
			character.status.sort_custom(self, "_sort_by_priority")
	else:
		print("Invalid status! " + str(status) + " does not exist!")

func remove_status(character: Dictionary, status: String):
	if does_ailment_exist(status):
		for ailment in character.status:
			if ailment.ailment == status:
				character.status.erase(ailment)
	else:
		print("Invalid status! " + str(status) + " does not exist!")

func remove_all_statuses(character: Dictionary):
	for ailment in character.status:
		character.status.erase(ailment)

func get_status(character: Dictionary, status: String) -> Status:
	for ailment in character.status:
		if ailment.ailment == status:
			return ailment
	return null

func has_status(character: Dictionary, status: String) -> bool:
	return get_status(character, status) != null

func get_status_effects(character: Dictionary, char_type := 0, is_boss := false, effect_name := "") -> Array:
	var effects := []
	for status in character.status:
		var ailment_info = get_ailment_info(status.ailment)
		if ailment_info == null or !ailment_info.has("effects_by_char"):
			continue
		var effects_for_type := _pick_status_effects(ailment_info.effects_by_char, char_type, is_boss, status.timesAfflicted)
		if effect_name != "":
			if effects_for_type.has(effect_name):
				effects.append(effects_for_type[effect_name])
		else:
			effects.append(effects_for_type)

	return effects

func _pick_status_effects(effects_by_char: Dictionary, char_type := 0, is_boss := false, times_afflicted := 0) -> Dictionary:
	for case in effects_by_char:
		var condition := false
		match case:
			"party_field":
				pass
			"party_battler":
				condition = (char_type == 0)
			"enemy":
				condition = (char_type == 2)
			"boss":
				condition = is_boss
			"boss_layer_1":
				condition = (is_boss and times_afflicted <= 1)
			"boss_layer_2":
				condition = (is_boss and times_afflicted > 1)
			"any":
				condition = true
		if condition:
			return effects_by_char[case]
	return {}

func get_combined_status_effect(character: Dictionary, effect_name: String, type := 0, is_boss := false) -> Object:
	var effects := get_status_effects(character, type, is_boss, effect_name)
	var combined_effect
	match effect_name:
		"hp_scroll_multiplier", "damage_multiplier":
			combined_effect = 1
		"fail_additionner":
			combined_effect = 0
		"info_plate_color":
			combined_effect = 'FFFFFF'
		"stat_mods":
			combined_effect = {}
		"confusion":
			combined_effect = false
		"cant_select", "turn_skip":
			combined_effect = {}
		"dealt_mod", "dealt_color", "received_mod", "received_color", "cant_do":
			combined_effect = []
	for i in effects.size():
		match effect_name:
			"hp_scroll_multiplier", "damage_multiplier":
				combined_effect *= effects[i]
			"fail_additionner":
				combined_effect += effects[i]
			"info_plate_color":
				combined_effect = effects[i]
				break
			"stat_mods":
				for stat in effects[i]:
					combined_effect[stat] = combined_effect.get(stat, 0) or effects[i].get(stat, 0)
			"turn_skip":
				combined_effect = effects[i]
				if combined_effect.get("enable", false):
					break
			"confusion":
				combined_effect = combined_effect or effects[i]
			"cant_select":
				for action in effects[i]:
					combined_effect[action] = combined_effect.get(action, false) or effects[i][action]
			"dealt_mod", "dealt_color", "received_mod", "received_color", "cant_do":
				combined_effect.append(effects[i])
	return combined_effect

func get_status_message(ailment: String, message: String) -> String:
	var ailment_info = get_ailment_info(ailment)
	if ailment_info.has("messages"):
		return ailment_info.messages.get(message, "")
	return ""

func _sort_by_priority(sts1, sts2):
	return get_ailment_info(sts1.ailment).get("priority", 0) > get_ailment_info(sts2.ailment).get("priority", 0)

func is_unconscious(character) -> bool:
	return has_status(character, AILMENT_UNCONSCIOUS)

func get_ailment_info(ailment: String) -> Dictionary:
	return _ailment_info.get(ailment)

func does_ailment_exist(ailment: String) -> bool:
	return _ailment_info.has(ailment)

func get_known_ailments() -> Array:
	return _ailment_info.keys()

func save_statuses(dict):
	for partyMember in global.POSSIBLE_PARTY_MEMBERS:
		var tempstatus = []
		if dict.has(partyMember):
			for status in dict[partyMember].status:
				var new_status = {"status": status.ailment}
				if get_ailment_info(status.ailment)["healing"].get("passive_heal", false):
					new_status["passiveHealingTurns"] = status.battleTurns
				tempstatus.append(new_status)
			dict[partyMember].status = tempstatus
			dict[partyMember].status.sort_custom(self, "_sort_by_priority")

func load_statuses(dict):
	for partyMember in global.POSSIBLE_PARTY_MEMBERS:
		var tempstatus = []
		if dict.has(partyMember):
			for status in dict[partyMember].status:
				var new_status = Status.new(status["status"])
				new_status.battleTurns = status.get("passiveHealingTurns", 0)
				tempstatus.append(new_status)
			dict[partyMember].status = tempstatus
			dict[partyMember].status.sort_custom(self, "_sort_by_priority")
