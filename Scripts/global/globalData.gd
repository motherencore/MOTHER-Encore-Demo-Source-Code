extends Node

enum ailments {Asthma,Blinded,Burned,Cold,Confused,Forgetful,Nausea,Numb,Poisoned,Sleeping,Sunstroked,Mushroomized,Unconscious}
const persistentAilments = [
	ailments.Asthma,
	ailments.Cold,
	ailments.Confused,
	ailments.Mushroomized,
	ailments.Nausea,
	ailments.Poisoned,
	ailments.Sunstroked,
]

const PSI_LEVELS = "αβγΩΣ"

# LOCALIZATION Code added for Polish grammar needs
var polishDeclension = load("Scripts/languages/PolishDeclension.gd").new()
var russianDeclension = load("Scripts/languages/RussianDeclension.gd").new()
var hangul = load("Scripts/languages/Hangul.gd").new()

var saveFile = 0
var playtime = 0
var winSize = 3
var musicVolume = 0
var sfxVolume = 0
var earned_cash: int = 0
var cash: int = 200
var bank: int = 0
var levelCap = 20
var respawnPoint = Vector2.ZERO
var respawnScene = ""
var description = true
var rumble = true
var favoriteFood = "Oreos"
var menuFlavor = "Plain"
var textSpeed = 0.02
var buttonPrompts = "Both"
var dialogHintColor = "ea8b2c"
var playerName = "You"
var rareDrops = {}
enum BTN_STYLES {NINTENDO, PLAYSTATION, XBOX, DETECT}
var buttonsStyle = BTN_STYLES.DETECT
# LOCALIZATION Code change: Added article field for each party member
var ninten = {
	"name": "ninten",
	"nickname": "ryu",
	"sprite": "Ninten", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": ["telepathy", "lifeUpA", "lifeUpB", "healingA"],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 75, 
	"maxhp": 75, 
	"pp": 30,
	"maxpp": 30, 
	"offense": 10, 
	"defense": 12, 
	"speed": 1,
	"iq": 5, 
	"guts": 8,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_NINTEN"
	} 
var ana = {
	"name": "ana",
	"nickname": "Ana",
	"sprite": "Ana", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": [],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 1, 
	"maxhp": 40, 
	"pp": 30, 
	"maxpp": 30, 
	"offense": 6, 
	"defense": 3, 
	"speed": 8, 
	"iq": 8, 
	"guts": 6,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_ANA"}
var lloyd = {
	"name": "lloyd", 
	"nickname": "Lloyd", 
	"sprite": "Lloyd", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": [],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 80, 
	"maxhp": 80, 
	"pp": 0, 
	"maxpp": 0, 
	"offense": 8, 
	"defense": 10, 
	"speed": 10, 
	"iq": 10, 
	"guts": 3,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_LLOYD"}
var teddy = {
	"name": "teddy", 
	"nickname": "Teddy",
	"sprite": "Teddy", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""}, 
	"learnedSkills": [""],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0, 
	"hp": 80, 
	"maxhp": 80, 
	"pp": 0, 
	"maxpp": 0, 
	"offense": 8, 
	"defense": 10, 
	"speed": 10, 
	"iq": 3, 
	"guts": 10,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_TEDDY"}
var pippi = {
	"name": "pippi", 
	"nickname": "Child", 
	"sprite": "Pippi", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""}, 
	"learnedSkills": [],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0, 
	"hp": 80, 
	"maxhp": 80, 
	"pp": 0, 
	"maxpp": 0, 
	"offense": 8, 
	"defense": 10, 
	"speed": 10, 
	"iq": 3, 
	"guts": 10,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_PIPPI"}
var flyingman = {
	"name": "flyingman", 
	"nickname": tr("NAME_FLYINGMAN"), 
	"sprite": "FlyingMan", 
	"status": [], 
	"learnedSkills": [""],
	"passiveSkills": [],
	"level": 99, 
	"exp": 0, 
	"hp": 400, 
	"maxhp": 400, 
	"pp": 0, 
	"maxpp": 0, 
	"speed": 14, 
	"offense": 55, 
	"defense": 25, 
	"iq": 25, 
	"guts": 25,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_FLYINGMAN"}
var canarychick = {
	"name": "canarychick", 
	"nickname": tr("NAME_CANARYCHICK"),
	"sprite": "CanaryChick", 
	"status": [], 
	"passiveSkills": [],
	"level": 42, 
	"exp": 0, 
	"hp": 0, 
	"maxhp": 0, 
	"pp": 0, 
	"maxpp": 0, 
	"speed": 1, 
	"offense": 1, 
	"defense": 1, 
	"iq": 1, 
	"guts": 1, 
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_CANARYCHICK"}
var eve = {
	"name": "eve", 
	"nickname": tr("NAME_EVE"),
	"sprite": "", 
	"status": [], 
	"passiveSkills": [],
	"level": 1, 
	"exp": 0, 
	"hp": 0, 
	"maxhp": 0, 
	"pp": 0, 
	"maxpp": 0, 
	"speed": 1, 
	"offense": 1, 
	"defense": 1, 
	"iq": 1, 
	"guts": 1, 
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
	"article": "ARTICLES_EVE"}

# The stat target table is a dictionary with stats that each have an array
# Each stat array represents where a stat should be at that (index * 10) level
# e.g. Ninten's offense at level 30 would be in index 3, the 4th number in the array
#      Level 30 - Offense Stat target is 24
const player_stat_target_table = {
	"ninten": {
		"maxhp": [60, 88, 121, 160, 205, 254, 308, 365, 425, 487, 550],
		"maxpp": [25, 38, 54, 73, 94, 118, 144, 171, 200, 230, 260],
		"offense": [10, 21, 34, 49, 66, 85, 106, 128, 152, 176, 200],
		"defense": [7, 11, 16, 21, 28, 36, 44, 52, 61, 71, 80],
		"speed": [6, 10, 15, 21, 28, 35, 43, 52, 61, 70, 80],
		"iq":  [5, 11, 18, 26, 36, 47, 58, 70, 83, 97, 110],
		"guts": [8, 10, 13, 17, 20, 25, 29, 34, 39, 44, 50],
	},
	"ana": {
		"maxhp": [40, 65, 95, 130, 170, 214, 263, 314, 368, 424, 480],
		"maxpp": [30, 47, 69, 93, 122, 153, 187, 223, 261, 300, 340],
		"offense": [6, 12, 19, 27, 37, 47, 59, 71, 84, 97, 140],
		"defense": [3, 6, 11, 16, 21, 28, 34, 42, 49, 57, 65],
		"speed": [8, 12, 18, 24, 31, 40, 48, 58, 67, 78, 88],
		"iq":  [8, 14, 22, 31, 41, 52, 65, 78, 91, 106, 120],
		"guts": [6, 8, 10, 13, 16, 19, 23, 27, 31, 35, 40],
	},
	"lloyd": {
		"maxhp": [80, 109, 145, 186, 234, 286, 343, 404, 467, 533, 600],
		"maxpp": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"offense": [8, 17, 28, 41, 56, 72, 90, 109, 129, 149, 170],
		"defense": [10, 14, 20, 26, 34, 42, 50, 60, 69, 80, 90],
		"speed": [10, 15, 21, 27, 35, 44, 53, 63, 73, 84, 95],
		"iq":  [10, 18, 29, 41, 54, 69, 86, 103, 122, 141, 160],
		"guts": [3, 5, 6, 9, 11, 14, 17, 20, 23, 27, 30],
	},
	
	"teddy": {
		"maxhp": [80, 111, 150, 195, 245, 302, 363, 429, 497, 568, 640],
		"maxpp": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"offense": [8, 20, 34, 51, 71, 92, 115, 140, 166, 193, 220],
		"defense": [10, 16, 22, 30, 40, 50, 61, 72, 85, 97, 110],
		"speed": [10, 15, 21, 29, 38, 48, 58, 69, 81, 93, 105],
		"iq":  [3, 8, 14, 21, 29, 37, 47, 57, 68, 79, 90],
		"guts": [8, 11, 14, 19, 23, 29, 34, 40, 47, 53, 60],
	},
	"pippi": {
		"maxhp": [80, 111, 150, 195, 245, 302, 363, 429, 497, 568, 640],
		"maxpp": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"offense": [8, 20, 34, 51, 71, 92, 115, 140, 166, 193, 220],
		"defense": [10, 16, 22, 30, 40, 50, 61, 72, 85, 97, 110],
		"speed": [10, 15, 21, 29, 38, 48, 58, 69, 81, 93, 105],
		"iq":  [3, 8, 14, 21, 29, 37, 47, 57, 68, 79, 90],
		"guts": [8, 11, 14, 19, 23, 29, 34, 40, 47, 53, 60],
	},
}

const player_learn_skill_table_flags = {
	"ninten": {
		"curveball": "bat"
	},
	"lloyd": {
		
	},
	"ana": {
	},
	"pippi": {
		
	},
	"teddy": {
		
	}
}

const player_learn_skill_table = {
	"ninten": {
		2: "telepathy",
		#4: "hypnosis",
		4: "speedUpA",
		5: "healingA",
		#6: "darkness",
		8: "offenseUpA",
		10: "defenseUpA",
		12: "curveball",
		20: "lifeUpB",
		22: "healingB",
		#32: "healingG",
		#35: "lifeUpG",
		#43: "healingO",
		#45: "lifeUpO",
	},
	"lloyd": {
		
	},
	"ana": {
		5: "pkFreezeA",
		7: "pkFireA"
	},
	"pippi": {
		
	},
	"teddy": {
		
	}
}

const skills = {}
const fieldSkills = {}
const items = {}
const shopLists = {}
const mapMarkers = {}

# LOCALIZATION Code change: Rewrote this methode to make it more effective, more consistent
# Also included more tags for articles and specific language needs
func replaceText(string, context = self, without_brackets = false):
	string = tr(string)
	string = _replace_ifs(string)
	string = _replace_tags(string, context, without_brackets)
	var substitutions = {" - ": " – " , "(\\d+) (\\$)": '$1 $2',  "([   ])!": "$1¦" }
	var regex = RegEx.new()
	for pattern in substitutions:
		regex.compile(pattern)
		string = regex.sub(string, substitutions[pattern], true)
	return string
	
# General syntax: [Tag], [Tag:Param1,Param2,...], or [Tag123] (numeric parameter)
func _replace_tags(string, context = self, without_brackets = false):
	var startIndex = 0
	var regex = RegEx.new()
	if !without_brackets:
		regex.compile("\\[([A-Za-z_]+)(:[^\\]]+|\\d+)?\\]")
	else:
		regex.compile("^([A-Za-z_]+)(:[^\\]]+|\\d+)?$")
	var tag = regex.search(string)
	while tag:
		var result = tag.get_string()
		var tagContent = tag.get_string(1)
		var tagParam = tag.get_string(2).trim_prefix(":")
		match tagContent:
			"N":			# [N] returns Ninten's initial, for the NES joke in other languages
				result = context.ninten["nickname"][0]
			"PartyLead":	# [PartyLead] returns the party leader's nickname
				result = global.party[0]["nickname"]
			"FavFood":		# [FavFood] returns the favorite food
				result = context.favoriteFood
			"ItemName": 	# [ItemName] returns the current item name
				result = tr(global.item["name"]) if global.item else ""
			"ItemReceiver":	# [ItemReceiver] returns the nickname of the party member receiving an item
				result = global.receiver["nickname"] if global.receiver else ""
			"User":			# [User] returns the nickname of the party member who's using an item
				result = global.itemUser["nickname"] if global.itemUser else ""
			"LeadArt":		# [LeadArt0], [LeadArt1], etc., return the party leader's articles
				result = get_battler_articles(global.party[0], int(tagParam))
			"ReceiverArt":	# [ReceiverArt0], [ReceiverArt1], etc., return the item receiver's articles
				result = get_battler_articles(global.receiver, int(tagParam))
			"UserArt":		# [UserArt0], [UserArt1], etc., return the item user's articles
				result = get_battler_articles(global.itemUser, int(tagParam))
			"ItemArt":		# [ItemArt0], [ItemArt1], etc., return the current item articles
				if global.item and tagParam:
					result = get_item_or_skill_articles(global.item, int(tagParam))
				else:
					result = ""
			"EarnedCash":	# [EarnedCash] returns - and resets - the amount of money you've just earned
				result = var2str(context.earned_cash) # Dollar sign not included
				context.earned_cash = 0
				context.flags["earned_cash"] = false
			"CurrentCash":	# [CurrentCash] returns the amount of money on hand (without dollar sign)
				result = var2str(context.cash)
			"BankCash":		# [BankCash] returns the amount of money on bank (without dollar sign)
				result = var2str(context.bank)
			"color":		# [color] returns the opening tag to set the text color to hint color
				result = "[color=#"+ dialogHintColor + "]"
			"br":			# [br] returns a new line (it can )
				result = "\n"
			"fr_eli":		# [fr_eli] returns French elision ("e " or "'" if followed by vowel)
							# [fr_eli:***] returns French elision where the next word is ***
				if tagParam:
					var nickname = _replace_tags(tagParam, context, true)
					result = get_french_elision(nickname)
				else:
					result = get_french_elision(string.substr(tag.get_end()))
			"de_gen":		# [de_gen] returns German genitive suffix ("s" or "'" if after an s or x)
							# [de_gen:***] returns German genitive suffix where the previous word is ***
				if tagParam:
					var nickname = _replace_tags(tagParam, context, true)
					result = get_german_genitive(nickname)
				else:
					result = get_german_genitive(string.substr(0, tag.get_start()))
			"pl_decl":		# [pl_decl:name:gender:case] returns Polish declension for name
							# where "gender" is M or F and "case" is the index of the grammar case
				var params = tagParam.split(":")
				var nickname = _replace_tags(params[0], context, true)
				result = get_polish_declension(nickname, params[1], int(params[2]))
			"ru_decl":		# [ru_decl:name:gender:case] returns Russian declension for name
							# where "gender" is M or F and "case" is the index of the grammar case
				var params = tagParam.split(":")
				var nickname = _replace_tags(params[0], context, true)
				result = get_russian_declension(nickname, params[1], int(params[2]))
			"ko_part":
				var params = tagParam.split(":")
				if params.size() > 1:
					var nickname = _replace_tags(params[0], context, true)
					result = get_korean_particle(nickname, int(params[1]))
				else:
					result = get_korean_particle(string.substr(0, tag.get_start()), int(params[0]))

			_:
				if tagContent.begins_with("ui_"):	# [ui_accept], [ui_cancel], etc., returns control keys
					result = get_key_name(tagContent)
				elif tagContent.to_lower() in global.POSSIBLE_PARTY_MEMBERS:
					result = context[tagContent.to_lower()]["nickname"]
					var max_length = len(tr("LONGEST_POSSIBLE_NAME"))
					result = result.substr(0, max_length)
				elif status_name_to_enum(tagContent.to_lower()) != -1:
					result = "[font=res://Graphics/UI/Ailments/Ailments.tres][img]res://Graphics/UI/Ailments/%s.png[/img][/font]" % tagContent.capitalize()
				else:								# Unknown tags: doing nothing, moving the start index to prevent looping indefinitely
					startIndex = tag.get_start() + 1
					if not tagContent in ["img", "i", "b"]:
						push_warning("UNKNOWN TAG: %s" % tagContent)

		var strBefore = string.substr(0, tag.get_start())
		var strAfter = string.substr(tag.get_end())
		string = strBefore + result + strAfter

		if without_brackets:
			break

		tag = regex.search(string, startIndex)
	
	return string


func _replace_ifs(string):
	var regex = RegEx.new()
	regex.compile("\\[if (\\w+)(:\\w+)?\\]((?:(?!\\[/?if [\\w:]+\\]).)*?)(\\[else\\]((?:(?!\\[/?if [\\w:]+\\]).)*?))?\\[/if\\]")
	var tag = regex.search(string)
	
	if tag:
		var condition = tag.get_string(1)
		var params = tag.get_string(2).trim_prefix(":").split(":")
		var content_if = tag.get_string(3)
		var content_else = tag.get_string(5)
		var before = string.substr(0, tag.get_start())
		var after = string.substr(tag.get_end())
		var condition_res = true
		match condition:
			"input":
				for param in params:
					match param:
						"gamepad":
							condition_res = condition_res if global.device == global.GAMEPAD else false
						"keyboard":
							condition_res = condition_res if global.device == global.KEYBOARD else false
						_:
							push_warning("UNKNOWN CONDITION: %s=%s" % [condition, param])
			"party":
				for param in params:
					match param:
						"plural":
							condition_res = condition_res if global.party.size() > 1 else false
						"singular":
							condition_res = false if global.party.size() > 1 else condition_res
						"female_lead":
							condition_res = condition_res if global.party[0] in [globaldata.ana, globaldata.pippi] else false
						"male_lead":
							condition_res = false if global.party[0] in [globaldata.ana, globaldata.pippi] else condition_res
			_:
				push_warning("UNKNOWN CONDITION: %s" % condition)
				condition_res = null
		var res
		if condition_res == null:
			res = before + after
		elif condition_res:
			res = before + content_if + after
		else:
			res = before + content_else + after
		if string == res:
			return res
		else:
			return _replace_ifs(res)
	
	else:
		return string

# LOCALIZATION Code added to handle multiple item articles
func get_item_or_skill_articles(item, articleIdx: int = -1):
	var articleStr = tr(item.article)
	var articleArray = articleStr.split(",")
	
	if articleIdx == -1:
		return Array(articleArray)
	else:
		return articleArray[articleIdx]

# LOCALIZATION Code added to handle multiple articles for battlers (includes pronouns, suffixes, etc.)
func get_battler_articles(battler, articleIdx : int = -1):
	var articleStr
	if battler.has("article"):
		articleStr = tr(battler.article)
	else:
		articleStr = tr("ARTICLES_DEFAULT")

	var articleArray = articleStr.split(",")

	for i in articleArray.size():
		# In case the "articles" are actually alternative names, [name] reverts to the actual nickname (useful for Polish)
		articleArray[i] = articleArray[i].replace("[name]", battler.nickname)
		# French elision in the case of articles (for user-defined party member names)
		articleArray[i] = replaceText(articleArray[i])
	
	if articleIdx == -1:
		return Array(articleArray)
	else:
		return articleArray[articleIdx]
	
func get_skill_level(skill):
	if skill.has("level") and skill.get("skillType") == "psi":
		var skill_level = int(skill["level"])
		if skill_level in range(0, PSI_LEVELS.length()):
			return tr("BATTLE_LETTER_WHITESPACE") + PSI_LEVELS[skill_level]
	return ""

func get_number_articles(number, article_idx: int = -1):
	var article_array = tr("ARTICLES_NUMBERS").split(",")

	for i in article_array.size():
		article_array[i] = article_array[i].format([number])
		article_array[i] = replaceText(article_array[i])
		
	if article_idx == -1:
		return Array(article_array)
	else:
		return article_array[article_idx]


func get_french_elision(nextWord):
	nextWord = replaceText(nextWord)
	var vowels = "aeiouáàâäæéèêëíìîïóòôöœúùûü"
	if nextWord.length() > 0 and nextWord[0].to_lower() in vowels:
		return "'"
	else:
		return "e "

func get_german_genitive(prevWord):
	prevWord = replaceText(prevWord)
	if prevWord.ends_with('s') or prevWord.ends_with('x'):
		return "'"
	else:
		return "s"

func get_polish_declension(name, gender, case):
	return polishDeclension.get_polish_declension(name, gender, case)
	
func get_russian_declension(name, gender, case):
	return russianDeclension.get_russian_declension(name, gender, case)

func get_korean_particle(prevWord, type):
	if hangul.ends_with_vowel(prevWord, type == 4):
		return ["는","가","를","와","로"][type]
	else:
		return ["은","이","을","과","으로"][type]

func get_key_name(key, device = global.device):
	var keyname = ""
	for event in InputMap.get_action_list(key):
		if (device == global.KEYBOARD and event is InputEventKey)\
		or (device == global.GAMEPAD and event is InputEventJoypadButton)\
		or (device == global.GAMEPAD and event is InputEventJoypadMotion):
			return get_key_name_from_event(event)

func is_key_allowed(event):
	return get_key_name_from_event(event) != null

func get_key_name_from_event(event):
	if event is InputEventKey:
		return get_key_from_scancode(event.scancode)
	elif event is InputEventJoypadButton:
		return get_button_name(Input.get_joy_button_string(event.button_index))
	elif event is InputEventJoypadMotion:
		return

func get_key_from_scancode(scancode):
	var SPECIAL_KEY_LABELS = {KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←", KEY_RIGHT: "→", KEY_KP_MULTIPLY: "*", KEY_KP_DIVIDE: "/", KEY_KP_SUBTRACT: "-", KEY_KP_PERIOD: ".", KEY_KP_ADD: "+", KEY_KP_0: "0", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_KP_4: "4", KEY_KP_5: "5", KEY_KP_6: "6", KEY_KP_7: "7", KEY_KP_8: "8", KEY_KP_9: "9", KEY_SPACE: "KEYBOARD_SPACE"}

	var ALLOWED_KEYS = SPECIAL_KEY_LABELS.keys() + [KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_INSERT, KEY_DELETE, KEY_PAUSE, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN, KEY_SHIFT, KEY_CONTROL, KEY_META, KEY_ALT, KEY_SUPER_L, KEY_SUPER_R, KEY_MENU, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12, KEY_F13, KEY_F14, KEY_F15, KEY_F16]

	if scancode in SPECIAL_KEY_LABELS:
		return tr(SPECIAL_KEY_LABELS[scancode])
	
	elif OS.is_scancode_unicode(scancode):
		if char(scancode) in "            ​  　﻿\t": # Filtering out non-printable characters
			return
		else:
			return char(scancode)
	
	elif scancode in ALLOWED_KEYS:
		var key_str = OS.get_scancode_string(scancode)
		var key_translated = tr("KEYBOARD_" + key_str.to_upper().replace(" ", "_"))
		if key_translated.begins_with("KEYBOARD_"):
			return key_str
		else:
			return key_translated

func get_button_name(button_string):
	var current_style = buttonsStyle
	if current_style == BTN_STYLES.DETECT:
		current_style = global.detect_buttons_style()
	match button_string:
		"Face Button Bottom":
			return "B✖A"[current_style]
		"Face Button Left":
			return "Y■X"[current_style]
		"Face Button Right":
			return "A●B"[current_style]
		"Face Button Top":
			return "X▲Y"[current_style]
		"DPAD Up":
			return "↑"
		"DPAD Down":
			return "↓"
		"DPAD Left":
			return "←"
		"DPAD Right":
			return "→"
		"L2":
			return ["ZL", "L2", "L2"][current_style]
		"R2":
			return ["ZR", "R2", "R2"][current_style]
		"L3":
			return ["LS", "L3", "L3"][current_style]
		"R3":
			return ["RS", "R3", "R3"][current_style]
		"Select":
			return ["-", "Share", "Select"][current_style]
		"Start":
			return ["+", "Optns", "Start"][current_style]
		_:
			return(button_string.replace(" ", "").substr(0, 6))

var text = {
	"actions":{
		"talk": "Talk",
		"check": "Check",
		"goods": "Goods",
		"psi": "PSI",
		
		"map": "Map",
		"stats": "Stats",
		"bash": "Bash",
		"guard": "Guard",
		"flee": "Flee"
	},
	"stats":{
		"cash": "Cash",
		"dollarsign": "$",
		"commands": "Commands",
		"status": "Status",
		"equipments": "Equipments",
		"elodies": "Melodies",
		"name": "Name",
		"lvl": "Lvl",
		"hp" : "HP",
		"pp": "PP",
		"offense": "Offense",
		"defence": "Defence",
		"speed": "Speed",
		"iq": "IQ",
		"guts": "Guts",
		"exp": "Exp"
	},
	"options":{
		"equip": "Equip",
		"info": "Info",
		"eat": "Eat",
		"use": "Use",
		"give": "Give",
		"drop": "Drop"
	},
	"title":{
		"start": "Start",
		"options": "Options",
		"soundtest": "Sound Test"
	}
}

var keys = {"Catacombs": 0}

var flags = {
	##################
	#Melodies
	##################
	"doll_melody": false,
	"canary_melody": false,
	"monkey_melody": false,
	"piano_melody": false,
	"cactus_melody": false,
	"dragon_melody": false,
	"eve_melody": false,
	"grave_melody": false,
	##################
	#Abilities
	##################
	"switch_leader": true,
	"bat": true,
	"laser": true,
	"PKfire": true,
	"PKfreeze": true,
	"PKthunder": true,
	"eagle_feather": true,
	"teleport": true,
	##################
	#Misc
	##################
	"earned_cash": false,
	"good_morning": false,
	"saved": false,
	##################
	#Debug
	##################
	"npc_appear_1": false,
	"npc_disappear_1": false,
	"npc_dialog_1": false,
	"npc_dialog_2": false,
	"debug_present_1": false,
	"debug_present_2": false,
	"debug_present_3": false,
	"debug_present_4": false,
	"debug_present_5": false,
	"debug_present_6": false,
	"debug_present_7": false,
	"debug_present_8": false,
	"debug_present_9": false,
	"debug_present_10": false,
	"debug_present_11": false,
	"debug_present_12": false,
	"debug_present_13": false,
	"debug_present_14": false,
	"debug_present_15": false,
	"debug_present_16": false,
	"debug_present_17": false,
	"debug_present_18": false,
	"debug_present_19": false,
	"debug_present_20": false,
	##################
	#Ninten's House
	##################
	"poltergeist": false,
	"mimmie_door_opened": false,
	"doll_attack": false,
	"pillow_attack": false,
	"minnie_leave": false,
	"minnie_door": false,
	"doll_defeated": false,
	"phone_ring": false,
	"talked_to_dad": false,
	"mimmie_ask_key": false,
	"carol_ask_key": false,
	"mick_scratch": false,
	"mick_telepathy": false,
	"ninten_basement_door": false,
	"got_juice": false,
	"got_diary": false,
	"got_dog_treats": false,
	"basement_pres_2": false,
	"basement_pres_3": false,
	"gave_treats": false,
	
	##################
	#Podunk
	##################
	"podunk_pres_1": false,
	"podunk_pres_2": false,
	"podunk_pres_3": false,
	"podunk_pres_4": false,
	"podunk_pres_5": false,
	"podunk_pres_6": false,
	"beat_dog_bridge": false,
	"pippis_mom_call": false,
	"pippis_mom_help": false,
	##################
	#Podunk Cemetery
	##################
	"disguised_zombie_defeated": false,
	"cem_roots_grown": false,
	"got_shovel": false,
	"returned_shovel": false,
	"cem_pres_1": false,
	"cem_pres_2": false,
	"cem_pres_3": false,
	"cem_pres_4": false,
	"cem_pres_5": false,
	
	##################
	#Podunk Catacombs
	##################
	"hidden_entrance_opened": false,
	"pippi_fight": false,
	"pippi_rescued": false,
	"courage_badge_received": false,
	"church_door_opened": false,
	"church_exited": false,
	
	"catac_pres_1": false,
	"catac_pres_2": false,
	"catac_pres_3": false,
	"catac_pres_4": false,
	"catac_pres_5": false,
	"catac_pres_6": false,
	"catac_pres_7": false,
	"catac_pres_8": false,
	"catac_pres_9": false,
	
	"catac_item_1": false,
	"catac_item_2": false,
	"catac_item_3": false,
	"catac_item_4": false,
	"catac_item_5": false,
	"catac_item_6": false,
	"catac_item_7": false,
	
	"catac_plate_1": false,
	"catac_plate_2": false,
	"catac_plate_3": false,
	"catac_plate_4": false,
	"catac_plate_5": false,
	
	"catac_key_1": false,
	"catac_key_2": false,
	"catac_key_3": false,
	
	"catac_door_1":false,
	"catac_door_2":false,
	"catac_door_3":false,
	##################
	#return to podunk
	##################
	"pippi_town_hall": false,
	"canary_found": false,
	"wally_attack": false,
	"wally_defeat": false,
	"pippi_reunite": false,
	"alfred_song": false,
	"leave_canary_village": false,
	"pippi_delivered": false,
	"mayor_key_not_received": false,
	"zoo_key_received": false,
	
	##################
	#Zoo
	##################
	"zoo_key_stolen": false,
	"zoo_pres_1": false,
	"zoo_pres_2": false,
	"zoo_pres_3": false,
	"zoo_pres_4": false,
	"zoo_office_pres_1": false,
	"zoo_office_pres_2": false,
	"zoo_freed": false,
	"monkey_apologize": false,
	"guard_moved": false,
	##################
	#Snowman
	##################
	"snow_pres_1": false,
	
	##################
	#Rematches
	##################
	"pippi_rematch": false,
	"wally_rematch": false,
	"starman_jr_rematch": false,

	##################
	#Exploration
	##################
	"visited_podunk": true,
	"visited_magicant": false,
	"visited_merrysville": false,
	"visited_reindeer": false,
	"visited_spookane": false,
	"visited_snowman": false,
	"visited_yucca": false,
	"visited_youngtown": false,
	"visited_ellay": false,
	"visited_mtitoi": false
}

func _init():
	var dir = Directory.new()
	
	_load_data("res://Data/BattleSkills/", skills)
	_load_data("res://Data/FieldSkills/", fieldSkills)
	_load_data("res://Data/Items/", items)
	_load_data("res://Data/Shops/", shopLists)
	_load_data("res://Data/MapMarkers/", mapMarkers)


func _load_data(path, dest, sub_dir = ""):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name in [".", ".."]:
					_load_data("%s/%s/" % [path, file_name], dest, "%s%s/" % [sub_dir, file_name])
			else:
				if file_name.ends_with(".json"):
					var json_data = get_json_file(path + file_name)
					dest[sub_dir + file_name.replace(".json", "")] = json_data
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)


func reset_data():
	playtime = 0
	earned_cash = 0
	cash = 0
	bank = 0
	keys = {"Catacombs": 0}
	respawnPoint = Vector2.ZERO
	respawnScene = ""
	favoriteFood = "Prime Rib"
	menuFlavor = "Plain"
	uiManager.set_menu_flavors("Plain")
	textSpeed = 0.035
	buttonPrompts = "Both"
	description = true
	InventoryManager.resetInventories()
	global.persistPlayer.run_sound = "wood.mp3"
	global.party.clear()
	global.partyNpcs.clear()
	global.party.append(ninten)
	for i in [ninten, ana, lloyd, pippi, teddy]:
		i["nickname"] = ""
		i["status"] = []
		i["equipment"] = {"weapon": "", "body": "", "head" : "", "other": ""}
		i["learnedSkills"] = []
		i["passiveSkills"] = []
		i["level"] = 1
		i["exp"] = 0
		i["boosts"] = {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
		}
		for stat in player_stat_target_table[i["name"]]:
			i[stat] = player_stat_target_table[i["name"]][stat][0]
			if "max" in stat:
				i[stat.replace("max", "")] = player_stat_target_table[i["name"]][stat][0]
	InventoryManager.addItem("ninten", "BaseballCap")
	InventoryManager.equipItem("ninten", 0)
	for flag in flags:
		flags[flag] = false

func upgrade_from_old_save():
	for i in [ninten, ana, lloyd, pippi, teddy, flyingman, canarychick, eve]:
		if not "article" in i:
			i["article"] = "ARTICLES_%s" % i["name"].to_upper()
	flags["visited_podunk"] = true

func get_json_file(filepath: String):
	var file = File.new()
	if file.file_exists(filepath):
		file.open(filepath, File.READ)
		var fileText = file.get_as_text()
		var validation = validate_json(fileText)
		if validation == "": # validate_json() returns empty string if valid.
			return parse_json(fileText)
		else:
			push_warning("Json format had errors:\n" + validation)
			return {}
	else:
		push_warning("Was not able to find json at " + filepath)
		return {}

func give_status(character, status):
	if !get(character)["status"].has(ailments.Unconscious) and !get(character)["status"].has(status_name_to_enum(status)):
		get(character)["status"].append(status_name_to_enum(status))

func status_name_to_enum(status_name):
	var res = ailments.get(status_name.capitalize())
	return -1 if res == null else res

func status_enum_to_name(status) -> String:
	if status < ailments.size():
		return ailments.keys()[status].to_lower()
	else:
		return ""

func get_inline_stat(stat):
	return tr("INLINE_STAT_" + stat.to_upper())

# LOCALIZATION Code added: Shortens item names to fit and adds ellipsis (for equip and status screens)
#func fit_item_name_to_label(label, item):
#	# First, trying to fit the full name...
#	label.text = tr(item.name)
#	if label.get_line_count() == 1:
#		return
#	# If the full name is too long, let's try with the shorter one
#	text = tr(get_item_short_name(item))
#	label.text = text
#	# And if needed, let's try to shorten it further...
#	while len(text) > 0 && label.get_line_count() > 1:
#		text = text.rstrip(text[-1])
#		while len(text) > 0 && text[-1] == " ":
#			text = text.rstrip(" ")
#		label.text = text + tr("SYMBOL_ELLIPIS")
#
#func get_item_short_name(item):
#	# Making sure the corresponding key has a translation (I couldn't find a better way)
#	if "short_name" in item and tr(item["short_name"]) != item["short_name"]:
#		return item["short_name"]
#	else:
#		return item["name"]
