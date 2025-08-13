class_name BattleParticipant

extends Object

signal defeated

enum Type { PLAYABLE, NPC, ENEMY }

const BattleScript = preload("res://Scripts/UI/Battle/BattleScript.gd")

const MODDABLE_STATS = ["offense", "defense", "speed", "iq", "guts"]

#* Battle Participant
#  An interface to a Participant in battle. 
var _id := 0
var _type: int = Type.PLAYABLE
var _battle_script = null

var _bp_name
var _bp_name_letter := -1
var _stat_mods := {}

var stats := {}
var defending := false

var overworldObj: Node
var battleSprite: Control

# only for players
var partyInfo: Control = null
var statusBubble: Control = null

func _init(battle_obj, id: int, t_stats, type: int):
	_id = id
	stats = t_stats
	_type = type
	if stats.has("nickname"):
		_bp_name = TextTools.replace_text(stats.nickname)
	else:
		_bp_name = tr(stats.name)
	if stats.has("battlescript"):
		_battle_script = BattleScript.new(self, stats.battlescript)
		battle_obj.connect("round_done", _battle_script, "set_turns_count")
	if _type == Type.ENEMY:
		stats.status = []
		stats.boosts = {
			"maxhp": 0,
			"maxpp": 0,
			"offense": 0,
			"defense": 0,
			"iq": 0,
			"guts": 0,
			"speed": 0
		}


func get_id() -> int:
	return _id

func get_name() -> String:
	if _bp_name_letter != -1:
		var actual_letter = tr("BATTLE_LETTER_ALPHABET")[_bp_name_letter % tr("BATTLE_LETTER_ALPHABET").length()]
		return tr("BATTLE_LETTER_SPACING").format([_bp_name, actual_letter])
	else:
		return _bp_name

func get_name_without_letter() -> String:
	return _bp_name

# Ignored if already has a letter
func assign_letter(letter: int) -> int:
	if _bp_name_letter == -1:
		_bp_name_letter = letter
	return _bp_name_letter

func get_type() -> int:
	return _type

func can_act() -> bool:
	return isConscious() and !get_combined_status_effect("turn_skip").get("enable", false)

func get_passive_skills() -> Array:
	var ret: Array
	if _type == Type.PLAYABLE:
		ret = InventoryManager.get_passive_skills_from_inv(stats.name)
	else:
		ret = stats.get("passiveSkills", [])
	ret.sort_custom(self, "_sort_passive_skills")
	return ret

func _sort_passive_skills(item1, item2) -> bool:
	return item1.get("priority", 0) > item2.get("priority", 0)

func get_vulnerab_multiplier(element: String) -> float:
	var multipliers: Dictionary
	if _type == Type.PLAYABLE:
		multipliers = InventoryManager.get_vulnerab_multipliers_from_inv(stats.name)
	else:
		multipliers = stats.get("vulnerab_multipliers", {})
	return multipliers.get(element, 1)

func get_passive_skill_for_attack(attack: Dictionary) -> Dictionary:
	var ret := []
	for key in get_passive_skills():
		var passive_skill = globaldata.passiveSkills[key]
		var are_conditions_met = true
		for cond_key in passive_skill.conditions:
			var cond_value = passive_skill.conditions[cond_key]
			match cond_key:
				"skill":
					are_conditions_met = are_conditions_met and attack == globaldata.skills[cond_value]
				"skill_type":
					are_conditions_met = are_conditions_met and attack.skillType == cond_value
				"damage_type":
					are_conditions_met = are_conditions_met and attack.damageType == cond_value
		if are_conditions_met:
			return passive_skill.get("passive_skill_actions")
	return {}
	
func handle_homonymy_with(bp_list: Array):
	var highest_letter = 0
	var has_homonym = false
	for bp in bp_list:
		if get_name_without_letter() == bp.get_name_without_letter():
			var letter = bp.assign_letter(0)
			if letter > highest_letter:
				highest_letter = letter
			has_homonym = true
	if has_homonym:
		self.assign_letter(highest_letter + 1)

func handle_battler_script():
	if _battle_script:
		_battle_script.handle_phrase()

func is_scripted_battle() -> bool:
	return _battle_script != null

func is_boss() -> bool:
	return stats.get("boss", false)

func select():
	match(_type):
		Type.ENEMY:
			battleSprite.select()
		Type.PLAYABLE:
			partyInfo.select()

func deselect():
	match(_type):
		Type.ENEMY:
			battleSprite.deselect()
		Type.PLAYABLE:
			partyInfo.deselect()

func isConscious() -> bool:
	return !StatusManager.is_unconscious(stats)

func get_position(of_plate:bool = false, of_plate_top:bool = false) -> Vector2:
	match(_type):
		Type.PLAYABLE:
			if of_plate_top:
				return partyInfo.rect_global_position + Vector2(partyInfo.rect_size.x/2, 0)
			elif of_plate:
				return partyInfo.rect_global_position + partyInfo.rect_size/2
			else:
				return battleSprite.rect_global_position + battleSprite.rect_size/2
		Type.ENEMY:
			return battleSprite.rect_global_position + battleSprite.rect_size/2
		Type.NPC:
			return battleSprite.get_position()
		_:
			return Vector2.ZERO

func get_size() -> Vector2:
	return battleSprite.rect_size

func defeat(silent := false):
	# remove all statuses
	#stats.status.clear()
	StatusManager.add_status(stats, StatusManager.AILMENT_UNCONSCIOUS)
	match(_type):
		Type.PLAYABLE:
			partyInfo.HP = 0
			partyInfo.setHP(0, true)

			partyInfo.modulate = Color(0.4, 0.4, 0.4)
			battleSprite.dead = true
			if battleSprite.state == battleSprite.states.SHOWN:
				battleSprite.hideAway()
		Type.ENEMY:
			if statusBubble:
				statusBubble.hide()
			battleSprite.defeat(is_boss())
			
			if overworldObj != null:
				if overworldObj.get("keepAfterBattle") != null:
					if !overworldObj.keepAfterBattle:
						overworldObj.die()
				else:
					overworldObj.die()
		Type.NPC:
			if stats == globaldata.flyingman:
				global.partyNpcs.erase(globaldata.flyingman)
				globaldata.flags["flying_man_in_party"] = false
				global.create_party_followers()
				global.emit_signal("party_changed")
			elif stats == globaldata.eve:
				pass # TODO in 10 years i guess
	emit_signal("defeated", self, silent)

func set_overworld_obj_null():
	overworldObj = null

func has_status(status: String, type = null) -> bool:
	return StatusManager.has_status(stats, status)

func get_status(status: String, type = null):
	return StatusManager.get_status(stats, status)

func get_combined_status_effect(effect_name: String):
	return StatusManager.get_combined_status_effect(stats, effect_name, is_boss(), _type)

func get_all_status_effects():
	return StatusManager.get_status_effects(stats, _type, is_boss())

func _update_status(status: String):
	var sts = get_status(status)
	if sts != null:
		sts.battleTurns = 0
		sts.timesAfflicted += 1

func set_status(status: String, value: bool):
	if value:
		if has_status(status):
			_update_status(status)
		else:
			StatusManager.add_status(stats, status)
	else:
		StatusManager.remove_status(stats, status)
	refresh_status_info()
		
func refresh_status_info():
	for ailment in StatusManager.get_known_ailments():
		var ailment_info = StatusManager.get_ailment_info(ailment)
		var value = has_status(ailment)
		if ailment != StatusManager.AILMENT_UNCONSCIOUS \
		and ailment_info.get("status_bubble", false) and !ailment_info.get("hidden", false):
			if value:
				statusBubble.add_status(ailment)
			else:
				statusBubble.remove_status(ailment)
		match ailment:
			StatusManager.AILMENT_UNCONSCIOUS:
				if get_type() == Type.PLAYABLE:
					if value:
						battleSprite.dead = false
	if get_type() == Type.PLAYABLE:
		partyInfo.scroll_speed = get_combined_status_effect("hp_scroll_multiplier")
		var color = get_combined_status_effect("info_plate_color")
		partyInfo.hp_color = Color(color)

func get_base_stat(stat: String) -> int:
	return stats[stat] + stats.boosts[stat]

func get_stat(stat: String):
	var baseStat := get_base_stat(stat)
	var finalStat := baseStat
	if stat in MODDABLE_STATS:
		finalStat = baseStat + max(3, floor(baseStat/8)) * _stat_mods.get(stat, 0)
	var effects = get_combined_status_effect("stat_mods")
	for i in effects.size():
		finalStat = finalStat * effects[i].get(stat, 100) / 100
	return finalStat

func add_stat_mod(stat: String, mod: float):
	if stat in MODDABLE_STATS:
		_stat_mods[stat] = _stat_mods.get(stat, 0) + mod

func get_stat_mod(stat):
	return _stat_mods.get(stat, 0)

func reset_stat_mod(stat: String):
	_stat_mods.erase(stat)

func reset_all_stat_mods():
	_stat_mods = {}

func hp_stopped_scrolling():
	stats.hp = partyInfo.HP

func pp_stopped_scrolling():
	stats.pp = partyInfo.PP

#  Dictionary stats (replacement for active or battleEnemies)
# - Hp = 60
# - Str = 10
# - Skills = ["bash", "pkFireA", etc]
# - Status = ailments.whatever
# - Etc

