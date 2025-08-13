extends Node

#Todo maybe:
#Do everything (search, organize) with UID items
enum ItemActions { HP_UP, PP_UP, HP_MAX, PP_MAX, STAT_UP, HEAL, HEAL_FAIL }

const _MAX_INVENTORY_SIZE := 16
const _MAX_STORAGE_SIZE := 64
const _MAX_STORAGE_SIZE_GOD := 99

const ID_KEY := "key"
const ID_STORAGE := "storage"
const ID_STORAGE_GOD := "god_storage"

const SLOTS := [ "weapon", "body", "arms", "other" ]
const BOOSTABLE_STATS := [ "maxhp", "maxpp", "offense", "defense", "speed", "iq", "guts" ]
const BOOSTABLE_STATS_COEFFS := { "maxhp": 2,  "maxpp": 2, "offense": 3, "defense": 2, "speed": 1, "iq": 1, "guts": 1 }

#existing IUDs to prevent having several items with same IUD
const used_uids_tab := []

#Class definition for Item object
class Item:
	var ItemName: String
	var uid: int
	var equiped: bool
	var doses: int # how many times it can be consumed
	
	func _init(item_name: String, equiped := false, doses := -1, uid := Item.get_uid(used_uids_tab)):
		ItemName = item_name
		self.equiped = equiped
		self.uid = uid
		self.doses = doses
		if doses == -1:
			self.doses = globaldata.items.get(ItemName, {}).get("doses", 1)
		
	func get_data() -> Dictionary:
		return globaldata.items.get(ItemName, {})
	
	static func get_uid(used_uids) -> int:
		randomize()
		var new_uid = randi()
		while(new_uid in used_uids):
			new_uid = randi()
		used_uids.append(new_uid)
		return new_uid

var Inventories := {
		"ninten": [
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Slingshot"),
			Item.new("BatWooden"),
			Item.new("CourageBadge"),
			Item.new("Antidote"),
			Item.new("EyeDrops"),
			Item.new("AsthmaSpray")
			],
		"lloyd": [
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Bread"),
			],
		"ana": [
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Bread"),
			],
		"teddy": [
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Bread"),
			Item.new("Bread"),

		],
		"pippi": [],
		"canarychick": [],
		"flyingman": [],
		"eve": [],
		"key": [
			Item.new("CashCard"),
		],
		"storage": [],
		"god_storage": []
	}

func _init():
	_init_god_storage()

func _clear_inventories():
	for inventory in Inventories.keys():
		Inventories[inventory].clear()
	_init_god_storage()

func _init_god_storage():
	for item_id in globaldata.items:
		var inv_item = Item.new(item_id)
		Inventories[ID_STORAGE_GOD].append(inv_item)
	sort_auto(ID_STORAGE_GOD)

#load inventories from savegame data
func load_inventories(serialized_inv: Dictionary):
	_clear_inventories()
	for inventory in serialized_inv.keys():
		if inventory != ID_STORAGE_GOD:
			var inv_content = []
			for serialized_item in serialized_inv[inventory]:
				if serialized_item.ItemName in globaldata.items:
					inv_content.append(Item.new(serialized_item["ItemName"], serialized_item["equiped"], serialized_item.get("doses", 1), int(serialized_item["uid"])))
					#var previouslyEquipped = serialized_item["equiped"]
			Inventories[inventory] = inv_content
	
#save inventories into savegame data	
func save_inventories() -> Dictionary:
	var serialized_inv = {}
	for inventory in Inventories.keys():
		if inventory != ID_STORAGE_GOD:
			var inv_content = []
			for item in Inventories[inventory]:
				var serialized_item = {"ItemName":item.ItemName, "equiped":item.equiped, "doses":item.doses, "uid":item.uid}
				inv_content.append(serialized_item)
			serialized_inv[inventory] = inv_content
	return serialized_inv

#function to add item (item name, target character)
func addItem(character: String, item: String):
	if character in Inventories.keys():
		Inventories[character].append(Item.new(item))
	
#drop item ()
func dropItem(character: String, item_idx: int):
	if character in Inventories.keys():
		var inventory = Inventories[character]
		if inventory[item_idx].equiped == true:
			var chara_data = get_global_data(character)
			var item_name = inventory[item_idx].ItemName
			_remove_boost(character, item_name)
			var item_data = inventory[item_idx].get_data()
			if chara_data["equipment"][item_data["slot"]] != "":
				chara_data["equipment"][item_data["slot"]] = ""
			
		inventory.remove(item_idx)
		
#get inventory content? 
func getInventory(character: String) -> Array:
	return Inventories[character]

#get items corresponding to equip slot, minus already equiped
func get_items_for_slot(char_name: String, slot: String, only_suitable := false, only_unequipped := false) -> Array:
	var ret := []
	var inv = Inventories[char_name]
	for item in inv:
		var item_data = item.get_data()
		var is_suitable = item_data["usable"][char_name]
		if !(only_unequipped and item.equiped) and !(only_suitable and !is_suitable):
			if item_data.get("slot") == slot:
				ret.append(item)
	return ret

func get_equipped_item(char_name: String, slot: String) -> Item:
	var inv = Inventories[char_name]
	for item in inv:
		var item_data = item.get_data()
		if item.equiped and item_data.get("slot") == slot:
			return item
	return null

#search item from uid
func get_item_from_uid(char_name: String, uid: int) -> Item:
	var inv = Inventories[char_name]
	for item in inv:
		if item.uid == uid:
			return item
	return null

#check if any character in your party has a specific item
func check_item_for_all(item_name: String) -> bool:
	for char_name in global.get_party_names() + [ID_KEY]:
		if _check_item(char_name, item_name):
			return true
	return false

func check_item_in_storage(itemName: String) -> bool:
	return _check_item(ID_STORAGE, itemName)

func _check_item(char_name: String, item_name: String) -> bool:
	for item in Inventories[char_name]:
		if item.ItemName == item_name:
			return true
	return false

#remove the first instance of an item 
func remove_item(item_name: String) -> bool:
	for char_name in global.get_party_names() + [ID_KEY]:
		var res := removeItemFromChar(char_name, item_name)
		if res:
			return true
	return false

func removeItemFromChar(character, item_name) -> bool:
	var inv = Inventories[character]
	for i in inv.size():
		if inv[i].ItemName == item_name:
			dropItem(character, i)
			return true
	return false

#test if given character inventory is full
func isInventoryFull(character)-> bool:
	character = character.to_lower()
	var inv_size = get_inventory_size(character)
	return inv_size > 0 and Inventories[character].size() >= inv_size

func get_inventory_size(character):
	character = character.to_lower()
	if character == ID_STORAGE:
		return _MAX_STORAGE_SIZE
	elif character == ID_STORAGE_GOD:
		return _MAX_STORAGE_SIZE_GOD
	elif character == ID_KEY:
		return 0
	else:
		return _MAX_INVENTORY_SIZE

#test if party has space in inventory
func has_inventory_space() -> bool:
	for i in global.party.size():
		if !isInventoryFull(global.party[i]["name"]):
			return true
	return false

#give item to anyone who has space in their inventory
func add_item_available(item):
	var item_given = false
	var item_data = Load_item_data(item)
	if item_data.has("keyitem"):
		if item_data["keyitem"]:
			addItem("key",item)
			item_given = true
			global.receiver = global.party[0]
	if !item_given and has_inventory_space():
		for i in global.party.size():
			if !isInventoryFull(global.party[i]["name"]) and !item_given:
				addItem(global.party[i]["name"],item)
				global.receiver = global.party[i]
				item_given = true

func _does_item_have_function(item, function) -> bool:
	var item_data := Load_item_data(item)
	var has_function := false
	if item_data.get("action_one") != null:
		if item_data["action_one"]["function"] == function:
			has_function = true
	if item_data.get("action_two") != null:
		if item_data["action_two"]["function"] == function:
			has_function = true
	return has_function

func is_usable_by(character_name: String, item_name: String) -> bool:
	var item_data = Load_item_data(item_name)
	return item_data.get("usable",{}).get(character_name, false)

func is_equippable(item_name: String) -> bool:
	return _does_item_have_function(item_name, "equip")

func is_equippable_by(character_name: String, item_name: String) -> bool:
	return is_equippable(item_name) and is_usable_by(character_name, item_name)

func is_equipped_by(character_name: String, item_name: String):
	if !is_equippable_by(character_name, item_name):
		return false
	else:
		var item_data = Load_item_data(item_name)
		return item_name == globaldata.get(character_name).equipment[item_data.slot]

#switch item in the inventory for sorting (item1_idx, item2_idx)
func switch_items(character, item1_idx, item2_idx):
	if character in Inventories.keys():
		var item1 = Inventories[character][item1_idx]
		var item2 = Inventories[character][item2_idx]
		
		Inventories[character][item2_idx] = item1
		Inventories[character][item1_idx] = item2
		

#swap item between characters inventories
func swap_between_characters(source, target, source_idx, target_idx):
	var item1 = Inventories[source][source_idx].ItemName
	var item2 = Inventories[target][target_idx].ItemName
	
	if  Inventories[source][source_idx].equiped == true:
		unequip(source, item1)
	
	Inventories[source].remove(source_idx)
	addItem(source,item2)
	
	Inventories[target].remove(target_idx)
	addItem(target,item1)

func _sort_auto(a: Item, b: Item) -> bool:
	var STEP := 100000
	var STEP_SLOT := 10000
	var SCORE_CAT_HP_RECOVER	:= (11 - 1)  * STEP # HP recovery items come first
	var SCORE_CAT_PP_RECOVER	:= (11 - 2)  * STEP # PP recovery items come second
	var SCORE_CAT_BATTLE_ITEMS	:= (11 - 3)  * STEP # battle items come third
	var SCORE_CAT_STATUS_HEALS	:= (11 - 4)  * STEP # status healing items come fourth
	var SCORE_CAT_CONSUMABLE	:= (11 - 5)  * STEP # consumable items come fifth
	var SCORE_CAT_USABLE		:= (11 - 6)  * STEP # usable items come sixth
	var SCORE_CAT_OTHERS		:= (11 - 7)  * STEP # uncategorized items come fifth to last
	var SCORE_CAT_BOOSTS		:= (11 - 8)  * STEP # stats boosting items come fourth to last
	var SCORE_CAT_UNEQUIPED		:= (11 - 9)  * STEP # unequiped items come third to last
	var SCORE_CAT_EQUIPED		:= (11 - 10) * STEP # equiped items come second to last
	var SCORE_CAT_KEY			:= (11 - 10) * STEP # key items come last

	var sorting_scores := []
	
	for item in [a, b]:
		var item_data: Dictionary = item.get_data()

		var boost_total := _get_boost_total(item_data.get("boost", {}))
		var function: String = item_data["action_one"]["function"] if item_data.get("action_one") else ""

		var score := 0
		
		if item_data.get("keyitem", false):
			score += SCORE_CAT_KEY
		elif item_data.get("battle_action"):
			score += SCORE_CAT_BATTLE_ITEMS
		elif item_data.get("status_heals"):
			score += SCORE_CAT_STATUS_HEALS
		elif is_equippable(item.ItemName):
			if !item.equiped:
				score += SCORE_CAT_UNEQUIPED
			else:
				score += SCORE_CAT_EQUIPED
			var slot_name: String = item_data["slot"]
			var slot := SLOTS.size() - SLOTS.find(slot_name)
			score += slot * STEP_SLOT
			score += boost_total
		elif boost_total > 0:
			score += SCORE_CAT_BOOSTS
			score += boost_total
		elif item_data.get("PPrecover", 0) > 0:
			score += SCORE_CAT_PP_RECOVER
			score += item_data["PPrecover"]
		elif item_data.get("HPrecover", 0) > 0:
			score += SCORE_CAT_HP_RECOVER
			score += item_data["HPrecover"]
		elif function == "consume":
			score += SCORE_CAT_CONSUMABLE
		elif function == "use":
			score += SCORE_CAT_USABLE
		else:
			score += SCORE_CAT_OTHERS
		
		sorting_scores.append(score)

	if sorting_scores[0] > sorting_scores[1]:
		return true
	elif sorting_scores[0] < sorting_scores[1]:
		return false
	else:
		# if scores are equal, sort by name
		return tr(a.get_data()["sorting_name"]) < tr(b.get_data()["sorting_name"])

func sort_auto(char_name: String):
	Inventories[char_name].sort_custom(self, "_sort_auto")

func _get_boost_total(item_boost) -> int:
	var total = 0
	for stat in BOOSTABLE_STATS_COEFFS:
		total += item_boost.get(stat, 0) * BOOSTABLE_STATS_COEFFS[stat]

	return total

#move item between inventory (charactertarget, charactersource)
func give_item(source_char: String, target_char: String, source_item_idx: int):
	if (source_char in Inventories.keys()) and \
			(target_char in Inventories.keys()) and \
			(source_char != target_char):
		var item: Item = Inventories[source_char][source_item_idx]
		if item.equiped:
			unequip(source_char, item.ItemName)
		if source_char == ID_STORAGE_GOD:
			Inventories[target_char].append(Item.new(item.ItemName))
		else:
			Inventories[source_char].remove(source_item_idx)
			if target_char != ID_STORAGE_GOD:
				Inventories[target_char].append(item)
		
#use item in inventory
func consume_item(actor: String, item_idx: int, receiver := "") -> Dictionary:
	if receiver == "":
		receiver = actor
	var chara_data := get_global_data(receiver)
	var item_name = Inventories[actor][item_idx].ItemName
	var item_data = Inventories[actor][item_idx].get_data()
	
	var do_consume := true
	var performed_actions := {}
	
	if int(item_data["HPrecover"]) > 0:
		chara_data["hp"] += int(item_data["HPrecover"])
		if chara_data["hp"] >= chara_data["maxhp"] + chara_data.boosts["maxhp"]:
			performed_actions[ItemActions.HP_MAX] = true
			chara_data["hp"] = (chara_data["maxhp"] + chara_data.boosts["maxhp"]) # + trigger UI animation?
		else:
			performed_actions[ItemActions.HP_UP] = int(item_data["HPrecover"])
	
	if int(item_data["PPrecover"]) > 0:
		chara_data["pp"] += int(item_data["PPrecover"])
		if chara_data["pp"] >= chara_data["maxpp"] + chara_data.boosts["maxpp"]:
			chara_data["pp"] = chara_data["maxpp"] + chara_data.boosts["maxpp"] # + trigger UI animation?
			performed_actions[ItemActions.PP_MAX] = true
		else:
			performed_actions[ItemActions.PP_UP] = int(item_data["PPrecover"])

	#heal statuses
	if item_data.has("status_heals"):
		for status in item_data["status_heals"]:
			if StatusManager.has_status(chara_data, status):
				performed_actions[ItemActions.HEAL] = performed_actions.get(ItemActions.HEAL, [])
				performed_actions[ItemActions.HEAL].append(status)
				StatusManager.remove_status(chara_data, status)
			else:
				performed_actions[ItemActions.HEAL_FAIL] = performed_actions.get(ItemActions.HEAL_FAIL, [])
				performed_actions[ItemActions.HEAL_FAIL].append(status)
	
	_apply_boost(receiver, item_name, performed_actions)
	
	#do a lot of thing depending of the item, then
	if do_consume:
		reduce_or_drop_item(actor, item_idx)

	return performed_actions

func reduce_or_drop_item_obj(item: Item):
	for name in global.get_party_names() + [ID_KEY]:
		var index = Inventories[name].find(item)
		if index != -1:
			reduce_or_drop_item(name, index)
			return

func reduce_or_drop_item(user: String, item_idx: int):
	if Inventories[user][item_idx].doses > 1:
		Inventories[user][item_idx].doses -= 1
	else:
		dropItem(user, item_idx)

#transform an item into another in inventory
func transform_item(character, item_idx):
	var chara_data = get_global_data(character)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Inventories[character][item_idx].get_data()
	
	if item_data["transform"] != "":
		addItem(character, item_data["transform"])
	
	#do a lot of thing depending of the item, then
	dropItem(character, item_idx)

func transform_item_by_name(character:String, item_name:String):
	var inv = Inventories[character]
	for i in inv.size():
		if inv[i].ItemName == item_name:
			transform_item(character, i)
			transform_item_by_name(character, item_name)
			break

func transform_item_for_all(item_name: String):
	var party_names = []
	var hasItem = false
	for mem_name in global.get_party_names() + [ID_KEY]:
		transform_item_by_name(mem_name, item_name)

#equip when equipable (current caracter) maybe another system?
func equip_item(character: String, item_idx: int) -> bool:
	var chara_data = get_global_data(character)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Inventories[character][item_idx].get_data()
	if is_equippable(item_name):
		if chara_data["equipment"][item_data["slot"]] != "":
			#un-equip item if needed
			unequip(character, chara_data["equipment"][item_data["slot"]])
		chara_data["equipment"][item_data["slot"]] = item_name
		Inventories[character][item_idx].equiped = true
		_apply_boost(character, item_name)
		return true
	else:
		return false
		
#equip item from Equip Menu using UID
func equip_item_from_uid(character: Dictionary, uid: int):
	var item := get_item_from_uid(character["name"], uid)
	var item_name := item.ItemName
	var item_data := item.get_data()
	if is_equippable(item_name):
		if character["equipment"][item_data["slot"]] != "":
			#un-equip item if needed
			unequip(character["name"], character["equipment"][item_data["slot"]])
		character["equipment"][item_data["slot"]] = item_name
		item.equiped = true
		_apply_boost(character["name"], item_name)
		var chara_data = character
		return true
	else:
		return false
		
#unequip item from character name and item name
func unequip(char_name: String, item_name: String):
	var chara_data := get_global_data(char_name)
	var item_data := Load_item_data(item_name)
	unequip_slot(chara_data, item_data["slot"])
		
#unequip item in a slot
func unequip_slot(character: Dictionary, slot: String):
	var chara_data := character
	var item_name = chara_data["equipment"][slot]
	if chara_data["equipment"][slot] != "":
		chara_data["equipment"][slot] = ""
		var item_data = Load_item_data(item_name)
		_remove_boost(character.name, item_name)
	for item in Inventories[character.name]:
		if item.ItemName == item_name:
			item.equiped = false

#apply boost when equipping item or eating capsule
func _apply_boost(character, item_name, performed_actions := {}):
	var chara_data := get_global_data(character)
	var item_data := Load_item_data(item_name)
	var item_boosts = item_data["boost"]
	for boost in item_boosts.keys():
		if item_boosts[boost] > 0 and chara_data.boosts.keys().find(boost) != -1:
			chara_data.boosts[boost] += item_boosts[boost]
			performed_actions[ItemActions.STAT_UP] = performed_actions.get(ItemActions.STAT_UP, {})
			performed_actions[ItemActions.STAT_UP][boost] = item_boosts[boost]
	
#remove stats boost when unequipping item	
func _remove_boost(character: String, item_name: String):
	var chara_data := get_global_data(character)
	var item_data := Load_item_data(item_name)
	var item_boosts = item_data["boost"]
	for boost in item_boosts.keys():
		if chara_data.boosts.keys().find(boost) != -1:
			chara_data.boosts[boost] -= item_boosts[boost]

# search for item in a character's inventory. Return first idx or -1 if not found
func find_item_index(char_name: String, item_name: String) -> int:
	var inv = Inventories[char_name]
	for i in inv.size():
		if inv[i].ItemName == item_name:
			return i
	return -1

func find_all_occurrences(item_name: String, char_name: String = "") -> Array:
	var char_names: Array
	if char_name:
		char_names = [char_name]
	else:
		char_names = global.get_party_names() + [ID_KEY]
	
	var ret := []
	for char_name in char_names:
		var inv = Inventories[char_name]
		for item in inv:
			if item.ItemName == item_name:
				ret.append(item)
	return ret

#retrieve dat from the yaml file of an item
func Load_item_data(item_name: String) -> Dictionary:
	return globaldata.items.get(item_name, {})

#get character global data from party
func get_global_data(character_name: String) -> Dictionary:
	var ret = null
	for chara in global.party:
		if chara["name"].to_lower() == character_name:
			return chara
	return ret

#resets everything in the inventory to what it should be at the start of the game
func reset_inventories():
	for i in Inventories:
		Inventories[i].clear()
	addItem("key", "CashCard")

############################################################	
#should probably be elswhere, in a character manager, or stats manager?

	
#since equipping item change stats for now, calculate back the boost from item to
#ease comparison
func calculate_stats_boost_from_slot(character: Dictionary, slot: String) -> Dictionary:
	var boost = {}

	for stat in BOOSTABLE_STATS:
		var add_boost = 0
		if character["equipment"][slot] != "":
			var item_data = Load_item_data(character["equipment"][slot])
			add_boost = item_data["boost"].get(stat, 0)
		boost[stat] = boost.get(stat, 0) + add_boost
	return boost

#checks if the specified item is better than the currently equipped item ( based
#on the slot)
#returns 1 for better, -1 for worst, 0 for no change
func is_the_item_better(character: Dictionary, item_name: String) -> int:
	var item_data = Load_item_data(item_name)
	if character["equipment"][item_data["slot"]] == "":
		return 1 #item is better than nothing
	else:
		#get actual boost from slot
		var actual_boost = calculate_stats_boost_from_slot(character, item_data["slot"])
		#check offense boost
		return int(sign(_get_boost_total(item_data["boost"]) - _get_boost_total(actual_boost)))

func get_passive_skills_from_inv(char_name: String) -> Array:
	var ret = []
	var char_inv = Inventories[char_name]
	for item in char_inv:
		if item.equiped or !is_equippable(item.ItemName):
			ret.append_array(item.get_data().get("passive_skills", []))
	return ret

func get_vulnerab_multipliers_from_inv(char_name: String) -> Dictionary:
	var ret = {}
	var char_inv = Inventories[char_name]
	for item in char_inv:
		if item.equiped or !is_equippable(item.ItemName):
			var item_multipliers = item.get_data().get("vulnerab_multipliers", {})
			for cur_mult in item_multipliers:
				ret[cur_mult] = ret.get(cur_mult, 1) * item_multipliers[cur_mult]
	return ret
