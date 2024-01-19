extends TextureRect

signal character_changed (character)

var active = false
var inhibit_chara_change = false
var swapmode = false

export var psiOnly = false
export var noKey = false
export var menuName = ""

onready var portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten.png"),
	preload("res://Graphics/UI/Inventory/characters/ana.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman.png"),
	preload("res://Graphics/UI/Inventory/characters/eve.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick.png"),
	preload("res://Graphics/UI/Inventory/characters/key.png")
]

onready var hl_portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/ana_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/eve_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick_hl.png"),
	preload("res://Graphics/UI/Inventory/characters/key_hl.png")
]

onready var gr_portraits_texture = [
	preload("res://Graphics/UI/Inventory/characters/ninten_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/ana_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/lloyd_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/teddy_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/flyingman_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/eve_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/canarychick_gr.png"),
	preload("res://Graphics/UI/Inventory/characters/pippi_gr.png")
]

onready var portrait_nodes = [
	$CharacterPortraits/Ninten,
	$CharacterPortraits/Ana,
	$CharacterPortraits/Lloyd,
	$CharacterPortraits/Teddy,
	$CharacterPortraits/Pippi,
	$CharacterPortraits/FlyingMan,
	$CharacterPortraits/Eve,
	$CharacterPortraits/CanaryChick,
	$CharacterPortraits/Key
]

var presence = {
	"ninten": false,
	"ana": false,
	"lloyd": false,
	"teddy": false,
	"pippi": false,
	"flyingman": false,
	"eve": false,
	"canarychick": false,
	"key": true
}
func _reset_presence():
	presence = {
	"ninten": false,
	"ana": false,
	"lloyd": false,
	"teddy": false,
	"pippi": false,
	"flyingman": false,
	"eve": false,
	"canarychick": false,
	"key": true
	}
	if noKey:
		presence["key"] = false


var inv_indexes = {
		"ninten": 0,
		"ana": 1,
		"lloyd": 2,
		"teddy": 3,
		"pippi": 4,
		"flyingman": 5,
		"eve": 6,
		"canarychick": 7,
		"key": 8
}

var show_inv = {}

func _get_inv_name(idx):
	var names = presence.keys()
	return names[idx]

const INV_OFFSET = 1
const MAX_INV = 7

var inv_nb = 2
var current_inv_idx = 0
var current_inventory = 0
var current_inventoryName = ""
var party = []


# Called when the node enters the scene tree for the first time.
func _ready():
	if noKey:
		portrait_nodes.pop_back()
		presence["key"] = false
	$CenterContainer/MenuName.text = menuName
		
	visible = false
	_update_portraits()
	
func _get_global_data():
	party = global.party
	inv_nb = party.size()-1
	
func setSwapmode(val, source, target):
	
	swapmode = val
	if val:
		InitFromCharacter(target)
		portrait_nodes[inv_indexes[source]].texture = gr_portraits_texture[inv_indexes[source]]
		portrait_nodes[inv_indexes[target]].texture = hl_portraits_texture[inv_indexes[target]]
		$CenterContainer/GoodsTxt.text = "Swap Items"
	else:
		InitFromCharacter(source)
		$CenterContainer/GoodsTxt.text = "Goods"
	
	
func _physics_process(_delta):
	_get_global_data()
	if !swapmode:
		if (active and !inhibit_chara_change):
			_inputs()
		_update_portraits()

	
	
func InitFromCharacter(character):
	current_inventoryName = character
	current_inventory = presence.keys().find(character)
	current_inv_idx = 0
	for i in presence:
		if presence[i] and inv_indexes[i] < current_inventory:
			current_inv_idx += 1
	active = true
	
func _update_portraits():
	show_inv = {}
	#hide portraits
	for node in portrait_nodes:
		node.visible = false
	
	_reset_presence()
	for member in party:
		if member.maxpp == 0 and psiOnly:
			continue
		var member_name = member["name"]
		presence[member_name] = true
	
	var portraitsVisible = 0
	for character in presence.keys():
		if presence[character] == true:
			portraitsVisible += 1
			portrait_nodes[presence.keys().find(character)].visible = true
			show_inv[presence.keys().find(character)] = character
		
	for index in show_inv.keys():
		if index == current_inventory:
			portrait_nodes[index].texture = hl_portraits_texture[index]
		else:
			portrait_nodes[index].texture = portraits_texture[index]
	
	
	$CharacterPortraits/IndicatorL.visible = true
	$CharacterPortraits/IndicatorR.visible = true
	if !noKey:
		$CharacterPortraits/Key.visible = true
	elif portraitsVisible <= 1:
		$CharacterPortraits/IndicatorL.visible = false
		$CharacterPortraits/IndicatorR.visible = false
	
	

func Update_portrait_modifiers(character, is_suitable, is_equiped, is_better, is_lower):
	if !is_equiped:
		portrait_nodes[presence.keys().find(character)].show_is_item_suitable(is_suitable)
		portrait_nodes[presence.keys().find(character)].show_is_item_equiped(false)
	else:
		portrait_nodes[presence.keys().find(character)].show_is_item_suitable(false)
		portrait_nodes[presence.keys().find(character)].show_is_item_equiped(is_equiped)
	portrait_nodes[presence.keys().find(character)].show_is_item_better(is_better)
	portrait_nodes[presence.keys().find(character)].show_is_item_lower(is_lower)
	

func _inputs():
	var portraitsVisible = 0
	for character in presence.keys():
		if presence[character] == true:
			portraitsVisible += 1
			portrait_nodes[presence.keys().find(character)].visible = true
			show_inv[presence.keys().find(character)] = character
	if portraitsVisible > 1 and active:
		if Input.is_action_just_pressed("ui_focus_next"):
			current_inv_idx += 1
			if current_inv_idx > show_inv.size()-1:
				current_inv_idx = 0
			if show_inv[show_inv.keys()[current_inv_idx]] in ["flyingman", "eve", "canarychick"]:
				current_inv_idx += 1
				if current_inv_idx > show_inv.size()-1:
					current_inv_idx = 0
			audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_open.wav"), "menu")
			current_inventory = show_inv.keys()[current_inv_idx]
			emit_signal("character_changed", show_inv[current_inventory])
		if Input.is_action_just_pressed("ui_focus_prev"):
			current_inv_idx -=1
			if current_inv_idx < 0:
				current_inv_idx = show_inv.size()-1
			if show_inv[show_inv.keys()[current_inv_idx]] in ["flyingman", "eve", "canarychick"]:
				current_inv_idx -= 1
				if current_inv_idx < 0:
					current_inv_idx = show_inv.size()-1
			audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_open.wav"), "menu")
			current_inventory = show_inv.keys()[current_inv_idx]
			emit_signal("character_changed", show_inv[current_inventory])

