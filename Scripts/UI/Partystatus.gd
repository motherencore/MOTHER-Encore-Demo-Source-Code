extends Control

onready var partyname = $Name
onready var status = $stats
onready var hp = $HP
onready var pp = $PP

var active 


func _ready():
	pass # Replace with function body.



func _process(delta):
	active = global.party
	#update_stats()
	if status.text == "Normal":
		status.hide()
	else:
		status.show()
	
	if hp.text == "0":
		$ColorRect.color = "eb2131"
		for i in range(active.size()):
			if active[i]["hp"] == 0:
				active[i]["status"] = globaldata.ailments.Unconcious
	else:
		$ColorRect.color = "381c23"

func update_stats():
	#for i in range(active.size()):
		#status.text = globaldata.ailments.keys()[active[i]["status"]]
		#hp.text = var2str(active[i]["hp"])
		pass#pp.text = var2str(active[i]["pp"])
