extends TextureRect


func show_is_item_suitable(val):
	$Indicators/is_item_suitable.visible = val
	
func show_is_item_equiped(val):
	$Indicators/is_item_equiped.visible = val
	
func show_is_item_better(val):
	$Indicators/is_item_suitable/is_item_better.visible = val
	
func show_is_item_lower(val):
	$Indicators/is_item_suitable/is_item_lower.visible = val
