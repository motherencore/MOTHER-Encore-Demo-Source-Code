extends NinePatchRect


func _ready():
	$Present/ButtonPrompt.show_button(true)
	$NPC/ButtonPrompt.show_button(true)

func quick_set():
	match $ButtonPromptsArrow.cursor_index:
		0:
			$Present/ButtonPrompt.show_button(true, true)
			$NPC/ButtonPrompt.show_button(true, true)
		1:
			$Present/ButtonPrompt.show_button(true, true)
			$NPC/ButtonPrompt.hide_button(true)
		2:
			$Present/ButtonPrompt.hide_button(true)
			$NPC/ButtonPrompt.show_button(true, true)
		3:
			$Present/ButtonPrompt.hide_button(true)
			$NPC/ButtonPrompt.hide_button(true)

func _on_ButtonPromptsArrow_moved(dir):
	match $ButtonPromptsArrow.cursor_index:
		0:
			$Present/ButtonPrompt.show_button(true)
			$NPC/ButtonPrompt.show_button(true)
		1:
			$Present/ButtonPrompt.show_button(true)
			$NPC/ButtonPrompt.hide_button()
		2:
			$Present/ButtonPrompt.hide_button()
			$NPC/ButtonPrompt.show_button(true)
		3:
			$Present/ButtonPrompt.hide_button()
			$NPC/ButtonPrompt.hide_button()
