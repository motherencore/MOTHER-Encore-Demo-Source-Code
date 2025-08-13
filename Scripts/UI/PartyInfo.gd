extends CanvasLayer

onready var _hbox = $Control/HBox
onready var _anim_player = $AnimationPlayer

var _showing = false

func _ready():
	update_party_infos()
	global.connect("party_changed", self, "update_party_infos")

func update_party_infos(set=true):
	for i in _hbox.get_child_count():
		var plate = _hbox.get_child(i)
		if i >= global.POSSIBLE_PLAYABLE_MEMBERS.size():
			plate.hide()
			continue
		var chara = globaldata.get(global.POSSIBLE_PLAYABLE_MEMBERS[i])
		plate.visible = chara in global.party
		plate.pName = TextTools.replace_text(chara.nickname)
		plate.maxHP = chara.maxhp + chara.boosts.maxhp
		plate.maxPP = chara.maxpp + chara.boosts.maxpp
		plate.setHP(chara.hp, set)
		plate.setPP(chara.pp, set)
		plate.show_max_num()

func deselect_all():
	for plate in _hbox.get_children():
		plate.deselect()

func select_one(character_name: String):
	var char_idx = global.POSSIBLE_PLAYABLE_MEMBERS.find(character_name)
	for i in _hbox.get_child_count():
		if i == char_idx:
			_hbox.get_child(i).select()
		else:
			_hbox.get_child(i).deselect()

func select_if(condition: FuncRef):
	for i in _hbox.get_child_count():
		var chara = globaldata.get(global.POSSIBLE_PLAYABLE_MEMBERS[i])
		if condition.call_func(chara):
			_hbox.get_child(i).select()
		else:
			_hbox.get_child(i).deselect()

func open():
	if !_showing:
		_showing = true
		_anim_player.play("Open")

func close():
	if _showing:
		_showing = false
		_anim_player.play("Close")
