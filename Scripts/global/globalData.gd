extends Node

enum BtnStyles {NINTENDO, PLAYSTATION, XBOX, DETECT}

const ALLOWED_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_KP_MULTIPLY, KEY_KP_DIVIDE, KEY_KP_SUBTRACT, KEY_KP_PERIOD, KEY_KP_ADD, KEY_KP_0, KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5, KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9, KEY_SPACE, KEY_ESCAPE, KEY_TAB, KEY_BACKSPACE, KEY_ENTER, KEY_INSERT, KEY_DELETE, KEY_PAUSE, KEY_HOME, KEY_END, KEY_PAGEUP, KEY_PAGEDOWN, KEY_SHIFT, KEY_CONTROL, KEY_META, KEY_ALT, KEY_SUPER_L, KEY_SUPER_R, KEY_MENU, KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12, KEY_F13, KEY_F14, KEY_F15, KEY_F16]
const TEXT_SPEEDS := [0.02, 0.035, 0.05]
const TEXT_SPEEDS_NAMES := ["FAST", "MEDIUM", "SLOW"]
const BUTTON_PROMPTS := ["Both", "Objects", "NPCs", "None"]
const FLAVORS := ["Plain", "Mint", "Strawberry", "Banana", "Peanut", "Grape", "Melon"]
const LANG_ALT := "upupdodolerilericaac"
const CONSTANT_CHAR_DATA := {
	"ninten": {
		"name": "ninten",
		"sprite": "Ninten",
		"article": "ARTICLES_NINTEN",
		"basic_skill": "attack",
	},
	"ana": {
		"name": "ana",
		"sprite": "Ana",
		"article": "ARTICLES_ANA",
		"basic_skill": "attack",
	},
	"lloyd": {
		"name": "lloyd",
		"sprite": "Lloyd",
		"article": "ARTICLES_LLOYD",
		"basic_skill": "attack",
	},
	"teddy": {
		"name": "teddy",
		"sprite": "Teddy",
		"article": "ARTICLES_TEDDY",
		"basic_skill": "attack",
	},
	"pippi": {
		"name": "pippi",
		"sprite": "Pippi",
		"article": "ARTICLES_PIPPI",
		"basic_skill": "attack",
	},
	"flyingman": {
		"name": "flyingman", 
		"nickname": "[tr:NAME_FLYINGMAN]", 
		"article": "ARTICLES_FLYINGMAN",
		"sprite": "FlyingMan", 
		"level": 99, 
		"exp": 0, 
		"maxhp": 400, 
		"maxpp": 0, 
		"speed": 14, 
		"offense": 55, 
		"defense": 25, 
		"iq": 25, 
		"guts": 25,
		"untargetable": true,
		"skills": [{
			"skill": "bash",
			"weight": 1
		}]
	},
	"canarychick": {
		"name": "canarychick", 
		"nickname": "[tr:NAME_CANARYCHICK]",
		"article": "ARTICLES_CANARYCHICK",
		"sprite": "CanaryChick", 
		"level": 1, 
		"exp": 0, 
		"hp": 1, 
		"pp": 0, 
		"maxhp": 0, 
		"maxpp": 0, 
		"speed": 1, 
		"offense": 1, 
		"defense": 1, 
		"iq": 1, 
		"guts": 1,
		"untargetable": true,
		"skills": [{
			"skill": "canaryLife1",
			"weight": 6
		}, {
			"skill": "canaryLife2",
			"weight": 1
		}],
	},
	"eve": {
		"name": "eve", 
		"nickname": "[tr:NAME_EVE]",
		"article": "ARTICLES_EVE",
		"sprite": "FlyingMan", 
		"level": 1, 
		"exp": 0, 
		"maxhp": 0, 
		"maxpp": 0, 
		"speed": 1, 
		"offense": 1, 
		"defense": 1, 
		"iq": 1, 
		"guts": 1, 
		"untargetable": true,
		"skills": [{
			"skill": "bash",
			"weight": 1
		}],
	}
}

var _yaml_lib = null

var saveFile := 0
var playtime := 0
var winSize := 3
var musicVolume := 0
var sfxVolume := 0
var earned_cash := 0
var cash := 10000
var bank := 0
var phone_units: int setget ,_get_phone_units
var levelCap := 20
var respawnPoint := Vector2.ZERO
var respawnScene := ""
var description := true
var rumble := true
var favoriteFood := "Oreos"
var menuFlavor: String = FLAVORS[0]
var textSpeed: float = TEXT_SPEEDS[0]
var buttonPrompts: String = BUTTON_PROMPTS[0]
var playerName := ""
var rareDrops := {}
var buttonsStyle: int = BtnStyles.DETECT
var encountered := {}
var ninten := {
	"nickname": "Ninten",
	"status": [], 
	"equipment": {"weapon": "BatPlastic", "body": "", "arms" : "", "other": "BaseballCap"},
	"learnedSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 30, 
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
} 
var ana := {
	"nickname": "Ana",
	"status": [], 
	"equipment": {"weapon": "", "body": "", "arms" : "", "other": ""},
	"learnedSkills": [],
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
}
var lloyd := {
	"nickname": "Lloyd", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "arms" : "", "other": ""},
	"learnedSkills": [],
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
	"guts": 0,
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
}
var teddy := {
	"nickname": "Teddy",
	"status": [], 
	"equipment": {"weapon": "", "body": "", "arms" : "", "other": ""}, 
	"learnedSkills": [""],
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
}
var pippi := {
	"nickname": "Child", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "arms" : "", "other": ""}, 
	"learnedSkills": [],
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
}
var canarychick := {
	"status": [],
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
}
var flyingman := {
	"hp": 400, 
	"pp": 0, 
	"status": [], 
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	},
}
var eve := {
	"hp": 400, 
	"pp": 0, 
	"status": [], 
	"boosts": {
		"maxhp": 0,
		"maxpp": 0, 
		"offense": 0, 
		"defense": 0, 
		"speed": 0, 
		"iq": 0, 
		"guts": 0,
	}
}

# The stat target table is a dictionary with stats that each have an array
# Each stat array represents where a stat should be at that (index * 10) level
# e.g. Ninten's offense at level 30 would be in index 3, the 4th number in the array
#      Level 30 - Offense Stat target is 24
const player_stat_target_table := {
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
		#"guts": [3, 5, 6, 9, 11, 14, 17, 20, 23, 27, 30],
		"guts": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
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

const player_learn_skill_table_flags := {
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

const player_learn_skill_table := {
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

const skills := {}
const fieldSkills := {}
const passiveSkills = {}
const items := {}
const shopLists := {}
const mapMarkers := {}
const namingSequences := {}

var keys := {}

var object_flags := {}

var flags := {
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
	"eagle_feather": true,
	##################
	#Misc
	##################
	"earned_cash": false,
	"good_morning": false,
	"saved": false,
	##################
	#Debug
	##################
	"npc_disappear_1": false,
	"npc_dialog_1": false,
	"npc_dialog_2": false,
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
	"got_asthma_spray": false,
	"gave_treats": false,
	##################
	#Podunk
	##################
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
	##################
	#Podunk Catacombs
	##################
	"hidden_entrance_opened": false,
	"pippi_fight": false,
	"pippi_rescued": false,
	"courage_badge_received": false,
	"church_door_opened": false,
	"church_exited": false,
	##################
	#Return to podunk
	##################
	#"pippi_town_hall": false, # Useless?
	"canary_found": false,
	"wally_attack": false,
	"wally_defeat": false,
	"pippi_reunite": false,
	"alfred_song": false,
	"leave_canary_village": false,
	"pippi_delivered": false,
	#"mayor_key_not_received": false, # Useless?
	#"zoo_key_received": false, # Useless
	##################
	#Zoo
	##################
	"zoo_key_stolen": false,
	"zoo_freed": false,
	"monkey_apologize": false,
	"guard_moved": false,
	##################
	#Podunk Rematches
	##################
	"pippi_rematch": false,
	"wally_rematch": false,
	"starman_jr_rematch": false,
	##################
	#Magicant
	##################
	
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
	var to_load = {
		"BattleSkills": skills,
		"FieldSkills": fieldSkills,
		"PassiveSkills": passiveSkills,
		"Items": items,
		"Shops": shopLists,
		"MapMarkers": mapMarkers,
		"NamingSequences": namingSequences
	}
	for key in to_load:
		load_data("res://Data/%s/" % key, to_load[key])
	
	reset_constant_char_data()

func load_data(path, dest, sub_dir = ""):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if not file_name in [".", ".."]:
					load_data("%s/%s/" % [path, file_name], dest, "%s%s/" % [sub_dir, file_name])
			else:
				if file_name.ends_with(".yaml"):
					var json_data = get_json_data(path + file_name)
					dest[sub_dir + file_name.trim_suffix(".yaml")] = json_data
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

func reset_constant_char_data(data = self):
	for char_name in CONSTANT_CHAR_DATA:
		if char_name in data:
			var char_data = CONSTANT_CHAR_DATA[char_name]
			for key in char_data:
				data.get(char_name)[key] = char_data[key]

func reset_data():
	playtime = 0
	earned_cash = 0
	cash = 0
	bank = 0
	keys = {"Catacombs": 0}
	respawnPoint = Vector2.ZERO
	respawnScene = ""
	favoriteFood = ""
	menuFlavor = FLAVORS[0]
	uiManager.set_menu_flavors(FLAVORS[0])
	textSpeed = TEXT_SPEEDS[1]
	buttonPrompts = "Both"
	description = true
	InventoryManager.reset_inventories()
	global.persistPlayer.run_sound = "wood.mp3"
	global.party.clear()
	global.partyNpcs.clear()
	global.party.append(ninten)
	for i in [ninten, ana, lloyd, pippi, teddy]:
		i["nickname"] = ""
		i["status"] = []
		i["equipment"] = {"weapon": "", "body": "", "arms" : "", "other": ""}
		i["learnedSkills"] = []
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
	InventoryManager.equip_item("ninten", 0)
	for flag in flags:
		flags[flag] = false
	object_flags.clear()
	

func get_json_data(file_path: String, fallback: String = "") -> Dictionary:
	var file = File.new()
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		var file_content = file.get_as_text()
		var res = parse_yaml(file_content)
		file.close()
		if res == null:
			push_warning("Couldn't parse yaml file at %s" % file_path)
			return {}
		return res
	else:
		if fallback:
			return get_json_data(fallback)
		else:
			push_warning("Couldn't find yaml file at %s" % file_path)
			return {}

func parse_yaml(content: String):
	if _yaml_lib == null:
		_yaml_lib = load("res://addons/godot-yaml/gdyaml.gdns").new()
	var obj = _yaml_lib.parse(content)
	var res = obj.result
	return res

func get_exp_for_level(level: int) -> int:
	return int(level * level * (level + 1) * .75)

func get_stat_for_level(char_name: String, stat_name: String, level: int) -> int:
	var stats_dict_for_member: Dictionary = player_stat_target_table[char_name]
	var level_tens := min(level / 10, stats_dict_for_member[stat_name].size() - 2)
	var level_units := level - (level_tens * 10)
	var lower_stat: int = stats_dict_for_member[stat_name][level_tens]
	var upper_stat: int = stats_dict_for_member[stat_name][level_tens + 1]
	return int(lerp(lower_stat, upper_stat, level_units / 10.0))

func get_basic_skill(char_name: String) -> String:
	var char_data: Dictionary = self.get(char_name)
	var weapon_name: String = char_data["equipment"]["weapon"]
	if weapon_name:
		var weapon_data: Dictionary = self.items[weapon_name]
		var skill_name: String = weapon_data.get("basic_skill", "")
		if skill_name:
			return skill_name
	return char_data.get("basic_skill", "attack")

# requested_stat: HPrecover, PPrecover, maxhp, maxpp, offense, defense, speed, iq, guts
# if requested_stat is omitted, the most relevant stat value is automatically returned
func get_item_value(item_data: Dictionary, requested_stat := "") -> int:
	var boosts: Dictionary = item_data.get("boost", {})
	if requested_stat:
		return item_data.get(requested_stat, item_data.get("boost", {}).get(requested_stat, 0))
	for stat in boosts:
		if boosts.get(stat, 0) > 0:
			return boosts[stat]
	for recover in ["PPrecover", "HPrecover"]:
		if item_data.get(recover, 0) > 0:
			return item_data[recover]
	return 0

func _get_phone_units() -> int:
	var all_phone_cards: Array = InventoryManager.find_all_occurrences("PhoneCard")
	var sum := 0
	for card in all_phone_cards:
		sum += (card as InventoryManager.Item).doses
	return sum

func has_field_skill(character: Dictionary, skill_name: String) -> bool:
	var skill: Dictionary = fieldSkills.get(skill_name, {})
	var ret := true
	if skill.has("usable") and !skill.usable.get(character.name, false):
		ret = false
	if skill.has("flag") and !flags.get(skill.flag, false):
		ret = false
	if skill.has("battle_skill") and !character.get("learnedSkills", []).has(skill.battle_skill):
		ret = false
	return ret

func is_key_allowed(event):
	return TextTools.get_key_name_from_event(event) != null

