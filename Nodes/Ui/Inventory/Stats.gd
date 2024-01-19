extends Control


func set_stat_value(val):
	$StatLabel.text = str(val)

func set_modifier_value(val):
	$Modifier/ModiferLabel.text = str(val)

func hide_modifier_value():
	$Modifier/ModiferLabel.text = ""
	
func set_modifier_icon(text):
	if text == "up":
		$Modifier/ModifierIconUp.visible = true
		$Modifier/ModifierIconDown.visible = false
	elif text == "down":
		$Modifier/ModifierIconUp.visible = false
		$Modifier/ModifierIconDown.visible = true
	elif text == "":
		$Modifier/ModifierIconUp.visible = false
		$Modifier/ModifierIconDown.visible = false
