extends TextureRect

const character_portrait_path = "res://Graphics/UI/Inventory/characters/"

const stats_list = [
	"maxhp",		
	"maxpp",		
	"speed",	
	"offense",
	"defense",
	"iq", 
	"guts"
]

onready var stats = {
	"maxhp": 		$StatsLabels/MarginContainer/HBoxContainer/HPStats,
	"maxpp":		$StatsLabels/MarginContainer/HBoxContainer/PPStats,
	"speed":	$StatsLabels/MarginContainer/HBoxContainer/SPDStats,
	"offense":	$StatsLabels/MarginContainer/HBoxContainer/OFEStats,
	"defense":	$StatsLabels/MarginContainer/HBoxContainer/DEFStats,
	"iq": 		$StatsLabels/MarginContainer/HBoxContainer/IQStats,
	"guts":		$StatsLabels/MarginContainer/HBoxContainer/GUTStats
}


func _ready():
	hide()

func show_statsBar(character_name, modifiersDic):
	$CenterContainer/CharacterPortrait.texture = load(character_portrait_path+character_name+".png")
	var character_stats = InventoryManager.Get_global_data(character_name)
	
	for stat in stats_list:
		stats[stat].set_stat_value(character_stats[stat] + character_stats["boosts"][stat])
		stats[stat].hide_modifier_value()
		stats[stat].set_modifier_icon("")
	
	if modifiersDic != {}:
		for modifier in modifiersDic.keys():
			stats[modifier].set_modifier_value(modifiersDic[modifier])
			if int(modifiersDic[modifier]) > int(character_stats[modifier] + character_stats["boosts"][modifier]):
				stats[modifier].set_modifier_icon("up")
			elif int(modifiersDic[modifier]) < int(character_stats[modifier] + character_stats["boosts"][modifier]):
				stats[modifier].set_modifier_icon("down")
			else:
				stats[modifier].set_modifier_icon("")
	if !visible:
		$AnimationPlayer.play("Open")

func hide_statsBar():
	if visible:
		$AnimationPlayer.play("Close")
