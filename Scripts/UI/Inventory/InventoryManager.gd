extends Node

#Todo maybe:
#Do everything (search, organize) with UID items

const _MAX_INVENTORY_SIZE = 16
const _MAX_STORAGE_SIZE = 64
const _MAX_STORAGE_SIZE_GOD = 99

const ID_KEY = "key"
const ID_STORAGE = "storage"
const ID_STORAGE_GOD = "god_storage"

const items_data_path = "res://Data/Items/"

#existing IUDs to prevent having several items with same IUD
var used_uids_tab = []

#Class definition for Item object
class Item:
	var ItemName = ""
	var uid = 0
	var equiped = false
	
	func _init(item_name, is_equiped, new_uid = Item.get_uid(InventoryManager.used_uids_tab)):
		ItemName = item_name
		equiped = is_equiped
		uid = new_uid
		
	static func get_uid(used_uids) -> int:
		var Uid = -1
		randomize()
		while(1):
			Uid = randi()
			if !(Uid in used_uids):
				break
		
		return Uid
		
	static func add_uid(new_uid, used_uids):
		if !(new_uid in used_uids):
			used_uids.append(new_uid)

#list of character with no inventory during the game
var no_inventory_characters = [
	"canarychick",
	"flyingman",
	"eve"
	]


#holds inventory for each characters + key objects
var Inventories = {
	"ninten": [
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Slingshot", false, Item.get_uid(used_uids_tab)),
		Item.new("BatWooden", false, Item.get_uid(used_uids_tab)),
		Item.new("CourageBadge", false, Item.get_uid(used_uids_tab)),
		Item.new("Antidote", false, Item.get_uid(used_uids_tab)),
		Item.new("EyeDrops", false, Item.get_uid(used_uids_tab)),
		Item.new("AsthmaSpray", false, Item.get_uid(used_uids_tab))
		],
	"lloyd": [
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		],
	"ana": [
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		],
	"teddy": [
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),
		Item.new("Bread", false, Item.get_uid(used_uids_tab)),

	],
	"pippi": [],
	"canarychick": [],
	"flyingman": [],
	"eve": [],
	"key": [
		Item.new("CashCard", false, Item.get_uid(used_uids_tab)),
	],
	"storage": [],
	"god_storage": []
}

func _init():
	_init_god_storage()

func _init_inventories():
	for inventory in Inventories.keys():
		Inventories[inventory].clear()
	_init_god_storage()

func _init_god_storage():
	for item_id in globaldata.items:
		var inv_item = Item.new(item_id, false, Item.get_uid(used_uids_tab))
		Inventories[ID_STORAGE_GOD].append(inv_item)
	sortAuto(ID_STORAGE_GOD)

#load inventories from savegame data
func load_inventories(serialized_inv):
	_init_inventories()
	for inventory in serialized_inv.keys():
		var inv_content = []
		for serialized_item in serialized_inv[inventory]:
			inv_content.append(Item.new(serialized_item["ItemName"], serialized_item["equiped"], int(serialized_item["uid"])))
			Item.add_uid(int(serialized_item["uid"]), used_uids_tab)
			#var previouslyEquipped = serialized_item["equiped"]
		Inventories[inventory] = inv_content
	
#save inventories into savegame data	
func save_inventories():
	var serialized_inv = {}
	for inventory in Inventories.keys():
		var inv_content = []
		for item in Inventories[inventory]:
			var serialised_item = {"ItemName":item.ItemName, "equiped": item.equiped, "uid" : item.uid}
			inv_content.append(serialised_item)
		serialized_inv[inventory] = inv_content
	return serialized_inv

#function to add item (item name, target character)
func addItem(character, item):
	if character in Inventories.keys():
		Inventories[character].append(Item.new(item, false, Item.get_uid(used_uids_tab)))
	
	
#drop item ()
func dropItem(character, item_idx):
	if character in Inventories.keys():
		var inventory = Inventories[character]
		if inventory[item_idx].equiped == true:
			var chara_data = Get_global_data(character)
			var item_name = inventory[item_idx].ItemName
			removeBoost(character, item_name)
			var item_data = Load_item_data(item_name)
			if chara_data["equipment"][item_data["slot"]] != "":
				chara_data["equipment"][item_data["slot"]] = ""
			
		inventory.remove(item_idx)
		
#get inventory content? 
func getInventory(character) -> Array:
	return Inventories[character]

#get items corresponding to equip slot, minus already equiped
func getItemsForSlot(character, slot) -> Array:
	var sortedItems =[]
	var inv = Inventories[character]
	for item in inv:
		var item_data = Load_item_data(item.ItemName)
		if item_data.has("slot"):
			if item_data["slot"] == slot:
				if item.equiped == false:
					sortedItems.append(item)
	return sortedItems
	
#search item from uid
func getItemFromUID(character, uid):
	var inv = Inventories[character]
	for item in inv:
		if item.uid == uid:
			return item
	return -1

#check if any character in your party has a specific item
func checkItemForAll(itemName):
	var characters = []
	var hasItem = false
	for i in global.party:
		characters.append(i.name)
	characters.append("key")
	for character in Inventories:
		var hasPartyMember = false
		for i in characters:
			if i == character or character == "key":
				hasPartyMember = true
		var inv = Inventories[character]
		if hasPartyMember:
			for item in inv:
				if item.ItemName == itemName:
					hasItem = true
	return hasItem

func checkItemInStorage(itemName):
	checkItem(ID_STORAGE, itemName)

func checkItem(character, itemName):
	for item in Inventories[character]:
		if item.ItemName == itemName:
			return true
	return false

#remove the first instance of an item 
func removeItem(itemName):
	var characters = []
	for i in global.party:
		characters.append(i.name)
	characters.append("key")
	for character in Inventories:
		var hasPartyMember = false
		for i in characters:
			if i == character or character == "key":
				hasPartyMember = true
		var inv = Inventories[character]
		var id = 0
		if hasPartyMember:
			for item in inv:
				if item.ItemName == itemName:
					dropItem(character, id)
					break
				id += 1

func removeItemFromChar(character, itemName):
	var inv = Inventories[character]
	var id = 0
	for item in inv:
		if item.ItemName == itemName:
			dropItem(character, id)
			break
		id += 1

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
func hasInventorySpace():
	var has_space = false
	for i in global.party.size():
		if !isInventoryFull(global.party[i]["name"]):
			has_space = true
	if has_space:
		return(true)
	else:
		return(false)

#give item to anyone who has space in their inventory
func giveItemAvailable(item):
	var item_given = false
	var item_data = Load_item_data(item)
	if item_data.has("keyitem"):
		if item_data["keyitem"]:
			addItem("key",item)
			item_given = true
			global.receiver = global.party[0]
	if !item_given and hasInventorySpace():
		for i in global.party.size():
			if !isInventoryFull(global.party[i]["name"]) and !item_given:
				addItem(global.party[i]["name"],item)
				global.receiver = global.party[i]
				item_given = true

func doesItemHaveFunction(item, function):
	var item_data = Load_item_data(item)
	var hasFunction = false
	if item_data["action_one"] != null:
		if item_data["action_one"]["function"] == function:
			hasFunction = true
	if item_data["action_two"] != null:
		if item_data["action_two"]["function"] == function:
			hasFunction = true
	return hasFunction

#switch item in the inventory for sorting (item1_idx, item2_idx)
func switchItems(character, item1_idx, item2_idx):
	if character in Inventories.keys():
		var item1 = Inventories[character][item1_idx]
		var item2 = Inventories[character][item2_idx]
		
		Inventories[character][item2_idx] = item1
		Inventories[character][item1_idx] = item2
		

#swap item between characters inventories
func swapBetweenCharacters(source, target, source_idx, target_idx):
	var item1 = Inventories[source][source_idx].ItemName
	var item2 = Inventories[target][target_idx].ItemName
	
	if  Inventories[source][source_idx].equiped == true:
		unequip(source, item1)
	
	Inventories[source].remove(source_idx)
	addItem(source,item2)
	
	Inventories[target].remove(target_idx)
	addItem(target,item1)

class sort_alphabetical:
	static func sort (a, b):
		if a["ItemName"] < b["ItemName"]:
			return true
		return false

class sort_hp:
	static func sort (a, b):
		if a["ItemName"] < b["ItemName"]:
			return true
		return false

#automatic sorting by name
func sortAuto(character):
	var temp_array = Inventories[character]
	var temp_array2 = []
	var temp_array3 = []
	var temp_array4 = []
	
	#sort by alphabetical order
	
	temp_array.sort_custom(sort_alphabetical, "sort")
	
	#healing HP
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if (!doesItemHaveFunction(item.ItemName, "equip")) and item_data["HPrecover"] >= 1 and item_data["boost"]["maxhp"] < 1:
			temp_array3.append(item_data["HPrecover"])
	
	#sort by HP recovery
	
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if item_data["HPrecover"] == i and item_data["boost"]["maxhp"] < 1:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#healing PP
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if (!doesItemHaveFunction(item.ItemName, "equip")) and item_data["PPrecover"] >= 1 and item_data["boost"]["maxpp"] < 1:
			temp_array3.append(item_data["PPrecover"])
	
	#sort by PP recovery
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if item_data["PPrecover"] == i and item_data["boost"]["maxpp"] < 1:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#battle items
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if (doesItemHaveFunction(item.ItemName, "equip") == false)\
		 and (item_data.has("battle_action"))\
		 and (item_data["HPrecover"] < 1)\
		 and (item_data["PPrecover"] < 1):
			temp_array2.append(item)
	
	#others
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if (doesItemHaveFunction(item.ItemName, "equip") == false)\
		 and !item_data.has("battle_action")\
		 and (item_data["HPrecover"] < 1)\
		 and (item_data["PPrecover"] < 1)\
		 and (item_data["boost"]["maxhp"] == 0)\
		 and (item_data["boost"]["maxpp"] == 0)\
		 and (item_data["boost"]["offense"] == 0)\
		 and (item_data["boost"]["defense"] == 0)\
		 and (item_data["boost"]["speed"] == 0)\
		 and (item_data["boost"]["iq"] == 0)\
		 and (item_data["boost"]["guts"] == 0):
			temp_array2.append(item)
	
	#capsules
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["maxhp"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["maxpp"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["offense"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["defense"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["speed"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["iq"] >= 1:
			temp_array2.append(item)
	
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if !doesItemHaveFunction(item.ItemName, "equip") and item_data["boost"]["guts"] >= 1:
			temp_array2.append(item)
	
	#weapon equipment
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if item_data["slot"] == slots[0] and doesItemHaveFunction(item.ItemName, "equip") == true and !item.equiped:
			temp_array3.append(equipBoostTotal(item_data["boost"]))
	
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if equipBoostTotal(item_data["boost"]) == i and item_data["slot"] == slots[0]:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#body equipment
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if item_data["slot"] == slots[1] and doesItemHaveFunction(item.ItemName, "equip") == true and !item.equiped:
			temp_array3.append(equipBoostTotal(item_data["boost"]))
	
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if equipBoostTotal(item_data["boost"]) == i and item_data["slot"] == slots[1] and !item.equiped:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#head equipment
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if item_data["slot"] == slots[2] and doesItemHaveFunction(item.ItemName, "equip") == true and !item.equiped:
			temp_array3.append(equipBoostTotal(item_data["boost"]))
	
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if equipBoostTotal(item_data["boost"]) == i and item_data["slot"] == slots[2] and !item.equiped:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#other equipment
	for item in temp_array:
		var item_data = Load_item_data(item.ItemName)
		if item_data["slot"] == slots[3] and doesItemHaveFunction(item.ItemName, "equip") == true and !item.equiped:
			temp_array3.append(equipBoostTotal(item_data["boost"]))
	
	temp_array3.sort()
	temp_array3.invert()
	
	for i in temp_array3:
		for item in temp_array:
			var item_data = Load_item_data(item.ItemName)
			if equipBoostTotal(item_data["boost"]) == i and item_data["slot"] == slots[3] and !item.equiped:
				temp_array2.append(item)
				temp_array.erase(item)
				break
	
	temp_array3.clear()
	
	#equiped items
	for item in temp_array:
		if item.equiped:
			temp_array2.append(item)
	
	Inventories[character] = temp_array2

func equipBoostTotal(item_boost):
	var total = 0
	total = int(item_boost["maxhp"] * 2\
			 + item_boost["maxpp"] * 2\
			 + item_boost["offense"] * 3\
			 + item_boost["defense"] * 2\
			 + item_boost["iq"]\
			 + item_boost["speed"]\
			 + item_boost["guts"])
	return total

#move item between inventory (charactertarget, charactersource)
func giveItem(sourceCharacter, targetCharacter, Sourceitem_idx):
	if (sourceCharacter in Inventories.keys()) and \
		(targetCharacter in Inventories.keys()) and \
		(sourceCharacter != targetCharacter):
		var item = Inventories[sourceCharacter][Sourceitem_idx]
		if item.equiped == true:
			unequip(sourceCharacter, item.ItemName)
		if targetCharacter != ID_STORAGE_GOD:
			addItem(targetCharacter,item.ItemName)
		if sourceCharacter != ID_STORAGE_GOD:
			Inventories[sourceCharacter].remove(Sourceitem_idx)
		

#use item in inventory
func consumeItem(character, item_idx, receiver = ""):
	if receiver == "":
		receiver = character
	var chara_data = Get_global_data(receiver)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Load_item_data(item_name)
	
	applyBoost(receiver, item_name)
	
	chara_data["hp"] += int(item_data["HPrecover"])
	if chara_data["hp"] > chara_data["maxhp"] + chara_data.boosts["maxhp"]:
		chara_data["hp"] = (chara_data["maxhp"] + chara_data.boosts["maxhp"]) # + trigger UI animation?
	
	chara_data["pp"] += int(item_data["PPrecover"])
	if chara_data["pp"] > chara_data["maxpp"] + chara_data.boosts["maxpp"]:
		chara_data["pp"] = chara_data["maxpp"] + chara_data.boosts["maxpp"] # + trigger UI animation?
	
	#heal statuses
	if item_data.has("status_heals"):
		for status in item_data["status_heals"]:
			if characterHasStatus(receiver, globaldata.status_name_to_enum(status)):
				chara_data["status"].erase(globaldata.status_name_to_enum(status))
				if chara_data.has("statusCountup") and chara_data.statusCountup.has(status):
					chara_data.statusCountup[status] = 0
	#do a lot of thing depending of the item, then
	dropItem(character, item_idx)




func characterHasStatus(character, status):
	var chara_data = Get_global_data(character)
	if chara_data["status"].has(status):
		return true
	else:
		return false

#use item in inventory
func useItem(character, item_idx):
	var chara_data = Get_global_data(character)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Load_item_data(item_name)
	
	if item_data["transform"] != "":
	 addItem(character, item_data["transform"])
	
	#do a lot of thing depending of the item, then
	dropItem(character, item_idx)

#transform an item into another in inventory
func transformItem(character, item_idx):
	var chara_data = Get_global_data(character)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Load_item_data(item_name)
	
	if item_data["transform"] != "":
	 addItem(character, item_data["transform"])
	
	#do a lot of thing depending of the item, then
	dropItem(character, item_idx)

#equip when equipable (current caracter) maybe another system?
func equipItem(character, item_idx):
	var chara_data = Get_global_data(character)
	var item_name = Inventories[character][item_idx].ItemName
	var item_data = Load_item_data(item_name)
	if doesItemHaveFunction(item_name, "equip") == true:
		if chara_data["equipment"][item_data["slot"]] != "":
			#un-equip item if needed
			unequip(character, chara_data["equipment"][item_data["slot"]])
		chara_data["equipment"][item_data["slot"]] = item_name
		Inventories[character][item_idx].equiped = true
		applyBoost(character, item_name)
		if "passive_skills" in item_data:
			add_passives(chara_data, item_data.passive_skills)
		return true
	else:
		return false
		
#equip item from Equip Menu using UID
func equipItemFromUID(character, uid):
	var item = getItemFromUID(character["name"], uid)
	var item_name = item.ItemName
	var item_data = Load_item_data(item_name)
	if doesItemHaveFunction(item_name, "equip") == true:
		if character["equipment"][item_data["slot"]] != "":
			#un-equip item if needed
			unequip(character["name"], character["equipment"][item_data["slot"]])
		character["equipment"][item_data["slot"]] = item_name
		item.equiped = true
		applyBoost(character["name"], item_name)
		var chara_data = character
		if "passive_skills" in item_data:
			add_passives(chara_data, item_data.passive_skills)
		return true
	else:
		return false
		
#unequip item from character name and item name
func unequip(character, item_name):
	var chara_data = Get_global_data(character)
	var item_data = Load_item_data(item_name)
	chara_data["equipment"][item_data["slot"]] = ""
	if "passive_skills" in item_data:
		remove_passives(chara_data, item_data.passive_skills)
	removeBoost(character, item_name)
	for item in Inventories[character]:
		if item.ItemName == item_name:
			item.equiped = false
		
#unequip item in a slot
func unequip_slot(character, slot):
	var chara_data = character
	var item_name = chara_data["equipment"][slot]
	if chara_data["equipment"][slot] != "":
		chara_data["equipment"][slot] = ""
		var item_data = Load_item_data(item_name)
		if "passive_skills" in item_data:
			remove_passives(chara_data, item_data.passive_skills)
		removeBoost(character["name"], item_name)
	for item in Inventories[character["name"]]:
		if item.ItemName == item_name:
			item.equiped = false

#apply boost when equipping item
func applyBoost(character, item_name):
	var chara_data = Get_global_data(character)
	var item_data = Load_item_data(item_name)
	var boosts = item_data["boost"]
	for boost in boosts.keys():
		if chara_data.boosts.keys().find(boost) != -1:
			chara_data.boosts[boost] += boosts[boost]
	
#remove stats boost when unequipping item	
func removeBoost(character, item_name):
	var chara_data = Get_global_data(character)
	var item_data = Load_item_data(item_name)
	var boosts = item_data["boost"]
	for boost in boosts.keys():
		if chara_data.boosts.keys().find(boost) != -1:
			chara_data.boosts[boost] -= boosts[boost]

# search for item in a character's inventory. Return first idx or -1 if not found
func findItemIdx(character, item_name):
	var inv = getInventory(character)
	for i in inv.size():
		if inv[i].ItemName == item_name:
			return i
	return -1

#retrieve dat from the json file of an item
func Load_item_data(item_name):
	if globaldata.items.has(item_name):
		return globaldata.items[item_name]
	else:
		return {}

#get character global data from party
func Get_global_data(character_name):
	var ret = null
	for chara in global.party:
		if chara["name"].to_lower() == character_name:
			return chara
	return ret

#resets everything in the inventory to what it should be at the start of the game
func resetInventories():
	for i in Inventories:
		Inventories[i].clear()
	addItem("key", "CashCard")

############################################################	
#should probably be elswhere, in a character manager, or stats manager?

#different slots name accessible from index
const slots = [
	"weapon",
	"body",
	"head",
	"other"
]
	
#since equipping item change stats for now, calculate back the boost from item to
#ease comparison
func calculate_stats_boost_from_slot(character, slot):
	var boost = {
	"maxhp" : 0, 
	"maxpp" : 0, 
	"speed" : 0, 
	"offense" : 0, 
	"defense" : 0, 
	"iq" : 0, 
	"guts" : 0
	}

	for stat in boost.keys():
		if character["equipment"][slot] != "":
			var item_data = Load_item_data(character["equipment"][slot])
			if item_data["boost"].has(stat):
				boost[stat] += item_data["boost"][stat]
	return boost

#checks if the specified item is better than the currently equipped item ( based
#on the slot)
#returns 1 for better, -1 for worst, 0 for no change
func is_the_item_better(character, item_name):
	var item_data = Load_item_data(item_name)
	if character["equipment"][item_data["slot"]] == "":
		return 1 #item is better than nothing
	else:
		#get actual boost from slot
		var actual_boost = calculate_stats_boost_from_slot(character, item_data["slot"])
		#check offense boost
		if equipBoostTotal(actual_boost) < equipBoostTotal(item_data["boost"]):
			return 1
		elif equipBoostTotal(actual_boost) == equipBoostTotal(item_data["boost"]):
			return 0
		else:
			return -1

func add_passives(character, passives):
	for passiveSkill in passives:
		if !passiveSkill in character.passiveSkills:
			character.passiveSkills.append(passiveSkill)

func remove_passives(character, passives):
	for passive in passives:
		character.passiveSkills.erase(passive)
