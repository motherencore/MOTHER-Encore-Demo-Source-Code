extends NinePatchRect

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
	"maxhp": 		$StatsLabels/HPStats,
	"maxpp":		$StatsLabels/PPStats,
	"speed":	$StatsLabels/SPDStats,
	"offense":	$StatsLabels/OFEStats,
	"defense":	$StatsLabels/DEFStats,
	"iq": 		$StatsLabels/IQStats,
	"guts":		$StatsLabels/GUTStats
}


func _ready():
	hide()

func show_statsBar(character_stats, modifiersDic):
	if character_stats == null:
		return

	$CenterContainer/CharacterPortrait.texture = load(character_portrait_path+character_stats.name+".png")	
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
