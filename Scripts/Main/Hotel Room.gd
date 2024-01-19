extends YSort

var party_members = []
var party_npcs = []


func _on_Area2D_body_entered(body):
	if body == global.persistPlayer:
		global.cutscene = true
		global.persistPlayer.pause()
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
		global.persistPlayer.unpause()
		print("dafuq")
		

func _on_Area2D_body_exited(body):
	if body == global.persistPlayer:
		for i in party_members:
			global.party.append(i)
		for i in party_npcs:
			global.partyNpcs.append(i)
		global.call_deferred("create_party_followers")
