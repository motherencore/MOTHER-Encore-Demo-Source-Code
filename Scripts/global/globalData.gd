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
const languages = ["english", "french"]
var saveFile = 0
var playtime = 0
var language = "english"
var winSize = 3
var musicVolume = 0
var sfxVolume = 0
var earned_cash: int = 0
var cash: int = 0
var bank: int = 0
var levelCap = 20
var respawnPoint = Vector2.ZERO
var respawnScene = ""
var description = true
var favoriteFood = "Oreos"
var menuFlavor = "Plain"
var textSpeed = 0.02
var buttonPrompts = "Both"
var dialogHintColor = "ea8b2c"
var playerName = "You"
var ninten = {
	"name": "ninten",
	"nickname": "ryu",
	"sprite": "Ninten", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": ["lifeUpA", "lifeUpB"],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 75, 
	"maxhp": 75, 
	"pp": 30,
	"maxpp": 30, 
	"offense": 10, 
	"defense": 12, 
	"speed": 8,
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
	"pronoun": "his",
	} 
var ana = {
	"name": "ana",
	"nickname": "Ana",
	"sprite": "Ana", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": ["pkFireA", "pkFreezeA"],
	"passiveSkills": [],
	"level": 1, 
	"exp": 0,
	"hp": 40, 
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
	"pronoun": "her"} 
var lloyd = {
	"name": "lloyd", 
	"nickname": "Lloyd", 
	"sprite": "Lloyd", 
	"status": [], 
	"equipment": {"weapon": "", "body": "", "head" : "", "other": ""},
	"learnedSkills": ["spy"],
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
	"pronoun": "his"} 
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
	"pronoun": "his"} 
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
	"pronoun": "her"} 
var flyingman = {
	"name": "flyingman", 
	"nickname": "Flying Man", 
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
	"pronoun": "his"} 
var canarychick = {
	"name": "canarychick", 
	"nickname": "Canary Chick", 
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
	"pronoun": "its"} 

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
const items = {}
const shopLists = {}

func replaceText(string):
	if "[Ninten]" in string:
		string = string.replace("[Ninten]", ninten["nickname"])
		
	if "[Ana]" in string:
		string = string.replace("[Ana]", ana["nickname"])

	if "[Lloyd]" in string:
		string = string.replace("[Lloyd]", lloyd["nickname"])

	if "[Teddy]" in string:
		string = string.replace("[Teddy]", teddy["nickname"])

	if "[Pippi]" in string:
		string = string.replace("[Pippi]", pippi["nickname"])
	
	if "PartyLeadPrn" in string:
		string = string.replace("PartyLeadPrn", global.party[0]["pronoun"])
	
	if "PartyLead" in string:
		string = string.replace("PartyLead", global.party[0]["nickname"])
	
	if "FavFood" in string:
		string = string.replace("FavFood", favoriteFood)
	
	if "ItemName" in string:
		string = string.replace("ItemName", global.itemname)
	
	if "ItemReceiver" in string:
		string = string.replace("ItemReceiver", global.receiver)
	
	if "ItemArt" in string:
		string = string.replace("ItemArt", global.itemart)
	
	if "EarnedCash" in string:
		string = string.replace("EarnedCash", "$" + var2str(earned_cash))
		earned_cash = 0
		flags["earned_cash"] = false
		
	if "CurrentCash" in string:
		string = string.replace("CurrentCash", "$" + var2str(cash))
	
	if "BankCash" in string:
		string = string.replace("BankCash", "$" + var2str(bank))
	
	#replace User Input keys
	if "[ui_accept]" in string:
		string = string.replace("[ui_accept]", get_key_name("ui_accept"))
	
	if "[ui_cancel]" in string:
		string = string.replace("[ui_cancel]", get_key_name("ui_cancel"))
	
	if "[ui_select]" in string:
		string = string.replace("[ui_select]", get_key_name("ui_select"))
	
	if "[ui_toggle]" in string:
		string = string.replace("[ui_toggle]", get_key_name("ui_toggle"))
	
	if "[ui_ctrl]" in string:
		string = string.replace("[ui_ctrl]", get_key_name("ui_ctrl"))
	
	if "[ui_up]" in string:
		string = string.replace("[ui_up]", get_key_name("ui_up"))
	
	if "[ui_down]" in string:
		string = string.replace("[ui_down]", get_key_name("ui_down"))
	
	if "[ui_left]" in string:
		string = string.replace("[ui_left]", get_key_name("ui_left"))
	
	if "[ui_right]" in string:
		string = string.replace("[ui_right]", get_key_name("ui_right"))
	
	if "[color]" in string:
		string = string.replace("[color]", "[color=#"+ dialogHintColor + "]")
	
	return string

func get_key_name(key):
	var keyname = ""
	for action in InputMap.get_action_list(key):
		if global.device == "Keyboard":
			if action is InputEventKey:
				keyname = OS.get_scancode_string(action.scancode)
				if keyname == "Control":
					keyname = "CTRL"
				return keyname
		if global.device == "Gamepad":
			if action is InputEventJoypadButton:
				keyname = get_button_name(Input.get_joy_button_string(action.button_index))
				return keyname
	return keyname

func get_button_name(button_string):
	match button_string:
		"Face Button Bottom":
			return("A")
		"Face Button Left":
			return("X")
		"Face Button Right":
			return("B")
		"Face Button Top":
			return("Y")
		_:
			return(button_string)

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
	#melodies
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
	#abilities
	##################
	"switch_leader": true,
	"bat": true,
	"laser": true,
	"PKfire": true,
	"PKfreeze": true,
	"PKthunder": true,
	"eagle_feather": true,
	##################
	#Misc
	##################
	"earned_cash": false,
	"good_morning": false,
	##################
	#Debug
	##################
	"npc_appear_1": true,
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
	#ninten's house
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
	#podunk
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
	#Podunk Cemetary
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
	
	"catac_pres_1": false,
	"catac_pres_2": false,
	"catac_pres_3": false,
	"catac_pres_4": false,
	"catac_pres_5": false,
	"catac_pres_6": false,
	"catac_pres_7": false,
	"catac_pres_8": false,
	"catac_pres_9": false,
	
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
	"snow_pres_1": false
}

func _init():
	# load battle skills
	var path = "res://Data/BattleSkills/"
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(".json"):
					print(file_name)
					var skillData = get_json_file(path + file_name)
					skills[file_name.replace(".json", "")] = skillData
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	path = "res://Data/Items/"
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(".json"):
					var itemData = get_json_file(path + file_name)
					items[file_name.replace(".json", "")] = itemData
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the items directory.")
	
	path = "res://Data/Shops/"
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				if file_name.ends_with(".json"):
					var shopListData = get_json_file(path + file_name)
					shopLists[file_name.replace(".json", "")] = shopListData
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the shops directory.")

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
	global.persistPlayer.run_sound = "wood.wav"
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
	match(status_name):
		"asthma": return ailments.Asthma
		"blinded": return ailments.Blinded
		"burned": return ailments.Burned
		"cold": return ailments.Cold
		"confused": return ailments.Confused
		"forgetful": return ailments.Forgetful
		"nausea": return ailments.Nausea
		"numb": return ailments.Numb
		"poisoned": return ailments.Poisoned
		"sleeping": return ailments.Sleeping
		"sunstroked": return ailments.Sunstroked
		"mushroomized": return ailments.Mushroomized
		"unsconcious": return ailments.Unconscious
		_: return -1

func status_enum_to_name(status) -> String:
	match(status):
		ailments.Asthma: return "asthma"
		ailments.Blinded: return "blinded"
		ailments.Burned: return "burned"
		ailments.Cold: return "cold"
		ailments.Confused: return "confused"
		ailments.Forgetful: return "forgetful"
		ailments.Nausea: return "nausea"
		ailments.Numb: return "numb"
		ailments.Poisoned: return "poisoned"
		ailments.Sleeping: return "sleeping"
		ailments.Sunstroked: return "sunstroked"
		ailments.Mushroomized: return "mushroomized"
		ailments.Unconscious: return "unsconcious"
		_: return ""

func status_int_to_enum(number):
	number = int(number)
	match(number):
		0: return ailments.Asthma
		1: return ailments.Blinded
		2: return ailments.Burned
		3: return ailments.Cold
		4: return ailments.Confused
		5: return ailments.Forgetful
		6: return ailments.Nausea
		7: return ailments.Numb
		8: return ailments.Poisoned
		9: return ailments.Sleeping
		10: return ailments.Sunstroked
		11: return ailments.Mushroomized
		12: return ailments.Unconscious
		_: return -1
func get_psi_level_ascii(level: int):
	match(level):
		0: #alpha
			return "¢"
		1: #beta
			return "\\"
		2: #gamma
			return "£"
		3: #omega
			return "€‎"
		4: #theta?
			return "^"
		_:
			return ""
		

func capitalize_stat(stat):
	match stat:
		"hp":
			return "HP"
		"pp":
			return "PP"
		"iq":
			return "IQ"
		_:
			return stat.capitalize()
