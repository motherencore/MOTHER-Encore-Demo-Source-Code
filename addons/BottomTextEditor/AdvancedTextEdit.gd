tool
extends TextEdit

var regex = RegEx.new()

var txtfind:LineEdit
var txtreplace:LineEdit

func _ready():
	txtfind = get_parent().get_node("FindReplaceBar/TxtRegex")
	txtreplace = get_parent().get_node("FindReplaceBar/TxtReplace")

func update_regex(pattern):
	regex.compile(pattern)

func _on_BtnReplace_pressed():
	update_regex(txtfind.text)
	var _match = regex.search(text)
	text = regex.sub(text, txtreplace.text, false, _match.get_start())

func _on_BtnReplaceAll_pressed():
	update_regex(txtfind.text)
	text = regex.sub(text, txtreplace.text, true)

var _regex_offset = 0
func _on_BtnFindNext_pressed():
	update_regex(txtfind.text)
	var next_match = regex.search()
