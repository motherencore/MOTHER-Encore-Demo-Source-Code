extends CanvasLayer

const InventorySelect = preload("res://Nodes/Ui/Inventory/InventorySelect.gd")
const SkillsMenu = preload("res://Scripts/UI/SkillsMenuUI.gd")

export (NodePath) onready var anim = get_node(anim) as AnimationPlayer
export (NodePath) onready var label_name = get_node(label_name) as Label
export (NodePath) onready var label_hp = get_node(label_hp) as Label
export (NodePath) onready var label_pp = get_node(label_pp) as Label
export (NodePath) onready var box_stats = get_node(box_stats) as BoxContainer
export (NodePath) onready var label_level = get_node(label_level) as Label
export (NodePath) onready var label_exp = get_node(label_exp) as Label
export (NodePath) onready var box_equip = get_node(box_equip) as BoxContainer
export (NodePath) onready var box_ailments = get_node(box_ailments) as BoxContainer
export (NodePath) onready var label_unconscious = get_node(label_unconscious) as Label
export (NodePath) onready var panel_select = get_node(panel_select) as InventorySelect
export (NodePath) onready var panel_skills = get_node(panel_skills) as SkillsMenu

signal back

const MAX_STATUS_DISPLAYED = 11

var active = false
var _character

func _ready():
	global.connect("locale_changed", self, "update")
	panel_skills.connect("exited", self, "_on_skills_exited")

func Show_stats(party_member): 
	_character = party_member["name"]
	panel_select.InitFromCharacter(_character)
	panel_skills.current_character = party_member
	anim.play("Open")
	panel_select.visible = true
	panel_select.active = true
	active = true
	
	update()

func _input(event):
	if active:
		if event.is_action_pressed("ui_cancel"):
			Input.action_release("ui_cancel")
			anim.play("Close")
			panel_select.active = false
			active = false
			emit_signal("back")
		elif event.is_action_pressed("ui_accept"):
			active = false
			audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_open.wav"), "menu_open")
			panel_skills.activate()
		
func update():
	if _character == null:
		return
	
	var charData = globaldata[_character]

	# Character name
	label_name.text = charData.nickname

	# HP, PP
	label_hp.text = "%s / %s" % [charData.hp, charData.maxhp + charData.boosts.maxhp]
	label_pp.text = "%s / %s" % [charData.pp, charData.maxpp + charData.boosts.maxpp]
	
	# Battle stats: Offense, Defense, Speed, IQ, Guts
	for node in box_stats.get_children():
		if node is Label:
			var stat = node.get_name()
			node.text = str(int(charData[stat] + charData.boosts[stat]))

	# Level, EXP
	var expNeeded = globaldata.get_exp_for_level(charData.level + 1)
	label_level.text = str(int(charData.level))
	label_exp.text = str(int(charData.exp)) + "/" + str(expNeeded)
	
	# Equip
	for node in box_equip.get_children():
		if node is Label:
			var item = node.get_name()
			if charData["equipment"][item] != "":
				#globaldata.fit_item_name_to_label(node, InventoryManager.Load_item_data(charData["equipment"][item]))
				node.text = InventoryManager.Load_item_data(charData["equipment"][item]).name
			else:
				node.text = "EQUIP_NONE"

	# Status ailments
	var ailments_to_show = charData.status
	while MAX_STATUS_DISPLAYED > 0 and ailments_to_show.size() > MAX_STATUS_DISPLAYED:
		ailments_to_show = ailments_to_show.slice(1, -1)
	for node in box_ailments.get_children():
		var status_name = node.get_name().to_lower()
		node.visible = StatusManager.has_status(charData, status_name) and !StatusManager.get_ailment_info(status_name).get("hidden", false)
	var text_unconscious = TextTools.format_text_with_context("AILMENT_UNCONSCIOUS", charData)
	label_unconscious.text = text_unconscious[0].to_upper() + text_unconscious.substr(1)
	label_unconscious.visible = StatusManager.is_unconscious(charData)

func _on_InventorySelect_character_changed(character):
	_character = character
	update()

func _on_skills_exited():
	active = true
