extends NinePatchRect


func _ready():
	$Present/ButtonPrompt.show_button(true)
	$NPC/ButtonPrompt.show_button(true)

func refresh(quick = false):
	match $ButtonPromptsArrow.cursor_index:
		0:
			$Present/ButtonPrompt.show_button(true, quick)
			$NPC/ButtonPrompt.show_button(true, quick)
		1:
			$Present/ButtonPrompt.show_button(true, quick)
			$NPC/ButtonPrompt.hide_button(quick)
		2:
			$Present/ButtonPrompt.hide_button(quick)
			$NPC/ButtonPrompt.show_button(true, quick)
		3:
			$Present/ButtonPrompt.hide_button(quick)
			$NPC/ButtonPrompt.hide_button(quick)

func _on_ButtonPromptsArrow_moved(dir):
	refresh()
