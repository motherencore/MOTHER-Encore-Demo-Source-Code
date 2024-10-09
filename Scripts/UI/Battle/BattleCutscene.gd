extends CanvasLayer

onready var battle = get_parent()

var currCutscene = {}
var currPhrase

var actors = []
var autoAdvance = false
var finished = false
var phraseNum = -1

signal done

func _process(delta):
	pass

func set_cutscene_file(path):
	print("It's like you put awesome sauce on an epic plate of bodacious ness")
	var filePath = "res://Data/BattleCutscenes/" + path + ".json"
	var f = File.new()

	if f.file_exists(filePath):
		pass
	else:
		return {}

	f.open(filePath, File.READ)
	var json = f.get_as_text()
	
	var output = parse_json(json)
	
	if typeof(output) == TYPE_DICTIONARY:
		currCutscene = output
		currPhrase = currCutscene["0"]

func next_phrase(wait = false) -> void:
	if phraseNum >= len(currCutscene):
		return
	
	currPhrase = currCutscene[str(phraseNum)]
	if !wait:
		handle_phrase(currPhrase)

func handle_phrase(phrase):
	if phrase != null:
		
		if phrase.has("changephase"):
			for enemy in battle.enemyBPs:
				if enemy.stats.name == phrase.changephase[1]:
					changePhase(enemy, battle.load_enemy("PhaseChanges/" + phrase.changephase[0])) # [0] phase, [1] enemy.
		
		if phrase.has("doskill"):
			for enemy in battle.enemyBPs:
				if enemy.stats.name == phrase.doskill[1]:
					enemy["stats"]["chosenSk"] = phrase["doskill"][0] # [0] action, [1] user.
		
		if phrase.has("finish"):
			currCutscene = {}
			currPhrase = null
		
		if phrase.has("goto"):
			phraseNum = str2var(currPhrase["goto"])
			next_phrase()
		
		if phrase.has("if"):
			check_conditions(phrase.if)
		
		if phrase.has("text"):
			for enemy in battle.enemyBPs:
				if enemy.stats.name == phrase.text[1].to_upper():
					enemy["stats"]["text"] = phrase["text"][0]

func changePhase(enemy, newStats: Dictionary):
	battle.enemyBPs.erase(enemy)
	for key in newStats:
		enemy.stats[key] = newStats[key]
	battle.enemyBPs.append(enemy)

func check_conditions(phrase):
	var condition = false
	for cond in phrase:
		
		if "hp" in cond:
			for enemy in battle.enemyBPs:
				if enemy.stats.name == phrase["hp"][1]:
					if enemy.stats.hp <= phrase["hp"][0]:
						condition = true
		
		if "turns" in cond:
			if battle.turns >= phrase.turns:
				condition = true
		
	if condition:
		phraseNum = str2var(phrase["goto"])
		next_phrase()
