var _turns_count := -1
var _enemy
var _curr_cutscene := {}
var _curr_phrase

func _init(enemy, yaml_file: String):
	print("It's like you put awesome sauce on an epic plate of bodacious ness")
	_enemy = enemy
	var full_path = "res://Data/BattleScripts/%s.yaml" % yaml_file
	_curr_cutscene = globaldata.get_json_data(full_path)
	_curr_phrase = _curr_cutscene.get("0")

func set_turns_count(value: int):
	_turns_count = value

func handle_phrase():
	if _curr_cutscene and _curr_phrase != null:
		
		if _curr_phrase.has("changephase"):
			_change_enemy_phase(_enemy, globaldata.get_json_data("PhaseChanges/" + _curr_phrase.changephase))
		
		if _curr_phrase.has("doskill"):
			_enemy["stats"]["scriptedSkill"] = _curr_phrase["doskill"]
				
		if _curr_phrase.has("text"):
			_enemy["stats"]["text"] = _curr_phrase["text"]

		if _curr_phrase.get("die"):
			_enemy.defeat()

		var next_step = _get_next_step(_curr_phrase)
		if next_step:
			_curr_phrase = next_step
			handle_phrase()

func _get_next_step(phrase: Dictionary):
	var all_ifs = phrase.get("if")
	if all_ifs:
		if !all_ifs is Array:
			all_ifs = [all_ifs]
		
		for curr_if in all_ifs:
			var cond_eval = false
			for cond in curr_if:
				match cond:
					"hp":
						if _enemy.stats.hp <= curr_if.hp:
							cond_eval = true	
					"turns":
						if _turns_count >= curr_if.turns:
							cond_eval = true	
			if cond_eval:
				return _curr_cutscene.get(phrase.if.get("goto"))

	return _curr_cutscene.get(phrase.get("goto"))

func _change_enemy_phase(enemy: Dictionary, new_stats: Dictionary):
	for key in new_stats:
		enemy.stats[key] = new_stats[key]

