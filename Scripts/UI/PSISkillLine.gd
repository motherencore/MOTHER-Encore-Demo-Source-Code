extends Control

onready var box = $HBox
var skillName = null

func init(skill):
	name = skill.name
	$Name.text = skill.name
	$Name.modulate = Color.darkgray
	
	#reset levels
	$HBox/Alpha.text = ""
	$HBox/Alpha.modulate = Color.darkgray
	$HBox/Beta.text = ""
	$HBox/Beta.modulate = Color.darkgray
	$HBox/Gamma.text = ""
	$HBox/Gamma.modulate = Color.darkgray
	$HBox/Omega.text = ""
	$HBox/Omega.modulate = Color.darkgray
	if !"level" in skill:
		addLevel(0)
	else:
		addLevel(skill.level, false)

func addLevel(level: int, selectable: bool = true):
	match(level):
		0: #alpha
			$HBox/Alpha.text = "¢"
			if selectable:
				$HBox/Alpha.modulate = Color.white
				$Name.modulate = Color.white
		1: #beta
			$HBox/Beta.text = "\\"
			if selectable:
				$HBox/Beta.modulate = Color.white
				$Name.modulate = Color.white
		2: #gamma (but its actually delta lol)
			$HBox/Gamma.text = "£"
			if selectable:
				$HBox/Gamma.modulate = Color.white
		3: #omega
			$HBox/Omega.text = "€‎"
			if selectable:
				$HBox/Omega.modulate = Color.white
				$Name.modulate = Color.white
		
	force_update_transform()

func addLevels(levels: Array):
	for level in levels:
		addLevel(level)
