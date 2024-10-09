extends YSort

var party_members = []
var party_npcs = []
var replacing = false

func replace_party_members():
	replacing = true
	global.cutscene = true
	party_members = []
	party_npcs = []
	for partyMem in global.party:
		if partyMem != globaldata.ninten:
			global.party.erase(partyMem)
			party_members.append(partyMem)
	for partyNPC in global.partyNpcs:
		global.partyNpcs.erase(partyNPC)
		party_npcs.append(partyNPC)
	global.cutscene = false
	global.call_deferred("create_party_followers")

func _on_Area2D_body_entered(body):
	if body == global.persistPlayer and !replacing:
		replace_party_members()

func _on_Area2D_body_exited(body):
	if body == global.persistPlayer and replacing:
		for i in party_members:
			global.party.append(i)
		for i in party_npcs:
			global.partyNpcs.append(i)
		global.call_deferred("create_party_followers")
		replacing = false
