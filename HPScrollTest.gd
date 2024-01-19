extends Control

onready var hpPlate = $PartyInfoPlate

func _ready():
	hpPlate.maxHP = 100
	hpPlate.setHP(100, true)
	hpPlate.maxPP = 100
	hpPlate.setPP(100, true)

func _input(event):
	if event.is_action_pressed("ui_right"):
		$PartyInfoPlate.setHP(hpPlate.HP + 1)
	if event.is_action_pressed("ui_left"):
		$PartyInfoPlate.setHP(hpPlate.HP - 1)
	if event.is_action_pressed("ui_up"):
		$PartyInfoPlate.setPP(hpPlate.PP + 1)
	if event.is_action_pressed("ui_down"):
		$PartyInfoPlate.setPP(hpPlate.PP - 1)
