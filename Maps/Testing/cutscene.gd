extends "res://Scripts/Main/UI/Functions.gd"


var timer = 0
var cutscene = null
export var cutsceneFile = ""
var phaseNum = 0
var currPhase = null
var currPhaseNum = 0


func _process(delta):
	if cutscene != null:
		global.cutscene = true
		if uiManager.uiStack.size() == 0:
			timer = timer + 1
			if timer == str2var(currPhaseNum):
				print(timer)
				commands()
				phaseNum = phaseNum + 1
				
			if (phaseNum + 1) <= cutscene.size():
				currPhaseNum = cutscene.keys()[phaseNum]
				currPhase = cutscene[currPhaseNum]
			else:
				cutscene = null
				uiManager.toggle_black_bars(false)
				global.persistPlayer.unpause()
				global.cutscene = false
				
				
		



func getDialog():
	var path = "res://Data/Cutscenes/" + cutsceneFile + ".json"
	var f = File.new()

	if f.file_exists(path):
		pass
	else:
		return {}

	f.open(path, File.READ)
	var json = f.get_as_text()
	
	var output = parse_json(json)
	if typeof(output) == TYPE_DICTIONARY:
		return output
	else:
		return null

func _on_CStrigger_body_entered(body):
	if $CollisionShape2D.disabled == false:
		$CollisionShape2D.disabled = true
		cutscene = getDialog()
		if cutscene != null:
			uiManager.toggle_black_bars(true)
			global.persistPlayer.pause()
			currPhaseNum = cutscene.keys()[phaseNum]
			currPhase = cutscene[currPhaseNum]

func commands():
	if currPhase.has("dialogue"):
		global.set_dialog(currPhase["dialogue"], null)
		uiManager.open_dialogue_box()
	
	if currPhase.has("commands"):
		for command in currPhase["commands"]:
			var expression = Expression.new()
			expression.parse(command)
			var result = expression.execute([], self)
	
	
