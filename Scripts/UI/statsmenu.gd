extends CanvasLayer

signal back
var active = false

func Show_stats():
	$AnimationPlayer.play("Open")
	$PartySelect.visible = true
	$PartySelect.active = true
	active = true
	set_stats(global.party[0]["name"])

func _input(event):
	if active and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle")):
		Input.action_release("ui_cancel")
		Input.action_release("ui_toggle")
		$AnimationPlayer.play("Close")
		$PartySelect.active = false
		active = false
		emit_signal("back")
		

func set_stats(chara):
	var nextLvl = globaldata[chara].level + 1
	var expNeeded = int(nextLvl * nextLvl * (nextLvl + 1) * .75)
	$Stats/Name.text = globaldata[chara].nickname
	$Stats/stats/HP.text = str(int(globaldata[chara].hp)) + " / " + str(globaldata[chara].maxhp + globaldata[chara]["boosts"].maxhp)
	$Stats/stats/PP.text = str(int(globaldata[chara].pp)) + " / " + str(globaldata[chara].maxpp + globaldata[chara]["boosts"].maxpp)
	$Stats/stats/offense.text = str(int(globaldata[chara].offense + globaldata[chara].boosts.offense))
	$Stats/stats/defense.text = str(int(globaldata[chara].defense + globaldata[chara].boosts.defense))
	$Stats/stats/speed.text = str(int(globaldata[chara].speed + globaldata[chara].boosts.speed))
	$Stats/stats/IQ.text = str(int(globaldata[chara].iq + globaldata[chara].boosts.iq))
	$Stats/stats/guts.text = str(int(globaldata[chara].guts + globaldata[chara].boosts.guts))
	$Stats/stats2/level.text = str(int(globaldata[chara].level))
	$Stats/stats2/points.text = str(int(globaldata[chara].exp)) + "/" + str(expNeeded)
	$Stats/stats2/weapon.text = ""
	$Stats/stats2/body.text = ""
	$Stats/stats2/head.text = ""
	$Stats/stats2/other.text = ""
	if globaldata[chara]["equipment"]["weapon"] != "":
		$Stats/stats2/weapon.text = InventoryManager.Load_item_data(globaldata[chara]["equipment"]["weapon"])["name"][globaldata.language]
	if globaldata[chara]["equipment"]["body"] != "":
		$Stats/stats2/body.text = InventoryManager.Load_item_data(globaldata[chara]["equipment"]["body"])["name"][globaldata.language]
	if globaldata[chara]["equipment"]["head"] != "":
		$Stats/stats2/head.text = InventoryManager.Load_item_data(globaldata[chara]["equipment"]["head"])["name"][globaldata.language]
	if globaldata[chara]["equipment"]["other"] != "":
		$Stats/stats2/other.text = InventoryManager.Load_item_data(globaldata[chara]["equipment"]["other"])["name"][globaldata.language]
	$Stats/Name/statuses.text = ""
	
	var overflowing = false
	for s in globaldata[chara].status.size():
		for st in globaldata.ailments.size():
			if st == globaldata[chara].status[s]:
				var num = 0
				for sta in globaldata.ailments:
					if num == st:
						if s > 0:
							#if s == globaldata[chara].status.size() - 1:
							#else:
							$Stats/Name/statuses.text += " and "
						$Stats/Name/statuses.text += "more"
						$Stats/Name/statuses.text += str(sta)
						if $Stats/Name/statuses.get_line_count() > 1:
							$Stats/Name/statuses.text = $Stats/Name/statuses.text.replace((str(sta)), "")
							overflowing = true
						else:
							$Stats/Name/statuses.text = $Stats/Name/statuses.text.replace("more", "")
							if s != globaldata[chara].status.size() - 1:
								$Stats/Name/statuses.text = $Stats/Name/statuses.text.replace(" and ", ", ")
						break
					num += 1
			if overflowing:
				break
		if overflowing:
			break
		
	
	for i in $Stats/stats2.get_children():
		if i.get("text") != null:
			if i.text == "":
				i.text = "None"

func _on_InventorySelect_character_changed(character):
	set_stats(character)
