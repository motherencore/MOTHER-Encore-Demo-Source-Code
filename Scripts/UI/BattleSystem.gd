extends CanvasLayer

signal action_done
signal round_done

#Other Scripts
#const Action = preload("res://Scripts/UI/Battle/Action.gd")

# HitNumber tscns
const RisingNumTscn = preload("res://Nodes/Ui/Battle/RisingNumber.tscn")
const FlyingNumTscn = preload("res://Nodes/Ui/Battle/FlyingNumber.tscn")
const SmashAttackTscn = preload("res://Nodes/Ui/Battle/Smash.tscn")

const DroppedItemNode = preload("res://Nodes/Overworld/Objects/Item.tscn")

# Party Member Sprites
var StatusBubbleTscn = preload("res://Nodes/Ui/Battle/StatusBubble.tscn")
var PartyInfoTscn = preload("res://Nodes/Ui/Battle/PartyInfoPlate.tscn")

var _party_battle_sprites = {
	"ninten": preload("res://Nodes/Ui/Battle/BattleSpriteNinten.tscn"),
	"lloyd": preload("res://Nodes/Ui/Battle/BattleSpriteLloyd.tscn"),
	"ana": preload("res://Nodes/Ui/Battle/BattleSpriteAna.tscn"),
	"pippi": preload("res://Nodes/Ui/Battle/BattleSpritePippi.tscn"),
	"teddy": preload("res://Nodes/Ui/Battle/BattleSpriteTeddy.tscn"),
	"canarychick": preload("res://Nodes/Ui/Battle/BattleSpriteNPC.tscn"),
	"flyingman": preload("res://Nodes/Ui/Battle/BattleSpriteFlyingMan.tscn"),
	"eve": preload("res://Nodes/Ui/Battle/BattleSpriteEVE.tscn")
}

var PartyBattleSpriteDefault = preload("res://Nodes/Ui/Battle/BattleSpriteDefault.tscn")

# Enemies
var EnemySprite := preload("res://Nodes/Ui/Battle/EnemySprite.tscn")

# sfx
var _sound_effects = {
	#cursors
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
	"error": load("res://Audio/Sound effects/M3/error.wav"),
	#battle sounds
	"swing": load("res://Audio/Sound effects/Ninten Bat.mp3"),
	"attack1": load("res://Audio/Sound effects/Attack 1.mp3"),
	"attack2": load("res://Audio/Sound effects/Attack 2.mp3"),
	"bash": load("res://Audio/Sound effects/bash.mp3"),
	"yourpsi": load("res://Audio/Sound effects/your_psi.mp3"),
	"enemypsi": load("res://Audio/Sound effects/M3/enemy_psi.wav"),
	"hurt1": load("res://Audio/Sound effects/Hurt 1.mp3"),
	"hurt2": load("res://Audio/Sound effects/Hurt 2.mp3"),
	"statup": load("res://Audio/Sound effects/M3/Stat_increase.wav"),
	"statdown": load("res://Audio/Sound effects/M3/Stat_decrease.wav"),
	"dodge": load("res://Audio/Sound effects/EB/dodge.wav"),
	"miss": load("res://Audio/Sound effects/EB/miss.wav"),
	"statusafflicted": load("res://Audio/Sound effects/EB/ailment.wav"),
	"enemyturn": load("res://Audio/Sound effects/Enemy Turn.mp3"),
	"enemydefeated": load("res://Audio/Sound effects/Enemy Defeat.mp3"),
	"playerdefeated": load("res://Audio/Sound effects/EB/die.wav"), #buy2
	"psilearned": load("res://Audio/Sound effects/Mortal Damage.mp3"),
	"mortaldamage": load("res://Audio/Sound effects/M3/Mortal_Blow.wav"),
	"partylose": load("res://Audio/Sound effects/PartyLose.mp3"),
	"smash": load("res://Audio/Sound effects/M3/SMAAAASH.wav"),
	"effectiveHit": load("res://Audio/Sound effects/M3/Enemy_hit_supereffective.wav"),
	#attack sounds
	"growl": load("res://Audio/Sound effects/M3/Growl.mp3"),
	"growl2": load("res://Audio/Sound effects/M3/Growl 2.mp3"),
	"siren": load("res://Audio/Sound effects/siren.mp3"),
	#item sounds
	"franklinbadge": load("res://Audio/Sound effects/M3/Franklin Badge.mp3"),
	"healHP": load("res://Audio/Sound effects/EB/heal 1.wav"),
	"healPP": load("res://Audio/Sound effects/EB/heal.wav"),
	"healstatus": load("res://Audio/Sound effects/EB/heal 2.wav"),
	# psi skill sounds
	"lifeup_a": load("res://Audio/Sound effects/EB/heal 1.wav"),
	"healing_a": load("res://Audio/Sound effects/EB/heal.wav"),
}
var _musical_effects = {
	"bossencounter": "Battle Encounter/Encounter Boss.mp3",
	"playeradv": "Battle Encounter/Encounter Player Advantage.mp3",
	"enemyadv": "Battle Encounter/Encounter Enemy Advantage.mp3",
	"encounter": "Battle Encounter/Encounter Enemy.mp3",
	"youwon": "You Win/YOUWON.mp3",
	"youwonboss": "You Win/YOUWONBOSS.mp3",
	"victory": "You Win/Victory.mp3",
	"lvlup": "You Win/LVLUP.mp3",
	"lvlup_ninten": "You Win/LVLUP_ninten.mp3",
	"lvlup_ana": "You Win/LVLUP_ninten.mp3",
	"lvlup_lloyd": "You Win/LVLUP_ninten.mp3",
	"lvlup_pippi": "You Win/LVLUP_pippi.mp3",
	"lvlup_teddy": "You Win/LVLUP_ninten.mp3"
}

const MAX_ENEMY_COUNT := 8

const FLEEING_MAX_ATTEMPTS := 3
const FLEEING_CHANCES_BASE := 40
const FLEEING_CHANCES_INCREASE := 10

const STAT_MOD_STEP := 1.0/16
const PASSIVE_HEAL_PROB = 25
const HEAL_BY_HIT_PROB = 25
const TRANSMIT_PROB = 10
const CONFUSED_BOSS_FAIL_CHANCE := 15
const SHAKE_FREQ := 0.06
const NPC_TAKING_HIT_THRESHOLD := { "flyingman": 200, "eve": 400 }
const NPC_TAKING_HIT_CHANCE := { "flyingman": 60, "eve": 90 }

const SPRITE_FRAMES = { 
	"crouch_up": Vector2(3, 3),
	"crouch_down": Vector2(3, 0),
	"crouch_left": Vector2(3, 1),
	"crouch_right": Vector2(3, 2),
	"jump_up": Vector2(3, 18),
	"jump_down": Vector2(0, 18),
	"jump_left": Vector2(1, 18),
	"jump_right": Vector2(2, 18)
}

# Classes
class Action extends Object:
	var user: BattleParticipant
	var priority := 0
	var targetType: int = TargetType.SELF
	var targetUnconscious := false
	signal done
	
	func _init(user, priority = 0):
		self.user = user
		self.priority = priority

class SkillAction extends Action:
	var skill := {} setget _set_skill
	var targets := []

	func _init(user: BattleParticipant, priority := 0).(user, priority):
		pass

	func get_dialog() -> String:
		if skill.has("dialog"):
			if skill.dialog is Array:
				return skill.dialog[randi() % skill.dialog.size()]
			else:
				return skill.dialog
		else:
			if skill.skillType == "psi":
				return "BATTLE_MSG_PSI"
			else:
				return "BATTLE_MSG_SKILL"
	
	func _set_skill(new_val):
		if new_val.has("priority"):
			priority = new_val.priority
		if new_val.has("targetType"):
			targetType = new_val.targetType
		if new_val.has("targetUnconscious"):
			targetUnconscious = new_val.targetUnconscious
		skill = new_val

class ItemAction extends SkillAction:
	var item := {} setget _set_item
	var inv_idx := -1
	func _init(user, priority = 0).(user, priority):
		pass
	
	func _set_item(new_val):
		item = new_val
		if item.get("battle_action"):
			_set_skill(globaldata.skills[item.battle_action])
		else:
			targetType = TargetType.ALLY
			if new_val.get("action_one"):
				if new_val.action_one.has("targetType"):
					targetType = new_val.action_one.targetType
				if new_val.action_one.has("targetUnconscious"):
					targetUnconscious = new_val.action_one.targetUnconscious
		if item.has("priority"):
			priority = item.priority
		

class GuardAction extends Action:
	func _init(_user).(_user):
		priority = 3

class FleeAction extends Action:
	func _init(_user).(_user):
		priority = 4

# enums
enum ActionType {DAMAGE, HEALING, NONE}
enum DamageType {NONE = -1, NORMAL, ICE, FIRE, ELECTRIC}
enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}

#The inventory that the player has at the beginning of the battle is saved
#to be given back to the player if they die and choose to continue
var _saved_inventories := {}

# Everyone in battle!
var _party_BPs := []
var _npc_BPs := []
var _enemy_BPs := []

var _special_npc_BPs := {}

var _lose_battle := false

# UI Cursor/ Menus
var _menu_page_stack := []

var _action_queue := []
var _curr_party_mem : int = -1

# for battle win stuff
var _exp_pool := 0
var _cash_pool := 0
# an array of item name and drop chances
var _items_pool := []

# for prebattle transition
var _enemies_shaking := false
var _shake_time := 0.0

var _battle_bg
var _music_intro := ""
var _music := ""

# listed in the strict order for battle (Ninten, Ana, Lloyd, Teddy, Pippi)
var _party_orig_objects := []
var _party_orig_positions := []
var _party_orig_dirs := []

# when the battle is inactive, we stop taking input
var _active := true
# for when actions are being done
var _doing_actions := false
var _current_action = null

# Dictionary (npc_name: String, yield: GDScriptFunctionState)
var _ongoing_npc_protection := {}

# know if it's a boss encounter
var _is_boss := false
var _can_run := true

var _player_adv := false
var _enemy_adv := false
var _show_intro_outro := false

var _fleeing_attempts := 0

var _buffered_player_defeat := []
var _buffer_reorganize := false
var _new_enemies := []

var _turns_count := 1

func _init():
	randomize()
	for name in global.POSSIBLE_PLAYABLE_MEMBERS:
		var party_member = globaldata.get(name)
		if party_member in global.party:
			_add_party_member(party_member)
	for partyNpc in global.partyNpcs:
		_add_party_npc(partyNpc)

	_party_orig_objects = global.partyObjects.duplicate()
	_party_orig_objects.sort_custom(self, "_sort_party_objects")

	for partyObj in _party_orig_objects:
		var dir = Vector2.RIGHT
		if "direction" in partyObj:
			dir = partyObj.direction
		elif "input_vector" in partyObj:
			dir = partyObj.input_vector
		_party_orig_dirs.append(dir)
	
	global.inBattle = true

func init_battle_params(enemies_to_join: Array, player_adv: bool, enemy_adv: bool, can_run: bool = true, battle_bgs: Dictionary = {}, transition = null):
	for enemy in enemies_to_join:
		if !enemy is Array:
			enemy = [enemy, null]
		_add_enemy(enemy[0], enemy[1])

	if !globaldata.encountered.get(_enemy_BPs[0].stats.name, false):
		globaldata.encountered[_enemy_BPs[0].stats.name] = true
		_show_intro_outro = _enemy_BPs[0].stats.get("show_intro_outro", false)

	_music_intro = _enemy_BPs[0].stats.get("musicintro", "")
	_music = _enemy_BPs[0].stats.get("music", "")

	_player_adv = player_adv
	_enemy_adv = enemy_adv
	_can_run = can_run

	var bg = battle_bgs.get(_enemy_BPs[0].stats.get("bg"), battle_bgs["lamp"])
	_battle_bg = CanvasLayer.new()
	_battle_bg.add_child(bg.instance())
	_battle_bg.layer = -1
	uiManager.add_ui(_battle_bg)
	if transition:
		transition.connect("done", _battle_bg, "set", ["layer", 1])

func _ready():
	var transitions_in_progress = _add_players_and_npc_transitions()
	_add_party_info_plates()
	#_add_npc_battlesprites()
	for i in range(_enemy_BPs.size()):
		_add_enemy_battlesprite(_enemy_BPs[i])
	_reorganize_enemies(false)
	$ActionMenuBox.connect("next", self, "_action_box_selected")
	# when we know who up first, we want to change the icons accordingly
	
	var _conscious_party = _get_conscious_party(true)
	_add_actions_to_menu(_conscious_party[0] if _conscious_party else null)
	$TargetsBox.partyBPs = _party_BPs
	$TargetsBox.enemyBPs = _enemy_BPs

	$AnimScene.play("transitionIn")
	$AnimScene.connect("animation_finished", self, "_battle_start", [], CONNECT_ONESHOT)
	if _music != "":
		audioManager.pause_all_music()
	for enemy in _enemy_BPs:
		if enemy["stats"].get("boss"):
			_is_boss = true

	var encounterSound
	if _is_boss:
		encounterSound = _musical_effects["bossencounter"]
	elif _player_adv:
		encounterSound = _musical_effects["playeradv"]
	elif _enemy_adv:
		encounterSound = _musical_effects["enemyadv"]
	else:
		encounterSound = _musical_effects["encounter"]
	
	if _enemy_adv:
		$ActionMenuBox.hide()
		
	if uiManager.battleRematchFlag != "" and globaldata.flags.has(uiManager.battleRematchFlag):
		globaldata.flags[uiManager.battleRematchFlag] = true
	
	global.dialogue.clear()
	audioManager.add_audio_player()
	audioManager.play_music_on_latest_player(encounterSound, "")
	_save_inventories()
	
func _battle_start(anim := ""):
	_add_npc_battlesprites()

	# Enter "Actions" menu page
	if _music != "":
		var intro = ""
		if _music_intro != "":
			intro = "Battle Themes/" + _music_intro
		audioManager.add_audio_player()
		audioManager.play_music_on_latest_player(intro, "Battle Themes/" + _music)
	if _enemy_adv:
		_curr_party_mem = _party_BPs.size()
	
	# activate statuses if there are any
	for partyBP in _party_BPs:
		partyBP.refresh_status_info()

	if _show_intro_outro:
		var dialog = _enemy_BPs[0].stats.get("intro_message", "You encountered {n3}{name}!")
		dialog = _format_battle_text(dialog, _enemy_BPs[0])
		yield($Dialoguebox.start_from_string(dialog), "completed")
		$AnimAction.play("transitionIn")
		yield($AnimAction, "animation_finished")
	
	_next_active_member()

func _input(event):
	if _active and !_doing_actions:	
		if OS.is_debug_build():
			# debug win battle instantly
			if event.is_action_pressed("ui_end") and $ActionMenuBox.cursor.on:
				$ActionMenuBox.hide()
				while _enemy_BPs.size() > 0:
					_enemy_BPs[0].defeat()
				_win()
		
		if Input.is_action_just_pressed("ui_cancel") and _current_action == null:
			get_tree().set_input_as_handled()
			if _leave_menu():
				_play_sfx("back")

		if Input.is_action_pressed("ui_toggle"):
			for member in _party_BPs:
				member.partyInfo.user_fast_mode = true

	if Input.is_action_just_released("ui_toggle"):
		for member in _party_BPs:
			member.partyInfo.user_fast_mode = false


func _goto_menu(menu: BattleMenuBox, action:Action = null):
	if !_menu_page_stack.empty():
		_menu_page_stack.back().hide()
	menu.enter(true, action)
	_menu_page_stack.push_back(menu)

# returns true if anything actually happens
func _leave_menu() -> bool:
	if _menu_page_stack.size() > 1:
		_menu_page_stack.pop_back().exit()
		_menu_page_stack.back().enter()
		return true
	elif _curr_party_mem < _party_BPs.size() and $ActionMenuBox.cursor.on:
		if _is_first_active_member():
			_reset_page_stack()
			_goto_menu($ActionMenuBox)
		else:
			_prev_active_member()
		return true
	else:
		return false

# When an action box is selected, we start an Action object that will be
# assembly-lined through menus
 
# When the last menu is completed, the Action object is then saved, and we move
# on to the next player
func _action_box_selected(action_name: String):
	for box in [$TargetsBox, $PSIBox, $SkillsBox, $ItemsBox]:
		for connection in box.get_signal_connection_list("next"):
			box.disconnect(connection.signal, connection.target, connection.method)
	
	var actor: BattleParticipant = _party_BPs[_curr_party_mem]
	match(action_name):
		"Basic":
			var skill_action = SkillAction.new(actor)
			skill_action.skill = globaldata.skills[globaldata.get_basic_skill(actor.stats.name)]
			$TargetsBox.connect("next", self, "_action_selected", [skill_action])
			_goto_menu($TargetsBox, skill_action)
		"PSI":
			var skill_action = SkillAction.new(actor)
			$PSIBox.connect("next", self, "_goto_menu", [$TargetsBox, skill_action])
			$TargetsBox.connect("next", self, "_action_selected", [skill_action])
			_goto_menu($PSIBox, skill_action)
		"Skills":
			var skill_action = SkillAction.new(actor)
			$SkillsBox.connect("next", self, "_goto_menu", [$TargetsBox, skill_action])
			$TargetsBox.connect("next", self, "_action_selected", [skill_action])
			_goto_menu($SkillsBox, skill_action)
		"Items":
			var itemAction = ItemAction.new(actor)
			$ItemsBox.connect("next", self, "_goto_menu", [$TargetsBox, itemAction])
			$TargetsBox.connect("next", self, "_action_selected", [itemAction])
			_goto_menu($ItemsBox, itemAction)
		"Defend":
			_action_selected(GuardAction.new(actor))
		"Run":
			_action_selected(FleeAction.new(actor))
		_:
			pass

func _show_inability_text(character: BattleParticipant, dialog:= "", choosing_action := true): # suspend func
	if !dialog:
		yield(get_tree(), "idle_frame")
		return
	dialog = _format_battle_text(dialog, character)
	$ActionMenuBox.hide()
	yield($Dialoguebox.start_from_string(dialog), "completed")
	if choosing_action:
		$ActionMenuBox.show()

func _check_ableness_for_action(character: BattleParticipant, action: Action = null) -> bool: # suspend func
	var action_types = character.get_combined_status_effect("cant_do")
	var can_do = true
	for type in action_types:
		can_do = !_compare_action_types(action, type.action)
		if !can_do:
			yield(_show_inability_text(character, type.get("message", ""), false), "completed")
			return false
	yield(get_tree(), "idle_frame")
	return true
 
func _add_actions_to_menu(bp: BattleParticipant):
	$ActionMenuBox.reset_actions()

	if bp:
		$ActionMenuBox.set_basic_action(globaldata.get_basic_skill(bp.stats.name))
		
		for skill in bp.stats.get("learnedSkills", []):
			if skill in globaldata.skills:
				var skill_data = globaldata.skills[skill]
				if !skill_data.has("required_weapon") or bp.stats.equipment.weapon in skill_data.required_weapon:
					if skill_data.get("skillType") == "skill":
						$ActionMenuBox.add_action("Skills")
					if skill_data.get("skillType") == "psi":
						$ActionMenuBox.add_action("PSI")

		$ActionMenuBox.add_unselectable_actions(bp.get_combined_status_effect("cant_select").keys())
	
		if _is_first_active_member() and (_can_run or uiManager.battleFleeCutscene != ""):
			$ActionMenuBox.add_action("Run")

func _physics_process(delta: float):
	if _enemies_shaking:
		_shake_time += delta
		if _shake_time > SHAKE_FREQ:
			_shake_time -= SHAKE_FREQ
			for overworldSprite in $EnemyTransitions.get_children():
				overworldSprite.offset.x = rand_range(-4.0,4.0)
				overworldSprite.offset.y = rand_range(-4.0,4.0)

func _sort_party_objects(obj1, obj2) -> bool:
	var idx1 = global.POSSIBLE_PARTY_MEMBERS.find(obj1.partyMember.name)
	var idx2 = global.POSSIBLE_PARTY_MEMBERS.find(obj2.partyMember.name)
	return idx1 < idx2

func _save_inventories():
	for inv in InventoryManager.Inventories:
		_saved_inventories[inv] = InventoryManager.Inventories[inv].duplicate()

func _restore_backup_inventories():
	for inv in InventoryManager.Inventories:
		InventoryManager.Inventories[inv].clear()
		InventoryManager.Inventories[inv].append_array(_saved_inventories[inv])

func _add_party_member(stats):
	var bp := BattleParticipant.new(self, _get_bp_count(), stats, BattleParticipant.Type.PLAYABLE)
	_party_BPs.append(bp)
	bp.connect("defeated", self, "_on_bp_defeated")

func _add_party_npc(stats):
	var bp := BattleParticipant.new(self, _get_bp_count(), stats, BattleParticipant.Type.NPC)
	_npc_BPs.append(bp)
	_special_npc_BPs[stats.name] = bp
	bp.connect("defeated", self, "_on_bp_defeated")

func _get_bp_count() -> int:
	return _party_BPs.size() + _enemy_BPs.size() + _npc_BPs.size()

func _retargeting(action:Action, target_type:int, maintain := true): # suspend func
	var targets = []

	var actor_side = _get_conscious_enemies() if action.user.get_type() == BattleParticipant.Type.ENEMY else _get_conscious_party()
	var opposite_side = _get_conscious_party() + _get_conscious_npcs(true) if action.user.get_type() == BattleParticipant.Type.ENEMY else _get_conscious_enemies()

	target_type = _apply_confusion(action, target_type)

	match target_type:
		TargetType.ALL_ENEMIES:
			targets = opposite_side
		TargetType.ALL_ALLIES:
			targets = actor_side
		TargetType.RANDOM_ENEMY:
			targets = [opposite_side[randi() % opposite_side.size()]]
		TargetType.RANDOM_ALLY:
			targets = [actor_side[randi() % actor_side.size()]]
		TargetType.ANY:
			# decide random!
			var all = actor_side + opposite_side
			var random = all[randi() % all.size()]
			targets.append(random)
		TargetType.ENEMY:
			if !maintain:
				targets = [opposite_side[randi() % opposite_side.size()]]
				for actor in opposite_side:
					if actor.stats.get("priorityTarget", false):
						targets = [actor]
			else:
				targets = action.targets
		TargetType.ALLY:
			if !maintain:
				targets = [actor_side[randi() % actor_side.size()]]
				if action is ItemAction:
					continue
			else:
				targets = action.targets
		TargetType.SELF:
			targets = [action.user]
	yield(get_tree(), "idle_frame")
	return targets

# TODO maybe decorrelate the message and the return value
func _apply_confusion(action:Action, target_type:int):
	var confusion = false
	if action.user.get_combined_status_effect("confusion"):
		if (randi() % 2 + 0) == 1:
			confusion = true
	if confusion:
		action.skill = globaldata.skills.bash
		target_type = TargetType.RANDOM_ALLY
		$Dialoguebox.append(_format_battle_text(StatusManager.get_status_message("confused", "effect"), action.user))
#		if target_type in [TargetType.RANDOM_ALLY, TargetType.ALLY, TargetType.RANDOM_ENEMY, TargetType.ENEMY]:
#			target_type = TargetType.ANY
#		elif target_type in [TargetType.ALL_ENEMIES, TargetType.ALL_ALLIES]:
#			if (randi()%2+0) == 1:
#				target_type = TargetType.ALL_ENEMIES
#			else:
#				target_type = TargetType.ALL_ALLIES
	return target_type


func _reset_page_stack():
	for page in range(_menu_page_stack.size()):
		_menu_page_stack.pop_back().exit()

func _action_selected(action: Action):
	if action is GuardAction:
		action.user.battleSprite.play("guardPrep")
	elif action is ItemAction:
		action.user.battleSprite.play("itemPrep")
	elif action is SkillAction:
		if action.skill.has("skillType") and action.skill.skillType in ["basic", "skill"]:
			action.user.battleSprite.play(action.skill.userAnim + "Prep")
		else:
			if action.skill.has("userAnimColors"):
				action.user.battleSprite.set_psi_colors(action.skill.userAnimColors)
			else:
				var colors = [Color("ffffff"), Color("f81070"), Color("5757f0")] #Default colors
				action.user.battleSprite.set_psi_colors(colors)
			action.user.battleSprite.play("psiPrep")
	
	_cache_action(action)
	_reset_page_stack()

	if action is FleeAction:
		_end_player_action_choices(false)
	else:
		_next_active_member()

func tilt_bars(position:Vector2):
	var topCenter = Vector2(160, -1200)
	var topRadAngle = topCenter.direction_to(position).rotated(-PI/2).angle()
	
	$Tween.stop_all()
	$Tween.interpolate_property($top, "rect_rotation",
		$top.rect_rotation, (topRadAngle / PI) * 180, 0.2,
		Tween.TRANS_CIRC, Tween.EASE_OUT)
	
	var bottomCenter = Vector2(160, 1500)
	var bottomRadAngle = bottomCenter.direction_to(position).rotated(PI/2).angle()
	$Tween.interpolate_property($bottom, "rect_rotation",
		$bottom.rect_rotation, (bottomRadAngle / PI) * 180, 0.2,
		Tween.TRANS_CIRC, Tween.EASE_OUT)
	$Tween.start()

func _next_active_member(): # suspend func
	#next player turn
	_curr_party_mem += 1
	var can_do_action = _party_BPs[_curr_party_mem].can_act() if _curr_party_mem < _party_BPs.size() else true
	#cycle through party members until we reach next conscious party member
	while _curr_party_mem < _party_BPs.size() and !can_do_action:
		if !_party_BPs[_curr_party_mem].can_act():
			yield(_show_inability_text(_party_BPs[_curr_party_mem], _party_BPs[_curr_party_mem].get_combined_status_effect("turn_skip").get("message", "")), "completed")
		_curr_party_mem += 1
		can_do_action = _party_BPs[_curr_party_mem].can_act() if _curr_party_mem < _party_BPs.size() else true
		
	# when there is no party members left, start battle
	if _curr_party_mem >= _party_BPs.size():
		_end_player_action_choices()
	else:
		_party_BPs[_curr_party_mem].battleSprite.showAndPlay("lookIntoYourSoul")
		_add_actions_to_menu(_party_BPs[_curr_party_mem])
		_goto_menu($ActionMenuBox)

func _prev_active_member(): # suspend func
	var prev_party_member = _curr_party_mem - 1
	while prev_party_member >= 0 and !_party_BPs[prev_party_member].can_act():
		yield(_show_inability_text(_party_BPs[prev_party_member], _party_BPs[prev_party_member].get_combined_status_effect("turn_skip").get("message", "")), "completed")
		prev_party_member -= 1
	if prev_party_member < 0:
		return
	_reset_page_stack()
	_action_queue.pop_back()
	_party_BPs[_curr_party_mem].battleSprite.hideAway()
	_curr_party_mem = prev_party_member
	_party_BPs[_curr_party_mem].battleSprite.play("lookIntoYourSoul", true)
	_add_actions_to_menu(_party_BPs[_curr_party_mem])
	_goto_menu($ActionMenuBox)

func _is_first_active_member() -> bool:
	var prev_party_member = _curr_party_mem - 1
	while prev_party_member >= 0 and !_party_BPs[prev_party_member].can_act():
		prev_party_member -= 1
	return prev_party_member < 0

func _end_player_action_choices(with_enemy_delay := true): # suspend func
	if !_player_adv:
		_cache_enemy_and_npc_actions(true, !_enemy_adv)
		if with_enemy_delay:
			yield(get_tree().create_timer(.3), "timeout")
	else:
		_cache_enemy_and_npc_actions(false, true)
	var in_progress = _do_actions()
	if in_progress: yield(in_progress, "completed")
	_new_round()

func _cache_action(action:Action):
	_action_queue.append(action)

func _on_bp_defeated(bp:BattleParticipant, silent:=false):
	match bp.get_type():
		BattleParticipant.Type.PLAYABLE:
			if !silent:
				_play_sfx("playerdefeated")
				global.start_joy_vibration(0, 1, 1, 0.5)
			if _get_conscious_party().empty():
				if uiManager.battleLoseCutscene:
					_lose_battle = true
					_active = false
					_end_battle(uiManager.battleLoseCutscene)
				else:
					_lose()
		BattleParticipant.Type.ENEMY:
			_enemy_BPs.erase(bp)
			if !_enemy_BPs.empty():
				_buffer_reorganize = true
		BattleParticipant.Type.NPC:
			if !silent:
				global.start_joy_vibration(0, 1, 1, 0.5)
				if bp == _special_npc_BPs.flyingman:
					$Dialoguebox.append(_format_battle_text("BATTLE_MSG_FLYING_MAN_COLLAPSED", bp), _sound_effects["playerdefeated"].resource_path)
				else:
					_play_sfx("playerdefeated")

			_special_npc_BPs.erase(bp.stats.name)
			_npc_BPs.erase(bp)

func _add_party_info_plates():
	var partySize : int = _party_BPs.size()
	var partyIsOdd : bool
	if partySize % 2 == 1: partyIsOdd = true
	else: partyIsOdd = false
	
	var plateSize := Vector2(67, 48) # includes spacing
	var centerPlacement := Vector2(128,20)
	var evenPlacement := Vector2(94,20)
	
	var firstPlacementX : int
	
	# too lazy to do the math to make this work on its own lol
	# 5 party members can't even fit on the battle screen anyway
	match partySize:
		2: firstPlacementX = int(evenPlacement.x)
		3: firstPlacementX = int(centerPlacement.x - plateSize.x)
		4: firstPlacementX = int(evenPlacement.x - plateSize.x)
		5: firstPlacementX = int(centerPlacement.x - (plateSize.x * 2))
		6: firstPlacementX = int(evenPlacement.x - (plateSize.x * 2))
		_: firstPlacementX = int(centerPlacement.x)
#	if partyIsOdd:
#		if partySize == 1:
#			firstPlacementX = centerPlacement.x
#		else:
#			firstPlacementX = 128 - (plateSize.x * (partySize - 2))
#	else:
#		firstPlacementX = (94 + (plateSize.x / partySize)) - (plateSize.x * (partySize - 2))
		#print(plateSize.x * (partySize - 1))
	
	for i in range(partySize):
		var plate = PartyInfoTscn.instance()
		plate.pName = TextTools.replace_text(_party_BPs[i].get_name())
		plate.maxHP = _party_BPs[i].get_stat("maxhp")
		plate.maxPP = _party_BPs[i].get_stat("maxpp")
		$PartyInfo.add_child(plate)
		plate.setHP(_party_BPs[i].stats.hp, true)
		plate.setPP(_party_BPs[i].stats.pp, true)
		plate.rect_position.x = firstPlacementX + (plateSize.x * i)
		plate.rect_position.y = 20
		plate.connect("hp_scroll_done", self, "_check_player_defeated", [_party_BPs[i]])
		plate.connect("hp_scroll_done", _party_BPs[i], "hp_stopped_scrolling")
		plate.connect("pp_scroll_done", _party_BPs[i], "pp_stopped_scrolling")
		_party_BPs[i].partyInfo = plate
		
		var battleSprite = _party_battle_sprites.get(_party_BPs[i].stats.name, PartyBattleSpriteDefault).instance()

		plate.add_child(battleSprite)
		_party_BPs[i].battleSprite = battleSprite
		
		var statusBubble = StatusBubbleTscn.instance()
		battleSprite.add_child(statusBubble)
		statusBubble.rect_position.x = battleSprite.rect_size.x/2
		statusBubble.rect_position.y += 16 #magic numbers, tsk tsk roka....
		_party_BPs[i].statusBubble = statusBubble
		if !_party_BPs[i].isConscious():
			_party_BPs[i].defeat(true)

func _add_npc_battlesprites():
	for i in range(_npc_BPs.size()):
		_npc_BPs[i].battleSprite = _party_battle_sprites.get(_npc_BPs[i].stats.name, PartyBattleSpriteDefault).instance()
		_npc_BPs[i].battleSprite.init_from_ov_sprite($NpcTransitions.get_child(i))
		$NPCs.add_child(_npc_BPs[i].battleSprite)

func _add_enemy_battlesprite(enemy_bp: BattleParticipant, transition := true):
	var sprite_path_pattern := "res://Graphics/Battle Sprites/%s.png"
	var sprite_path : String = sprite_path_pattern % enemy_bp.stats.sprite
	var texture = EnemySprite.instance()
	enemy_bp.battleSprite = texture
	$Enemies.add_child(texture)
	if ResourceLoader.exists(sprite_path):
		texture.set_texture(sprite_path)
	else:
		print("could not load sprite: ", sprite_path)
		texture.set_texture(sprite_path_pattern % "invalidsprite")
	
	# put texture off screen
	texture.rect_position = Vector2(320, 0) + texture.texture.get_size()
	texture.hide()
	var statusBubble = StatusBubbleTscn.instance()
	texture.add_child(statusBubble)
	statusBubble.rect_position.x = texture.rect_size.x / 2
	statusBubble.rect_position.y += 24 - texture.rect_size.y / 2 #magic numbers, tsk tsk roka....
	enemy_bp.statusBubble = statusBubble

func _flee():
	_active = false
	for bp in _party_BPs:
		if bp.isConscious() and bp.partyInfo.HP <= bp.partyInfo.get_current_HP():
			bp.partyInfo.stop_scrolling()
	for onScreenEnemy in uiManager.onScreenEnemies:
		onScreenEnemy[1].activate()
	for enemy in _enemy_BPs:
		if enemy != null:
			if enemy.overworldObj != null:
				if enemy.overworldObj.has_method("stun"):
					enemy.overworldObj.stun()
					enemy.overworldObj.get_node("interact/CollisionShape2D").set_deferred("disabled", false)
					enemy.overworldObj.flash(3, 0.2, 0, true)
	#temp functionality
	_end_battle(uiManager.battleFleeCutscene)

func _win(): # suspend func
	_active = false
	for onScreenEnemy in uiManager.onScreenEnemies:
		onScreenEnemy[1].activate()
	
	if (!audioManager.overworldBattleMusic) or (_is_boss and audioManager.overworldBattleMusic):
		audioManager.pause_all_music()
		audioManager.add_audio_player()
		if _is_boss:
			audioManager.play_music_on_latest_player(_musical_effects["youwonboss"], _musical_effects["victory"])
		else:
			audioManager.play_music_on_latest_player(_musical_effects["youwon"], _musical_effects["victory"])
	
	#_play_sfx("res://Audio/Sound effects/EB/wow.wav")
	
	#stop rolling hp
	# show player battle sprites + victory animation
	for bp in _party_BPs:
		if bp.isConscious():
			if bp.partyInfo.HP <= bp.partyInfo.get_current_HP():
				bp.partyInfo.stop_scrolling()
			bp.reset_all_stat_mods()
			# heal all non persistent ailments
			var status_to_remove = bp.stats.status.duplicate()
			for status in status_to_remove:
				if !StatusManager.get_ailment_info(status.ailment)["healing"].get("persistent", false): 
					bp.set_status(status.ailment, false)
			if !bp.battleSprite.state == bp.battleSprite.states.SHOWN:
				bp.battleSprite.showIn()
			bp.battleSprite.play("victory", true)
			# save off stats to globaldata
#			for partyMem in global.party:
#				partyMem.stats = bp.stats

	$Dialoguebox.play_win()
	yield(get_tree().create_timer(3), "timeout")
	#text box
	var receiving_party = []
	for i in _party_BPs.size():
		if _party_BPs[i].isConscious() and _party_BPs[i].stats.level < globaldata.levelCap:
			receiving_party.append(_party_BPs[i])

	var exp_per_ally := 0

	if receiving_party.size() == 0:
		receiving_party = _get_conscious_party()
	else:
		exp_per_ally = int(round(_exp_pool / receiving_party.size()))
	
	var dialog: String
	match receiving_party.size():
		2:
			dialog = _format_battle_text("BATTLE_MSG_EXP_TWO_ALLIES", receiving_party[0], [receiving_party[1]], null, exp_per_ally)
		1:
			dialog = _format_battle_text("BATTLE_MSG_EXP_ONE_ALLY", receiving_party[0], [], null, exp_per_ally)
		_:
			dialog = _format_battle_text("BATTLE_MSG_EXP_MANY_ALLIES", receiving_party[0], [], null, exp_per_ally)
	
	yield($Dialoguebox.start_from_string(dialog), "completed")
		
	var in_progress = _give_exp(receiving_party, exp_per_ally)
	if in_progress: yield(in_progress, "completed")

	var items_to_overworld := []
	in_progress = _do_rewards(items_to_overworld)
	if in_progress: yield(in_progress, "completed")

	_give_cash()

	_end_battle(uiManager.battleWinCutscene, items_to_overworld)

func _do_rewards(items_to_overworld: Array): # suspend func
	# do we get an item???
	var droppedItem = ""
	var itemGiven = false
	var chanceTrue = false
	for itemStat in _items_pool:
		for item in itemStat.items:
			if item.has("rare") and item.rare:
				if not itemStat.enemyName in globaldata.rareDrops:
					globaldata.rareDrops[itemStat.enemyName] = 0
				var r = rand_range(0.0, 100)
				var chanceMod
				if item.has("increaseChance"):
					chanceMod = item.increaseChance * globaldata.rareDrops[itemStat.enemyName]
				else:
					chanceMod = 0
				if r <= item.chance + chanceMod or globaldata.rareDrops[itemStat.enemyName] >= 100.0 / item.chance:
					chanceTrue = true
					globaldata.rareDrops[itemStat.enemyName] = 0
				else:
					globaldata.rareDrops[itemStat.enemyName] += 1
			else:
				var r = randi() % 100 + 1
				if r <= item.chance:
					chanceTrue = true
			if chanceTrue:
				itemGiven = true
				droppedItem = item.item
				# LOCALIZATION Code change: We need full item object
				var itemData = InventoryManager.Load_item_data(droppedItem)
				# LOCALIZATION Use of csv key for "The enemy dropped a present!"
				$Dialoguebox.append(tr("BATTLE_MSG_PRESENT"))
				# LOCALIZATION Code change: Centralized formatting of battlers, items and articles
				# LOCALIZATION Use of csv key for "Inside the present, there was {i3}{item}."
				$Dialoguebox.append(_format_battle_text("BATTLE_MSG_PRESENT_INSIDE", null, [], itemData))
				#who has room in their inventory?
				var itemGet = false
				for partyMem in _party_BPs:
					if !InventoryManager.isInventoryFull(partyMem.stats.name):
						if partyMem.isConscious():
							# LOCALIZATION Code change: Centralized formatting of battlers, items and articles
							# LOCALIZATION Use of csv key for "{n0}{name} took {i5}."
							$Dialoguebox.append(
								_format_battle_text("BATTLE_MSG_PRESENT_TAKING", partyMem, [], itemData),
							"EB/itemget1.wav")
						else :
							# LOCALIZATION Code change: Centralized formatting of battlers, items and articles
							# LOCALIZATION Use of csv key for "{i0}{item} was put inside {name}'s bag."
							$Dialoguebox.append(
								_format_battle_text("BATTLE_MSG_PRESENT_GIVING", partyMem, [], itemData),
							"EB/itemget1.wav")
						InventoryManager.addItem(partyMem.stats.name, droppedItem)
						itemGet = true
						break
				#does it get dropped??
				if !itemGet:
					$Dialoguebox.append(_format_battle_text("BATTLE_MSG_PRESENT_FULL", null, [], itemData))
					var dropItem = DroppedItemNode.instance()
					# yo, I heard you like items, so I set an item to your item item
					dropItem.item = item.item
					dropItem.reset_when_consumed = true
					items_to_overworld.append(dropItem)
#					if itemStat.overworld != null:
#						itemStat.overworld.queued_item = item.item
				break
		if itemGiven:
			break
	
	if uiManager.battleWinFlag != "" and globaldata.flags.has(uiManager.battleWinFlag):
		globaldata.flags[uiManager.battleWinFlag] = true
	
	if droppedItem != "":
		yield($Dialoguebox.start_from_appended(), "completed")

func _lose(): # suspend func
	_reset_page_stack()
	_lose_battle = true
	_active = false
	$ActionMenuBox.hide()
	_remove_battle_music()
	audioManager.pause_all_music()
	
	if !$Dialoguebox.did_finish():
		yield($Dialoguebox, "done")
	else:
		yield(get_tree().create_timer(0.5), "timeout")
	_play_sfx("partylose")
	yield($Dialoguebox.start_from_string(tr("BATTLE_MSG_GAME_OVER")), "completed")
	yield(uiManager.game_over(false), "completed")
	#set up return TEMP
	for obj in _party_orig_objects:
		obj.show()
	_hide_battle_BG()
	global.inBattle = false
	_restore_backup_inventories()
	uiManager.remove_ui(self)

func _end_battle(cutscene := "", items_to_overworld := []): # suspend func
	$Dialoguebox.hide()
	$ActionMenuBox.hide()
	if (!audioManager.overworldBattleMusic) or (_is_boss and audioManager.overworldBattleMusic):
		#remove victory and level up tracks
		_remove_battle_music()
		
		#resume overworld music
		if audioManager.get_audio_player(0) != null:
			if audioManager.get_audio_player(0).stream_paused:
				audioManager.music_fadein(0, audioManager.get_audio_player(0).volume_db, 3)
	
	audioManager.resume_all_music()
	$AnimScene.play("transitionOut")
	_drop_item_to_overworld(items_to_overworld)
	yield($AnimScene, "animation_finished")
		
	# release player or play cutscene
	global.inBattle = false
	uiManager.remove_ui(self)
	if cutscene != "":
		global.set_dialog(cutscene)
		uiManager.open_dialogue_box()
	else:
		global.persistPlayer.unpause()
	uiManager.reset_battle_cutscenes()

func _add_enemy(enemyName:String, overworld_object) -> BattleParticipant:
	var new_enemy_stats = globaldata.get_json_data("res://Data/Battlers/%s.yaml" % enemyName, "res://Data/Battlers/testenemy.yaml")
	var new_enemy := BattleParticipant.new(self, _get_bp_count(), new_enemy_stats, BattleParticipant.Type.ENEMY)
	
	new_enemy.handle_homonymy_with(_enemy_BPs)

	if overworld_object != null and overworld_object.get("startingHP") != null:
		new_enemy.stats.hp = overworld_object.startingHP
	#then exps, cashes, and items!!
	_exp_pool += new_enemy.stats.exp
	_cash_pool += new_enemy.stats.cash
	if new_enemy.stats.has("items"):
		if !_is_boss:
			_items_pool.append(
				{"items": new_enemy.stats.items,
				 "overworld": overworld_object,
				 "enemyName": new_enemy.stats.name})
		elif new_enemy.stats.boss:
			#only append boss item if it's a boss encounter
			_items_pool.append(
				{"items": new_enemy.stats.items,
				 "overworld": overworld_object,
				 "enemyName": new_enemy.stats.name})
	_enemy_BPs.append(new_enemy)
	new_enemy.connect("defeated", self, "_on_bp_defeated")
	
	#next, we set up enemy transitions, if there is an overworld sprite
	var enemySpr = null
	if overworld_object != null:
		if overworld_object.has_method("die"):
			new_enemy.overworldObj = overworld_object
			overworld_object.connect("enemy_erased", new_enemy, "set_overworld_obj_null")
		overworld_object.hide()
		enemySpr = overworld_object.duplicate_sprite()
		#duplicate() duplicates the child nodes of the sprite so we have to remove them
		enemySpr.set_script(null)
		for child in enemySpr.get_children():
			child.queue_free()
		enemySpr.position = overworld_object.get_viewport().canvas_transform.xform(overworld_object.position)
	else:
		# otherwise, we just add an empty sprite
		enemySpr = Sprite.new()
	$EnemyTransitions.add_child(enemySpr)
	return new_enemy

func _add_players_and_npc_transitions(): # suspend func
#	var arr = [global.persistPlayer]
#	arr.append_array(global.partyObjects)
	for partyMem in _party_orig_objects:
		partyMem.hide()
		var sprite = partyMem.duplicate_sprite()
		
		sprite.show()
		sprite.position = partyMem.get_viewport().canvas_transform.xform(partyMem.position) - Vector2(0,4)
		if partyMem.partyMember.name in global.POSSIBLE_PLAYABLE_MEMBERS:
			sprite.frame_coords = SPRITE_FRAMES.crouch_down
			$PlayerTransitions.add_child(sprite)
		else:
			sprite.frame_coords = SPRITE_FRAMES.crouch_right
			$NpcTransitions.add_child(sprite)
		
		var tween = Tween.new()
		_party_orig_positions.append(sprite.position)
		sprite.add_child(tween)
		tween.interpolate_property(sprite, "scale", \
			sprite.scale, Vector2(1.1, 0.9), 0.1, \
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.interpolate_property(sprite, "scale", \
			Vector2(1.1, 0.9), Vector2(1, 1), 0.1, \
			Tween.TRANS_BACK, Tween.EASE_OUT, 0.1)
		if global.party.size() == 1 and sprite.position.x < 164 and sprite.position.x > 156:
			var dir = 1
			if (randi()%2+0) == 1:
				dir = 1
			else:
				dir = -1
			tween.interpolate_property(sprite, "position:x", \
				sprite.position.x, sprite.position.x + 16 * dir, 0.2, \
				Tween.TRANS_BACK, Tween.EASE_OUT)
		tween.start()
		yield(get_tree().create_timer(.01), "timeout")

func _cache_enemy_and_npc_actions(do_enemies := true, do_npcs := true):
	var pool = []
	if do_enemies:
		pool += _enemy_BPs
	if do_npcs:
		pool += _npc_BPs
	for actor in pool:
		# add skill weights
		var chosenSkill = "bash"
		if "scriptedSkill" in actor.stats and actor.stats["scriptedSkill"] != "":
			chosenSkill = actor.stats["scriptedSkill"]
			actor.stats["scriptedSkill"] = ""
		else:
			var allWeights := 0
			for skill in actor.stats.skills:
				allWeights += skill.weight
			var i = rand_range(0.0, float(allWeights))
			#print("rolled ", i, " out of ", allWeights)
			# find where the random number landed
			var currentWeight = 0
			for skill in actor.stats.skills:
				currentWeight += skill.weight
				if i <= currentWeight:
					chosenSkill = skill.skill
					break
		var skillAction = SkillAction.new(actor)
		skillAction.skill = globaldata.skills[chosenSkill]
		_cache_action(skillAction)

func _do_actions(): # suspend func
	_doing_actions = true
	$ActionMenuBox.hide()
	_action_queue.sort_custom(self, "_sort_by_priority")

	for i in range(_action_queue.size()):
		var action = _action_queue[i]
		call_deferred("_start_action", action)
		yield(action, "done")
		var status_in_progress = _check_status_effect(action.user)
		if status_in_progress: yield(status_in_progress, "completed")

func _new_round(): # suspend func
	for enemy in _enemy_BPs:
		enemy.handle_battler_script()
	if _buffer_reorganize:
		_reorganize_enemies()
	_current_action = null
	_doing_actions = false
	# check for win
	if _get_conscious_enemies().empty():
		_win()
		return
	
	# check for healed statuses and do passives
	for bp in (_get_conscious_party() + _get_conscious_enemies()):
		for status in bp.stats.status:
			var info = StatusManager.get_ailment_info(status.ailment)
			if info["healing"].get("passive_heal", false):
				var roll = randi() % 100 + 1
				var prob = info["healing"].get("heal_prob", PASSIVE_HEAL_PROB)
				var turns = info["healing"].get("mandatory_turns", 3)
				if roll <= prob * (status.battleTurns - turns):
					yield(_heal_status(status.ailment, bp), "completed")
				else:
					status.battleTurns += 1
					
		# TODO Passive for end of turn?

	_turns_count += 1
	emit_signal("round_done", _turns_count)
	yield(get_tree().create_timer(.4), "timeout")
	_player_adv = false
	_enemy_adv = false
	if !_active:
		return
	# start new round!
	for action in _action_queue:
		action.free()
	_action_queue.clear()
	_curr_party_mem = -1
	_next_active_member()

func _check_status_effect(character:BattleParticipant, before_turn := false, on_complete: FuncRef = null, on_complete_params: Array = []): # suspend func
	var effects_to_do := []
	for effect in character.get_all_status_effects():
		for key in effect.keys():
			var dict = {key: effect[key]}
			if effect[key] is Dictionary:
				if before_turn:
					if effect[key].get("moment", "after") == "before":
						effects_to_do.append(dict)
				else:
					if effect[key].get("moment", "after") == "after":
						effects_to_do.append(dict)
	
	for effect in effects_to_do:
		var in_progress = _do_status_effect(character, effect)
		if in_progress: yield(in_progress, "completed")
	
	if on_complete:
		on_complete.call_funcv(on_complete_params)

func _do_status_effect(character:BattleParticipant, effect:Dictionary):
	var key = effect.keys()[0]
	var value = effect.values()[0]
	match key:
		"do_skill":
			var action = SkillAction.new(character)
			action.skill = globaldata.skills[value.get("skill", "attack")]
			var in_progress = _start_action(action)
			if in_progress: yield(in_progress, "completed")
			
	#for status in character.stats.status:
	#	if status.ailment == "asthma": # TODO replace with get_combined_status_effect
	#		var dialog = _format_battle_text("BATTLE_MSG_ASTHMA_" + str(status.battleTurns), character)
	#		yield($Dialoguebox.start_from_string(dialog), "completed")
	#		status.battleTurns += 1
	#		if status.battleTurns >= 4:
	#			character.defeat()
	#			break

func _start_action(action:Action): # suspend func
	if _lose_battle:
		return
	if _buffer_reorganize:
		yield(_reorganize_enemies(), "completed")
		if !_active:
			return
	_current_action = action
	var turn_skip = _current_action.user.get_combined_status_effect("turn_skip")
	if turn_skip.get("enable", false):
		yield(_show_inability_text(_current_action.user, turn_skip.get("message", ""), false), "completed")
		action.emit_signal("done")
		return
	#hackiest code you've ever seen, at least it works
	for enemy in _enemy_BPs:
		if enemy.stats.has("text"):
			if _current_action.user == enemy:
				for bp in _party_BPs:
					bp.stats.newHp = bp.stats.hp
					bp.partyInfo.stop_scrolling()
				yield(get_tree().create_timer(1), "timeout")
				_darken_bg()
				yield($Dialoguebox.start_from_scripted_dialog(enemy.stats.text, false), "completed")
				_undarken_bg()
				enemy.stats.erase("text")
				for bp in _party_BPs:
					bp.partyInfo.setHP(bp.stats.newHp)
					
	# check for win
	if _get_conscious_enemies().empty():
		_win()
		return
	
	if !action.user.isConscious():
		action.emit_signal("done")
		return

	if _lose_battle:
		return
	
	var can_do_action = yield(_check_ableness_for_action(action.user, action), "completed")
	if !can_do_action:
		action.emit_signal("done")
		return
	
	if action.user.get_type() == BattleParticipant.Type.ENEMY:
		_play_sfx("enemyturn")
		if action.skill.skillType == "psi":
			if action.skill.has("enemyFlashColor"):
				action.user.battleSprite.set_psi_flash_color(action.skill.enemyFlashColor)
			else:
				action.user.battleSprite.set_psi_flash_color(Color.white)
			action.user.battleSprite.flash_psi()
		else:
			action.user.battleSprite.flash()
	else:
		if !action is GuardAction:
			_play_sfx("attack1")
	yield(get_tree().create_timer(.2), "timeout")
	
	if !_active:
		return
	
	# this category handles both skills and items
	# because items just contain a skill 
	if action is SkillAction and !action is ItemAction:
		# TODO: check if the action is possible??
		# aka, what if we try to use a status healing item on someone whose status is now healed
		#      or what if we try to heal or attack someone who is unconscious
		yield(_retarget_action(action), "completed")
		_apply_skill_costs(action.skill, action.user, action.targets)
		
		var dialog := _format_battle_text(action.get_dialog(), action.user, action.targets, action.skill)
		if !"dialog" in action.skill:
			if action.skill.skillType == "psi":
				if action.user.get_type() == BattleParticipant.Type.ENEMY:
					_play_sfx("enemypsi")
				else:
					_play_sfx("yourpsi")
		
		$Dialoguebox.append(dialog)
		yield($Dialoguebox.start_from_appended(), "completed")
		
		_do_skill_with_screen_effect(action)
		#$Dialoguebox.connect("done", self, "_do_skill_with_screen_effect", [action], CONNECT_ONESHOT)
		#$Dialoguebox.start_from_scripted_dialog(dialog)
	elif action is ItemAction:
		InventoryManager.reduce_or_drop_item(action.user.stats.name, action.inv_idx)
		_play_battle_sprite_anim(action.user, "item")

		var dialog_text = "BATTLE_MSG_ITEM_SELF" if action.user == action.targets[0] else "BATTLE_MSG_ITEM_OTHER"
		dialog_text = action.skill.get("dialog", dialog_text)
		var dialog = _format_battle_text(dialog_text, action.user, action.targets, action.item)
		$Dialoguebox.append(dialog)
		yield($Dialoguebox.start_from_appended(), "completed")
		if action.item.get("battle_action"):
			_do_skill_with_screen_effect(action)
		else:
			_do_item(action)

		#if action.item.get("battle_action"):
		#	$Dialoguebox.connect("done", self, "_do_skill_with_screen_effect", [action], CONNECT_ONESHOT)
		#else:
		#	$Dialoguebox.connect("done", self, "_do_item", [action], CONNECT_ONESHOT)
		#$Dialoguebox.start_from_scripted_dialog(dialog)
	elif action is GuardAction:
		_do_guard(action)
	elif action is FleeAction:
		var dialog = _format_battle_text("BATTLE_MSG_FLEE", action.user)
		yield($Dialoguebox.start_from_string(dialog), "completed")
		_try_flee(action)

func _retarget_action(action:Action): # suspend func
	# ANYWAY if there are no targets (or, they are unconscious), try again
	var target_ok = (!action.targetType in [TargetType.ALL_ALLIES, TargetType.ALL_ENEMIES]) and !action.targets.empty()
	for target in action.targets:
		if !target.isConscious() and !action.targetUnconscious:
			#redo targets, heck
			target_ok = false
	action.targets = yield(_retargeting(action, action.targetType, target_ok), "completed")
	yield(get_tree(), "idle_frame")

func _apply_skill_costs(skill, user:BattleParticipant, targets:Array):
	# subtract hp/pp costs
	if skill.hpCost > 0:
		user.stats.hp -= skill.hpCost
		if user.get_type() == BattleParticipant.Type.PLAYABLE:
			user.partyInfo.setHP(user.stats.hp)
	if skill.ppCost > 0:
		user.stats.pp -= skill.ppCost
		if user.get_type() == BattleParticipant.Type.PLAYABLE:
			user.partyInfo.setPP(user.stats.pp)

func _compare_action_types(action:Action, desiredType: Dictionary):
	var actionType = {"dict": desiredType.get("action_type", "any"), "compare": "actionType"}
	var skillType = {"dict": desiredType.get("skill_type", "any"), "compare": "skillType"}
	var damageType = {"dict": desiredType.get("damage_type", "any"), "compare": "damageType"}
	var specificSkill = {"dict": desiredType.get("specific_skill", "any"), "compare": "identifier"}
	for typeDict in [actionType, skillType, damageType, specificSkill]:
		if not typeDict.dict is Array:
			typeDict.dict = [typeDict.dict]
		var isType = false
		if "any" in typeDict.dict:
			isType = true
		else:
			for type in typeDict.dict:
				if action.skill.has(typeDict.compare):
					if type == action.skill.get(typeDict.compare, ""):
						isType = true
		if !isType:
			return false
	return true
			
	
func _do_fail_chance(action:Action) -> bool:
	var hitRoll = randi() % 100 + 1
	var statusRoll = randi() % 100 + 1
	var ailmentChance = action.user.get_combined_status_effect("fail_additionner")
	if statusRoll <= ailmentChance:
		return true
	if hitRoll <= action.skill.failChance:
		return true
	return false

func _do_status_hit_heal(character:BattleParticipant, action:Action):
	for status in character.stats.status:
		var info = StatusManager.get_ailment_info(status.ailment)
		if info.has("healing") and info.healing.has("by_hit"):
			if info.healing.by_hit.has("action") and !_compare_action_types(action, info.healing.by_hit.action):
				continue
			var roll = randi() % 100 + 1
			var prob = info.healing.by_hit.get("prob", HEAL_BY_HIT_PROB)
			yield(_try_afflict_status(status.ailment, prob, character), "completed")

func _do_status_transmission(transmitter:BattleParticipant, transmitted:BattleParticipant, action:Action):
	for status in transmitter.stats.status:
		var info = StatusManager.get_ailment_info(status.ailment)
		if info.has("transmit"):
			if info.transmit.has("action") and !_compare_action_types(action, info.transmit.action):
				continue
			var roll = randi() % 100 + 1
			var prob = info.transmit.get("prob", TRANSMIT_PROB)
			yield(_try_afflict_status(status.ailment, prob, transmitted), "completed")
			
func _get_damage_modifiers(effects: Array, action:Action) -> int:
	var modifier = 1
	for effect in effects:
		if effect.has("action") and _compare_action_types(action, effect.action):
			modifier *= effect.get("mod", 1)
	return modifier

func _get_damage_color(effects: Array, action:Action) -> Color:
	for effect in effects:
		if effect.has("action") and _compare_action_types(action, effect.action):
			return Color(effect.get("color", "FFFFFF"))
	return Color.white

func _calculate_damage(action:Action, target:BattleParticipant, passive_multiplier, adrenaline, smash):
	var stats_mod := 0
	var user := action.user
	var value_type = action.skill.get("damageValueType", "normal")
	var val
	if action.skill.skillType == "psi":
		stats_mod = user.get_stat("iq") / 5
	else:
		stats_mod = user.get_stat("offense")
				
	var defense: int = target.get_stat("defense")
	if target.defending:
		defense *= 2
	match value_type:
		"fixed":
			val = int(action.skill.damage)
			if action.skill.has("variance"):
				val = floor(val + (randf() * action.skill.variance) - action.skill.variance/2.0)
		"percentage":
			val = int(action.skill.damage*target.stats.hp/100)
		"normal":
			val = int(action.skill.damage) + stats_mod - (defense/2.0)
			if smash:
				val *= 2
			else:
				if adrenaline:
					val *= 1.5
				val = floor(val + (randf() * action.skill.variance) - action.skill.variance/2.0)
			
			val *= target.get_vulnerab_multiplier(action.skill.damageType)
			# apply creature type damage multiplier
			val *= action.skill.get("creature_type_multipliers", {}).get(target.stats.get("creature_type"), 1)
			# apply multiplier from passive skill
			val *= passive_multiplier
			
			var user_modifier = user.get_combined_status_effect("dealt_mod")
			val *= float(_get_damage_modifiers(user_modifier, action))
			var target_modifier = target.get_combined_status_effect("received_mod")
			val *= float(_get_damage_modifiers(target_modifier, action))

	val = max(1, val)
	
	return val

func _do_attack_damage(action:Action, target:BattleParticipant, passive_multiplier := 1.0, intended_target:BattleParticipant = null): # suspend func
	var can_smash := false
	var use_flying_num := false
	var user := action.user
	if action.skill.skillType != "psi":
		can_smash = true
		use_flying_num = true
	
	# check for smash attack
	
	var smash_roll := randi() % 100 + 1
	var smashed := false
	var adrenaline := false
	# smash chance is either 5/100 or guts/5
	if action.user.get_type() == BattleParticipant.Type.PLAYABLE:
		if action.user.stats.hp <= 0:
			adrenaline = true
		if "Slingshot" in user.stats.equipment.weapon:
			can_smash = false
	
	if smash_roll <= max(5, floor(user.get_stat("guts")/5)) and user.get_stat("guts") > 0 and can_smash:
		# SMAAAAAAASH
		smashed = true
	
	var val = _calculate_damage(action, target, passive_multiplier, adrenaline, smashed)

	if target != intended_target and _ongoing_npc_protection.get(target.stats.name):
		if _ongoing_npc_protection[target.stats.name].is_valid():
			yield(_ongoing_npc_protection[target.stats.name], "completed")
		_ongoing_npc_protection[target.stats.name] = null

	if smashed:
		var smash_attack = _create_smash_attack(target)
		$SMASHBOX.add_child(smash_attack)
		_play_sfx("smash", 1)
		global.start_joy_vibration(0, 1, 1, 0.4)
		global.start_slowmo(0.5, 0.5)
	elif target.get_type() == BattleParticipant.Type.ENEMY:
		_play_sfx(action.skill.hitSound, 1)
		global.start_joy_vibration(0, 0.5, 0.8, 0.2)
	
	var val_int := int(val)
	var damage_num := str(val_int)
	if adrenaline:
		damage_num = damage_num + "!"
	var rising_num = _create_rising_num(damage_num, target, use_flying_num)
	#manage color
	var color = Color.white
	var user_color = _get_damage_color(user.get_combined_status_effect("dealt_color"), action)
	var target_color = _get_damage_color(target.get_combined_status_effect("received_color"), action)
	if user_color != Color.white:
		color = user_color
	elif target_color != Color.white:
		color = target_color
	rising_num.add_color_override("font_color", color)
	
	rising_num.run()

	_do_hit_effect(action.skill.hitEffect, action.skill.hitSound, target)

	var in_progress = _apply_damage(target, val_int, intended_target)	
	if in_progress: yield(in_progress, "completed")

	yield(get_tree(), "idle_frame")

func _apply_passive_skill(passive_skill_actions: Dictionary, skill: Dictionary, user: BattleParticipant, target: BattleParticipant):
		var damage_multiplier = passive_skill_actions.get("damage_multiplier", 1)

		# Sound/vibration
		if passive_skill_actions.has("sound"):
			$AudioStreamPlayer.stream = _sound_effects[passive_skill_actions.sound]
			$AudioStreamPlayer.play()
		if passive_skill_actions.get("vibrate", 0):
			global.start_joy_vibration(0, 0.3, 0.6, passive_skill_actions.vibrate)	

		# Hit dialogue
		if passive_skill_actions.has("dialogue"):
			var item = globaldata.items.get(passive_skill_actions.get("context_item", "error"))
			var dialog := _format_battle_text(passive_skill_actions.dialogue, user, [target], item)
			yield($Dialoguebox.start_from_string(dialog), "completed")

		# Counter attack
		if passive_skill_actions.get("counter_multiplier", 0):
			var counter_action = SkillAction.new(target)
			counter_action.targets = [user]
			counter_action.skill = skill
			if passive_skill_actions.counter_multiplier > 0:
				yield(_do_attack_damage(counter_action, user, passive_skill_actions.counter_multiplier), "completed")

		# Add/remove items
		if passive_skill_actions.has("remove_item"):
			InventoryManager.removeItemFromChar(target.stats.name, passive_skill_actions.remove_item)
		if passive_skill_actions.has("add_item"):
			InventoryManager.addItem(target.stats.name, passive_skill_actions.add_item)

		# Dialogue after
		if passive_skill_actions.has("dialogue_after"):
			yield($Dialoguebox.start_from_string(tr(passive_skill_actions.dialogue_after)), "completed")

func _do_skill(action: SkillAction): # suspend func
	if !action.user.isConscious():
		action.emit_signal("done")
		return

	var no_miss_targets = []
	for target in action.targets:
		if !_do_fail_chance(action):
			no_miss_targets.append(target)
	
	# Dictionary (ally → npc)
	var allies_protected_by_npcs = {}

	match action.user.get_type():
		BattleParticipant.Type.PLAYABLE:
			_play_battle_sprite_anim(action.user, action.skill.userAnim)
			if action.skill.skillType == "basic":
				if action.user.battleSprite.animationPlayer.has_animation(action.skill.userAnim):
					yield(action.user.battleSprite, "apply_damage")
		
		BattleParticipant.Type.ENEMY:
			if action.skill.actionType == ActionType.DAMAGE:
				no_miss_targets.sort_custom(self, "_sort_by_low_hp")
				var protected_targets_count = 0
				for npc_name in _special_npc_BPs:
					if action.skill.damage < NPC_TAKING_HIT_THRESHOLD.get(npc_name, 0) and protected_targets_count < no_miss_targets.size():
						var roll := randi() % 100 + 1
						if roll <= NPC_TAKING_HIT_CHANCE.get(npc_name, 0):
							var cur_target = no_miss_targets[protected_targets_count]
							allies_protected_by_npcs[cur_target.stats.name] = npc_name
							protected_targets_count += 1
							if cur_target == action.targets[0]:
								_ongoing_npc_protection[npc_name] = _special_npc_BPs[npc_name].battleSprite.protect_ally(cur_target)
								yield(get_tree().create_timer(_special_npc_BPs[npc_name].battleSprite.ENEMY_ATTACK_DELAY), "timeout")
							else:
								_ongoing_npc_protection[npc_name] = null
				
				if action.skill.skillType in ["basic", "skill"]:
					action.user.battleSprite.attack()
					yield(action.user.battleSprite, "apply_damage")

		BattleParticipant.Type.NPC:
			if action.skill.actionType == ActionType.DAMAGE:
				yield(action.user.battleSprite.attack_target(action.targets[0]), "completed")

	for i in action.targets.size():
		var skill := action.skill
		var user := action.user
		var target: BattleParticipant = action.targets[i]
		var intended_target := target
		var miss: bool = !(target in no_miss_targets)

		if !target.isConscious() and !action.targetUnconscious:
			continue

		if user.get_type() == BattleParticipant.Type.PLAYABLE:
			_play_sfx(action.skill.useSound)

		var pre_hit_fx_in_progress = _do_pre_hit_effect(target, skill.get("preHitEffect"))

		if allies_protected_by_npcs.has(target.stats.name):
			var npc_name = allies_protected_by_npcs[target.stats.name]
			if !_ongoing_npc_protection[npc_name]:
				_ongoing_npc_protection[npc_name] = _special_npc_BPs[npc_name].battleSprite.protect_ally(target)
			target = _special_npc_BPs[npc_name]

		yield(pre_hit_fx_in_progress, "completed")

		# if this is healing
		# damage skill!
		if skill.actionType == ActionType.DAMAGE:
			# blind check!
			if !miss:
				var passive_skill_actions := target.get_passive_skill_for_attack(skill)
				
				var damage_multiplier = passive_skill_actions.get("damage_multiplier", 1)
				if damage_multiplier > 0:
					yield(_do_attack_damage(action, target, damage_multiplier, intended_target), "completed")
				
				var in_progress = _apply_passive_skill(passive_skill_actions, skill, user, target)
				if in_progress: yield(in_progress, "completed")

				# Status ailment
				if damage_multiplier > 0:
					for status in skill.statusEffects:
						yield(_try_afflict_status(status.name, status.chance, target), "completed")
				
			else: # if miss:
				var risingNum := _create_rising_num("Miss", target)
				risingNum.run()
				
				target.battleSprite.dodge()
				if target.get_type() == BattleParticipant.Type.ENEMY:
					$AudioStreamPlayer.stream = _sound_effects["miss"]
				else:
					$AudioStreamPlayer.stream = _sound_effects["dodge"]
				$AudioStreamPlayer.play()
				
		# for healin skills
		elif skill.actionType == ActionType.HEALING:
			var val: int = skill.damage + user.get_stat("iq") / 5
			#apply healing with variance!
			val += (randf() * skill.variance) - (skill.variance / 2)
			_apply_restore_hp(target, val, action.targetUnconscious)
			global.start_joy_vibration(0, 0.3, 0, 0.3)
			print("%s is healed by %s!" % [target.get_name(), val])
			var risingNum := _create_rising_num(str(val), target)
			risingNum.add_color_override("font_color", Color("00ee44"))
			risingNum.run()
			_do_hit_effect(action.skill.hitEffect, action.skill.hitSound, target)
		# for non hp stuff
		else:
			if !miss:
				#free space~!! dumbass lloyd shit go here for now
				for status in skill.statusEffects:
					yield(_try_afflict_status(status.name, status.chance, target, true), "completed")
				if action.skill == globaldata.skills.spy:
					var dialog: Array
					if "description" in action.targets[0].stats:
						dialog = [
							tr("BATTLE_MSG_SPY_NAME") + action.targets[0].get_name(),
							tr(action.targets[0].stats.description)
						]
					else :
						dialog = [_format_battle_text("BATTLE_MSG_SPY_FAILED", action.user)]
					yield($Dialoguebox.start_from_array(dialog), "completed")
				elif action.skill == globaldata.skills.escapeCrumbs:
					if _can_run:
						_flee()
					else :
						yield($Dialoguebox.start_from_string(tr("BATTLE_MSG_FLEE_FAILED")), "completed")
				elif "allies" in action.skill and !action.skill.allies.empty() and _enemy_BPs.size() < MAX_ENEMY_COUNT:
					# lookin' for allies
					var allWeights := 0
					for ally in action.skill.allies:
						allWeights += ally.weight
					var j = rand_range(0.0, float(allWeights))
					# find where the random number landed
					var chosenAlly = ""
					var currentWeight = 0
					for ally in action.skill.allies:
						currentWeight += ally.weight
						if j < currentWeight:
							chosenAlly = ally.ally
							break
					if chosenAlly != "":
						var enemyBP = _add_enemy(chosenAlly, null)
						_add_enemy_battlesprite(enemyBP, false)
						enemyBP.battleSprite.show()
						_new_enemies.append(enemyBP)
						_buffer_reorganize = true
			else:
				if action.skill.has("failDialog"):
					var dialog = _format_battle_text(action.skill.failDialog, action.user, action.targets, action.skill)
					yield($Dialoguebox.start_from_string(dialog), "completed")
		
		if skill.statusHeals != []:
			if skill.statusAmountHealed > 0:
				for j in skill.statusAmountHealed:
					for status in target.stats.status:
						if status.ailment in skill.statusHeals:
							yield(_heal_status(status.ailment, target), "completed")
							break
			elif skill.statusAmountHealed == -1:
				for status in skill.statusHeals:
					yield(_heal_status(status.ailment, target), "completed")
				
		for stat in skill.get("statMods", {}):
			yield(_mod_stat(stat, skill.statMods[stat], target), "completed")
			if !_active:
				return
		if !miss:
			var in_progress = _do_status_transmission(action.user, target, action)	
			if in_progress: yield(in_progress, "completed")
		
			in_progress = _do_status_hit_heal(target, action)
			if in_progress: yield(in_progress, "completed")
		yield(get_tree().create_timer(.175), "timeout")
		if !_active:
			return

	#check if we buffered any player knockouts
	if !_buffered_player_defeat.empty():
		for partyBp in _buffered_player_defeat:
			_check_player_defeated(partyBp)
		_buffered_player_defeat.clear()
	if !_active:
		return
	#check for status effect damage
	yield(get_tree().create_timer(.4), "timeout")
	if !_active:
		return
	
	if action.user.get_type() == BattleParticipant.Type.PLAYABLE and !action.user.defending:
		action.user.battleSprite.hideAway()
		#if action.skill.has("userHideAnim") and action.skill.userHideAnim != "":
		#	action.user.battleSprite.hideAway(action.skill.userHideAnim, true)
		#else:
		#	action.user.battleSprite.hideAway("lookIntoYourSoul", true)
	action.emit_signal("done")

func _sort_by_low_hp(bp1: BattleParticipant, bp2: BattleParticipant):
	return bp1.partyInfo.HP < bp2.partyInfo.HP

func _darken_bg():
	$BGDarkinator/AnimationPlayer.play("darken")

func _undarken_bg():
	$BGDarkinator/AnimationPlayer.play("undarken")

func _start_joy_vibration(device := 0, weak_magnitude := 0.0, strong_magnitude := 0.0, duration := 0):
	global.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)

func _do_skill_with_screen_effect(action: SkillAction): # suspend func
	if _sound_effects.has(action.skill.useSound):
		$AudioStreamPlayer.stream = _sound_effects[action.skill.useSound]
		$AudioStreamPlayer.play()
	
	var started_effect := false
	if !action.user.get_type() == BattleParticipant.Type.ENEMY and action.skill.has("screenEffect"): 
		if $ScreenEffect/AnimationPlayer.has_animation(action.skill.screenEffect):
			$ScreenEffect/AnimationPlayer.play(action.skill.screenEffect)
			started_effect = true
	elif action.user.get_type() == BattleParticipant.Type.ENEMY and action.skill.has("enemyScreenEffect"):
		if $ScreenEffect/AnimationPlayer.has_animation(action.skill.enemyScreenEffect):
			$ScreenEffect/AnimationPlayer.play(action.skill.enemyScreenEffect)
			started_effect = true

	if started_effect:	
		_darken_bg()
		yield($ScreenEffect/AnimationPlayer, "animation_finished")
	_do_skill(action)
	if started_effect:
		_undarken_bg()

func _do_pre_hit_effect(target:BattleParticipant, effect): # suspend func
	if !effect or !$PreHitEffect/AnimationPlayer.has_animation(effect):
		yield(get_tree(), "idle_frame")
		return
	
	#this is the stupidist way to find our target's ui in the scene, but we living it up out here
	var targetPos = target.get_position(true)
	
	_darken_bg()
	$PreHitEffect/AnimationPlayer.play(effect)
	$PreHitEffect/AnimationPlayer.advance(0)
	$PreHitEffect.rect_position = targetPos - $PreHitEffect.rect_size/2
	yield($PreHitEffect/AnimationPlayer, "animation_finished")
	_undarken_bg()

func _do_hit_effect(hit_effect: String, hit_sound: String, target: BattleParticipant):
	if !hit_effect or !$HitEffect/AnimationPlayer.has_animation(hit_effect):
		return
	
	#this is the stupidist way to find our target's ui in the scene, but we living it up out here
	var targetPos = target.get_position(true)

	if _sound_effects.has(hit_sound):
		$AudioStreamPlayer.stream = _sound_effects[hit_sound]
	
	$HitEffect/AnimationPlayer.play(hit_effect)
	$HitEffect/AnimationPlayer.advance(0)
	$HitEffect.rect_position = targetPos - $HitEffect.rect_size/2

#mainly used for stat buffs/debuffs
func _do_hit_effect_by_anim(anim:String, target: BattleParticipant):
	if !$HitEffect/AnimationPlayer.has_animation(anim):
		return
	
	var targetPos = target.get_position()
	
	$HitEffect/AnimationPlayer.play(anim)
	$HitEffect/AnimationPlayer.advance(0)
	$HitEffect.rect_position = targetPos - $HitEffect.rect_size/2

func _do_guard(action: Action):
	action.user.defending = true
	if !is_connected("round_done", self, "_undo_guard"):
		connect("round_done", self, "_undo_guard", [], CONNECT_ONESHOT)
	action.emit_signal("done")

func _undo_guard(foo):
	for partyMember in _party_BPs:
		if partyMember.defending:
			partyMember.defending = false
			partyMember.battleSprite.hideAway()

func _do_item(action: Action): # suspend func
	if !action.user.isConscious():
		action.emit_signal("done")
		return
	yield(_retarget_action(action), "completed")
	var item = action.item
	for target in action.targets:
		if target.isConscious() and !action.targetUnconscious:
			if item.HPrecover > 0:
				_play_sfx("healHP", 1)
				_apply_restore_hp(target, item.HPrecover, action.targetUnconscious)
				var risingNum = _create_rising_num(str(item.HPrecover), target)
				risingNum.add_color_override("font_color", Color("00ee44"))
				risingNum.run()
			if item.PPrecover > 0:
				_play_sfx("healPP", 1)
				_apply_restore_pp(target, item.PPrecover, action.targetUnconscious)
				var risingNum = _create_rising_num(str(item.PPrecover), target)
				risingNum.add_color_override("font_color", Color.aqua)
				risingNum.run()
			if "status_heals" in item:
				_play_sfx("healstatus", 1)
				for status in item.status_heals:
					yield(_heal_status(status, target), "completed")
					if !_active:
						return
			yield(get_tree().create_timer(.15), "timeout")
			if !_active:
				return
	if action.user.get_type() == BattleParticipant.Type.PLAYABLE:
		action.user.battleSprite.hideAway()
	action.emit_signal("done")

func _apply_restore_hp(target: BattleParticipant, val: int, target_unconscious = false):
	if !target.isConscious() and !target_unconscious:
		return
	target.stats.hp += val
	target.stats.hp = min(target.stats.hp, target.get_stat("maxhp"))
	if target.get_type() == BattleParticipant.Type.PLAYABLE:
		target.partyInfo.setHP(target.stats.hp)

func _apply_restore_pp(target: BattleParticipant, val: int, target_unconscious = false):
	if !target.isConscious() and !target_unconscious:
		return
	target.stats.pp += val
	target.stats.pp = min(target.stats.pp, target.get_stat("maxpp"))
	if target.get_type() == BattleParticipant.Type.PLAYABLE:
		target.partyInfo.setPP(target.stats.pp)

func _apply_damage(target: BattleParticipant, val: int, intended_target: BattleParticipant = null): # suspend func
	if !target.isConscious():
		return
	var oldHP = target.stats.hp
	target.stats.hp -= val
	target.stats.hp = max(target.stats.hp, 0)
	match target.get_type():
		BattleParticipant.Type.PLAYABLE:
			target.partyInfo.setHP(target.stats.hp)
			if target.defending:
				_play_sfx("hurt2")
				target.battleSprite.play("guard")
				global.start_joy_vibration(0, 0.5, 0.5, 0.2)
			elif val > (1.0/16.0) * target.get_stat("maxhp"):
				global.start_joy_vibration(0, 0.8, 0.8, 0.3)
				_play_sfx("hurt2")
				target.battleSprite.bounceUpHit(min(val / (target.get_stat("maxhp") / 2), 3))
				
				target.partyInfo.quake(.1, 1.5)
			else:
				global.start_joy_vibration(0, 0.5, 0.5, 0.2)
				_play_sfx("hurt1")
				target.partyInfo.quake(.1)
				target.battleSprite.shake(val / (target.get_stat("maxhp") / 2))
			if target.stats.hp <= 0:
				_play_sfx("mortaldamage")
				global.start_joy_vibration(0, 1, 1, 0.4)
				if oldHP > 0:
					var dialog = _format_battle_text("BATTLE_MSG_MORTAL_DAMAGE", null, [target])
					yield($Dialoguebox.start_from_string(dialog), "completed")
		BattleParticipant.Type.ENEMY:
			if target.stats.hp == 0:
				# TODO Passive skill on enemy defeated?
				if target.stats.has("swansong"):
					var on_dying_skill = SkillAction.new(target)
					on_dying_skill.skill = globaldata.skills[target.stats.swansong]
					call_deferred("_start_action", on_dying_skill)
					yield(on_dying_skill, "done")
				target.defeat()
				if _show_intro_outro:
					yield(get_tree().create_timer(0.5), "timeout")
					var dialog = target.stats.get("outro_message", "{n0}{name} became tame!")
					yield($Dialoguebox.start_from_string(_format_battle_text(dialog, target)), "completed")
			else:
				target.battleSprite.hit()
		BattleParticipant.Type.NPC:
			if intended_target:
				$Dialoguebox.append(_format_battle_text("BATTLE_MSG_NPC_PROTECTION", target, [intended_target]), _sound_effects["hurt1"].resource_path)
			else:
				_play_sfx("hurt1")
			if target.stats.hp <= 0:
				target.defeat()
			yield($Dialoguebox.start_from_appended(), "completed")

func _drain_pp(target: BattleParticipant, drainer: BattleParticipant, val):
	if !target.isConscious():
		return
	#remove pp from target
	var oldPP = target.stats.pp
	target.stats.pp -= val
	target.stats.pp = max(target.stats.pp, 0)
	
	if target.get_type() == BattleParticipant.Type.PLAYABLE:
		target.partyInfo.setPP(target.stats.pp)
	#give pp to drainer
	if drainer != null:
		var difference = oldPP - target.stats.pp 
		if difference < 0:
			difference = 0
		drainer.stats.pp += difference
		_create_rising_num(difference, drainer)
	
		if drainer.get_type() == BattleParticipant.Type.PLAYABLE:
			drainer.partyInfo.setPP(drainer.stats.pp)

func _try_afflict_status(status: String, chance: float, target: BattleParticipant, status_skill:= false): # suspend func
	if !target.isConscious():
		yield(get_tree(), "idle_frame")
		return
	if !StatusManager.does_ailment_exist(status):
		push_warning("Invalid status effect !" + status + " skipping...")
		yield(get_tree(), "idle_frame")
		return

	chance *= target.get_vulnerab_multiplier(status)
	
	var r = randi() % 100 + 1
	if r <= chance:
		yield(_afflict_status(status, target, status_skill), "completed")
	else:
		yield(get_tree(), "idle_frame")
		return

func _afflict_status(status: String, target: BattleParticipant, status_skill:= false): # suspend func
	var info = StatusManager.get_ailment_info(status)
	if !StatusManager.does_ailment_exist(status):
		push_warning("Invalid status effect" + status + "skipping...")
		yield(get_tree(), "idle_frame")
		return
	if target.has_status(status) and info.get("ignore_reinflict", false):
		if status_skill:
			var dialog = _format_battle_text("jdksañfjskfdafkds", null, [target]) # It had no effect on [target]!
			yield($Dialoguebox.start_from_string(dialog), "completed")
			return
		else:
			yield(get_tree(), "idle_frame")
			return
	_play_sfx("statusafflicted")
	target.set_status(status, true)

	var dialogKey = StatusManager.get_status_message(status, "afflict_battle")
	var dialog = _format_battle_text(dialogKey, null, [target])
	yield($Dialoguebox.start_from_string(dialog), "completed")

func _heal_status(status: String, target: BattleParticipant): # suspend func
	if !StatusManager.does_ailment_exist(status):
		push_warning("Invalid status effect " + status + " skipping...")
		yield(get_tree(), "idle_frame")
		return
	if !target.has_status(status):
		yield(get_tree(), "idle_frame")
		return
	target.set_status(status, false)

	var dialogKey = StatusManager.get_status_message(status, "heal_battle")
	var dialog = _format_battle_text(dialogKey, null, [target])
	yield($Dialoguebox.start_from_string(dialog), "completed")

func _mod_stat(stat:String, amt:int, target: BattleParticipant): # suspend func
	var cur_stat_mod = target.get_stat_mod(stat)
	# Add smaller amount if it’s close to the limit
	if cur_stat_mod < 6 and cur_stat_mod + amt > 6:
		amt = 6 - cur_stat_mod
	elif cur_stat_mod > -6 and cur_stat_mod + amt < -6:
		amt = -6 - cur_stat_mod
	
	var dialog: String
	if abs(cur_stat_mod + amt) <= 6:
		var statRaise = amt * max(3, floor(target.get_base_stat(stat) * STAT_MOD_STEP))
		if sign(amt) > 0:
			_play_sfx("statup", 1)
			global.start_joy_vibration(0, 0.3, 0, 0.2)
			if stat in ["offense", "defense", "speed"]:
				_do_hit_effect_by_anim("stat_" + stat + "_up", target)
			dialog = _format_battle_text("BATTLE_MSG_STATS_UP", null, [target], null, statRaise, stat)
		elif sign(amt) < 0:
			_play_sfx("statdown", 1)
			global.start_joy_vibration(0, 0.3, 0, 0.2)
			if stat in ["offense", "defense", "speed"]:
				_do_hit_effect_by_anim("stat_" + stat + "_down", target)
			dialog = _format_battle_text("BATTLE_MSG_STATS_DOWN", null, [target], null, -statRaise, stat)
		target.add_stat_mod(stat, amt)
	elif cur_stat_mod + amt > 6:
		dialog = _format_battle_text("BATTLE_MSG_STATS_UP_MAX", null, [target], null, 0, stat)
			
	elif cur_stat_mod + amt <= -6:
		dialog = _format_battle_text("BATTLE_MSG_STATS_DOWN_MAX", null, [target], null, 0, stat)
	
	if dialog:
		yield($Dialoguebox.start_from_string(dialog), "completed")
	else:
		yield(get_tree(), "idle_frame")

func _sort_by_priority(a: Action, b: Action) -> bool:
	if a.priority > b.priority:
		return true
	# when in the same priority, speed matters
	elif a.priority == b.priority:
		return _sort_by_speed(a, b)
	else:
		return false

func _sort_by_speed(a: Action, b: Action) -> bool:
	if a.user.get_stat("speed") > b.user.get_stat("speed"):
		return true
	# we dont randomize if both speeds are the same, godot doesn't like that
	else:
		return false

func _create_rising_num(text: String, who: BattleParticipant, flyingNum := false) -> Label:
	var risingNum: Label
	if !flyingNum:
		risingNum = RisingNumTscn.instance()
	else:
		risingNum = FlyingNumTscn.instance()
	risingNum.text = text
	add_child(risingNum)
	var targetPos = who.get_position(true, true)
	targetPos -= risingNum.rect_size/2
	risingNum.rect_position = targetPos
	return risingNum

func _create_smash_attack(target: BattleParticipant) -> Sprite:
	$BGDarkinator/AnimationPlayer.play("smash")
	var smashAttack = SmashAttackTscn.instance()
	var targetPos = target.get_position(true, true)
	targetPos.y -= 32
#	targetPos -= smashAttack.rect_size/2
	smashAttack.position = targetPos
	return smashAttack

func _play_battle_sprite_anim(user: BattleParticipant, anim: String):
	if user.get_type() == BattleParticipant.Type.PLAYABLE:
		user.battleSprite.play(anim, true)

func _get_conscious_party(only_who_can_attack := false) -> Array:
	var arr = []
	for party_member in _party_BPs:
		if party_member.isConscious():
			if !only_who_can_attack or party_member.can_act():
				arr.append(party_member)
	return arr

func _get_conscious_enemies(only_who_can_attack := false) -> Array:
	var arr = []
	for enemy in _enemy_BPs:
		if enemy.isConscious():
			if !only_who_can_attack or enemy.can_act():
				arr.append(enemy)
		
	return arr

func _get_conscious_npcs(targetable_only := false) -> Array:
	var arr = []
	for npc in _npc_BPs:
		if npc.isConscious() and !npc.stats.get("untargetable", false):
			arr.append(npc)
	return arr

func _show_action_menu(is_battle_start := false):
	if !_show_intro_outro:
		$AnimAction.play("transitionIn")

func _show_enemy_sprites(): # suspend func
	for enemy in $Enemies.get_children():
#		$EnemyTransitions.get_child(0).queue_free()
		enemy.show()
		enemy.appear()
		yield(get_tree().create_timer(.1), "timeout")
	_enemies_shaking = false

func _check_player_defeated(partyMem: BattleParticipant):
	if _active and !_enemy_BPs.empty():
		if partyMem.partyInfo.HP == 0:
			if _doing_actions and _current_action.user.get_type() == BattleParticipant.Type.PLAYABLE and \
			   ($ScreenEffect/AnimationPlayer.is_playing() or $PreHitEffect/AnimationPlayer.is_playing()):
				_buffered_player_defeat.append(partyMem)
			else:
				partyMem.defeat()

func _revive_party():
	for i in global.party:
		i.status.clear()
		if i == global.party[0]:
			i.hp = i.maxhp
			i.pp = i.maxpp
		else:
			StatusManager.add_status(i, StatusManager.AILMENT_UNCONSCIOUS)
			i.pp = i.maxpp

func _remove_enemy_transitions(): # suspend func
	for enemy in $Enemies.get_children():
		$EnemyTransitions.get_child(0).queue_free()
		yield(get_tree().create_timer(.1), "timeout")

func _jump_to_battle(): # suspend func
	yield(get_tree().create_timer(.2), "timeout")
	for i in range($PlayerTransitions.get_child_count()):
		yield(get_tree().create_timer(.1), "timeout")
		_jump_player_to_partyinfo(i)
	yield(get_tree().create_timer(.2), "timeout")
	for i in range($NpcTransitions.get_child_count()):
		yield(get_tree().create_timer(.1), "timeout")
		_jump_npc_to_side(i)

func _jump_player_to_partyinfo(index: int):
	var sprite = $PlayerTransitions.get_child(index)
	var partyInfo = $PartyInfo.get_child(index)
	var tween = Tween.new()
	var jumpHeight = 0
	sprite.add_child(tween)
	if sprite.position.y >= 90:
		jumpHeight = sprite.position.y - 90
	tween.interpolate_property(sprite, "position:x", \
		sprite.position.x, partyInfo.rect_position.x + partyInfo.rect_size.x/2, 0.6, \
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(sprite, "position:y", \
		sprite.position.y, sprite.position.y - (16 + jumpHeight), 0.3, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.interpolate_property(sprite, "position:y", \
		sprite.position.y - (16 + jumpHeight), 180, 0.3, \
		Tween.TRANS_QUAD, Tween.EASE_IN, 0.3)
	tween.interpolate_property(sprite, "scale:x", \
		sprite.scale.x, 0.3, 0.3, \
		Tween.TRANS_QUART, Tween.EASE_IN, 0.3)
	tween.interpolate_property(sprite, "scale:y", \
		sprite.scale.y, 2, 0.3, \
		Tween.TRANS_QUART, Tween.EASE_IN, 0.3)
	tween.connect("tween_all_completed", partyInfo, "quake", [0, .5])
	tween.connect("tween_all_completed", sprite, "hide", [], CONNECT_DEFERRED)
	
	sprite.frame_coords = SPRITE_FRAMES.jump_down
	tween.start()

func _jump_npc_to_side(index: int):
	var sprite = $NpcTransitions.get_child(index)
	var tween = Tween.new()
	var jumpHeight = 0
	sprite.add_child(tween)
	if sprite.position.y >= 90:
		jumpHeight = sprite.position.y - 90
	tween.interpolate_property(sprite, "position:x", \
		sprite.position.x, 370, 0.6, \
		Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.interpolate_property(sprite, "position:y", \
		sprite.position.y, sprite.position.y - (42 + jumpHeight), 0.3, \
		Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.interpolate_property(sprite, "position:y", \
		sprite.position.y - (42 + jumpHeight), 90, 0.3, \
		Tween.TRANS_QUAD, Tween.EASE_IN, 0.3)
	tween.interpolate_property(sprite, "scale:x", \
		0.8, sprite.scale.x, 0.2, \
		Tween.TRANS_QUART, Tween.EASE_IN)
	tween.interpolate_property(sprite, "scale:y", \
		1.2, sprite.scale.y, 0.2, \
		Tween.TRANS_QUART, Tween.EASE_IN)
	#tween.connect("tween_all_completed", sprite, "hide", [], CONNECT_DEFERRED)
	
	sprite.frame_coords = SPRITE_FRAMES.jump_right
	tween.start()

func _enemy_to_position(): # suspend func
	_enemies_shaking = true
	for i in range($EnemyTransitions.get_child_count()):
		var sprite = $EnemyTransitions.get_child(i)
		var fullSprite = $Enemies.get_child(i)
		var tween = Tween.new()
		sprite.add_child(tween)
		tween.interpolate_property(sprite, "position", \
			sprite.position, fullSprite.rect_position + fullSprite.rect_size/2, 0.25, \
			Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.start()
		yield(get_tree().create_timer(0.2/$EnemyTransitions.get_child_count()), "timeout")
		tween.interpolate_property(sprite, "modulate",
			sprite.modulate, Color.black, 0.2,
			Tween.TRANS_LINEAR)
		tween.start()	

func _play_sfx(sfx_name: String, channel := 0):
	if !_sound_effects.has(sfx_name):
		return
	audioManager.play_sfx(_sound_effects[sfx_name], "BattleSfx" + str(channel))

func _give_exp(party_members: Array, amount: int): # suspend func
	for party_mem in party_members:
		party_mem.stats.exp += amount
		var in_progress = _check_level_up(party_mem)
		if in_progress: yield(in_progress, "completed")

func _give_cash():
	globaldata.earned_cash += _cash_pool
	globaldata.bank += _cash_pool
	globaldata.flags["earned_cash"] = true

func _check_level_up(party_mem: BattleParticipant): # suspend func
	# do level up, if enough exp!!
	var target_level: int = party_mem.stats.level
	while party_mem.stats.exp >= globaldata.get_exp_for_level(target_level + 1):
		target_level += 1
	if target_level > party_mem.stats.level:
		_level_up(party_mem, target_level)
	$Dialoguebox.start_from_appended()
	yield($Dialoguebox, "done")

func _level_up(party_mem: BattleParticipant, to_level: int): # suspend func
	if (!audioManager.overworldBattleMusic) or (_is_boss and audioManager.overworldBattleMusic):
		if !audioManager.get_playing(_musical_effects["lvlup"]):
			#audioManager.music_fadeout(audioManager.get_latest_audio_player_index(), 0.2)
			audioManager.pause_all_music()
			audioManager.add_audio_player()
			audioManager.play_music_on_latest_player("", _musical_effects["lvlup"])
		var startTime = audioManager.get_audio_player_from_song(_musical_effects["lvlup"]).get_playback_position()
		var partyMemLevelUp = _musical_effects["lvlup_" + party_mem.stats.name]
		if !audioManager.get_playing(partyMemLevelUp):
			audioManager.add_audio_player()
			audioManager.play_music_on_latest_player("", partyMemLevelUp, startTime)
	
	$Dialoguebox.append(_format_battle_text("BATTLE_MSG_LEVEL_UP", party_mem, [], null, to_level), "M3/Cheering.mp3")
	for stat in globaldata.player_stat_target_table[party_mem.stats.name]:
		var new_value := globaldata.get_stat_for_level(party_mem.stats.name, stat, to_level)
		var gain: int = new_value - party_mem.stats[stat]
		if gain > 0:
			party_mem.stats[stat] += gain
			# add the new dialog
			if stat == "maxhp":
				# let the numbers roll
				party_mem.partyInfo.maxHP = party_mem.get_stat("maxhp")
				# also update the current
				party_mem.partyInfo.setHP(party_mem.partyInfo.HP + gain)
				stat = "hp"
				party_mem.stats[stat] += gain
			elif stat == "maxpp":
				# let the numbers roll
				party_mem.partyInfo.maxPP = party_mem.get_stat("maxpp")
				# also update the current
				party_mem.partyInfo.setPP(party_mem.stats.pp + gain)
				stat = "pp"
				party_mem.stats[stat] += gain
			
			var stat_msg = _format_battle_text("BATTLE_MSG_LEVEL_UP_" + stat.to_upper(), party_mem, [], null, gain)
			$Dialoguebox.append(stat_msg)

	party_mem.stats.level = to_level

	# check skill table
	for level in to_level + 1:
		if globaldata.player_learn_skill_table[party_mem.stats.name].has(level):
			var newSkill = globaldata.player_learn_skill_table[party_mem.stats.name][level]
			if !globaldata[party_mem.stats.name].learnedSkills.has(newSkill):
				var flagTrue = true
				if globaldata.player_learn_skill_table_flags[party_mem.stats.name].has(newSkill):
					if !globaldata.flags[globaldata.player_learn_skill_table_flags[party_mem.stats.name][newSkill]]:
						flagTrue = false
				
				#secretely give the move to the party member if the flag is false
				if flagTrue:	
					var new_psi_msg = _format_battle_text("BATTLE_MSG_LEARNING", party_mem, [], globaldata.skills[newSkill])
					$Dialoguebox.append(new_psi_msg, "M3/Learned PSI.wav")
				globaldata[party_mem.stats.name].learnedSkills.append(newSkill)

func _hide_battle_BG():
	uiManager.remove_ui(_battle_bg)
	global.currentCamera.get_node("Tween").set_active(true)
	global.currentCamera.reset()

func _hide_enemies():
	$Enemies.hide()

func _drop_item_to_overworld(queued_dropped_items: Array): # suspend func
	yield(get_tree().create_timer(0.8), "timeout")
	var playerPos = global.persistPlayer.get_viewport().canvas_transform.xform(global.persistPlayer.position)
	for droppedItem in queued_dropped_items:
		var sprite = Sprite.new()
		var path := str("res://Graphics/Objects/Items/" + droppedItem.item + ".png")
		sprite.texture = load(path)
		sprite.position = playerPos - Vector2(0, 180)
		$EnemyTransitions.add_child(sprite)
		$Tween.interpolate_property(sprite, "position:y",
			sprite.position.y, playerPos.y, 1.3,
			Tween.TRANS_QUART, Tween.EASE_IN)
		$Tween.interpolate_property(sprite, "position:y", \
			playerPos.y, playerPos.y - 8, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT, 1.3)
		$Tween.interpolate_property(sprite, "position:y", \
			playerPos.y - 8, playerPos.y, 0.2, 
			Tween.TRANS_QUART, Tween.EASE_IN, 1.5)
		$Tween.start()
	yield($Tween, "tween_all_completed")
	for droppedItem in queued_dropped_items:
		droppedItem.position = global.persistPlayer.position
		var objectsLayer = global.persistPlayer.get_parent()
		if objectsLayer == null:
			global.currentScene.add_child(droppedItem)
		else:
			droppedItem.show()
			objectsLayer.add_child(droppedItem)
		droppedItem.disappear()
	
	for sprite in $EnemyTransitions.get_children():
		sprite.queue_free()

func _jump_to_overworld(): # suspend func
	if _lose_battle and uiManager.battleLoseCutscene != "":
		for i in _party_orig_objects.size():
			_party_orig_objects[i].show()
		_revive_party()
	else:
		_party_orig_positions.clear()
		for partyMem in _party_orig_objects:
			if is_instance_valid(partyMem):
				_party_orig_positions.append(partyMem.get_viewport().canvas_transform.xform(partyMem.position) - Vector2(0,4))
		_jump_npcs_to_overworld()
		for i in range($PlayerTransitions.get_child_count()):
			var sprite = $PlayerTransitions.get_child(i)
			var partyInfo = $PartyInfo.get_child(i)
			# set sprite back in position
			sprite.show()
			sprite.position = partyInfo.rect_global_position
			sprite.position.x += partyInfo.rect_size.x/2# - sprite.texture.get_width()/2
	#		sprite.position.y = 180
			sprite.scale = Vector2.ONE
			
			# do the tween stuff
			var tween = Tween.new()
			sprite.add_child(tween)
			tween.interpolate_property(sprite, "position:x", \
				sprite.position.x, _party_orig_positions[i].x, 0.55, \
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(sprite, "position:y", \
				sprite.position.y, _party_orig_positions[i].y - 24, 0.35, \
				Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property(sprite, "position:y", \
				_party_orig_positions[i].y - 24, _party_orig_positions[i].y + 4, 0.2, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.4)
			tween.interpolate_property(sprite, "scale:x", \
				0.6, 1, 0.4, \
				Tween.TRANS_QUAD, Tween.EASE_IN)
			tween.interpolate_property(sprite, "scale:y", \
				1.2, 1, 0.4, \
				Tween.TRANS_QUAD, Tween.EASE_IN)
			tween.interpolate_property(sprite, "scale:x", \
				1, 0.8, 0.2, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.4)
			tween.interpolate_property(sprite, "scale:y", \
				1, 1.1, 0.2, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.4)
			
			tween.connect("tween_all_completed", sprite, "hide", [])
			tween.connect("tween_all_completed", _party_orig_objects[i], "show", [])
			tween.connect("tween_all_completed", _party_orig_objects[i], "set_direction", [Vector2(0, -1)])
			tween.connect("tween_all_completed", _party_orig_objects[i].sprite, "set", ["frame_coords", SPRITE_FRAMES.crouch_up])
			
			if !_party_BPs[i].isConscious():
				pass
			
			sprite.frame_coords = SPRITE_FRAMES.jump_up
			tween.start()
			yield(get_tree().create_timer(.05), "timeout")

func _jump_npcs_to_overworld(): # suspend func
	for i in range($NpcTransitions.get_child_count()):
		var sprite = $NpcTransitions.get_child(i)
		# set sprite back in position
		sprite.show()
#		sprite.position.y = 180
		sprite.scale = Vector2.ONE

		var index_in_objects = i + global.party.size()
		var orig_object = _party_orig_objects[index_in_objects]
		
		if is_instance_valid(orig_object):
			var orig_position = _party_orig_positions[index_in_objects]
			var orig_position_prev = _party_orig_positions[index_in_objects - 1]
			
			# do the tween stuff
			var tween = Tween.new()
			sprite.add_child(tween)
			tween.interpolate_property(sprite, 
			"position:x", \
				sprite.position.x, orig_position.x, 0.55, \
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(sprite, "position:y", \
				sprite.position.y, orig_position_prev.y - 24, 0.35, \
				Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property(sprite, "position:y", \
				orig_position_prev.y - 24, orig_position.y + 4, 0.2, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.4)
			tween.interpolate_property(sprite, "scale:x", \
				0.6, 1, 0.3, \
				Tween.TRANS_QUAD, Tween.EASE_IN)
			tween.interpolate_property(sprite, "scale:y", \
				1.2, 1, 0.3, \
				Tween.TRANS_QUAD, Tween.EASE_IN)
			tween.interpolate_property(sprite, "scale:x", \
				1, 0.8, 0.1, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.5)
			tween.interpolate_property(sprite, "scale:y", \
				1, 1.1, 0.1, \
				Tween.TRANS_QUAD, Tween.EASE_IN, 0.5)
			
			tween.connect("tween_all_completed", sprite, "hide", [])
			tween.connect("tween_all_completed", orig_object, "show", [])
			tween.connect("tween_all_completed", orig_object, "set_direction", [Vector2(0, -1)])
			tween.connect("tween_all_completed", orig_object.sprite, "set", ["frame_coords", SPRITE_FRAMES.crouch_up])
			
			if !_npc_BPs[i].isConscious():
				pass
			
			sprite.frame_coords = SPRITE_FRAMES.jump_up
			tween.start()
			yield(get_tree().create_timer(.05), "timeout")

func _remove_battle_music():
	var winThemes = []

	for id in _musical_effects:
		winThemes.append(load("res://Audio/Music/" + _musical_effects[id]))

	for audioPlayer in audioManager.get_audio_player_list():
		if audioPlayer.stream in winThemes:
			audioManager.remove_audio_player(audioManager.get_audio_player_index(audioPlayer))
	if _music != "":
		if audioManager.get_playing("Battle Themes/" + _music):
			audioManager.remove_audio_player(audioManager.get_audio_player_index(audioManager.get_audio_player_from_song("Battle Themes/" + _music)))
		if _music_intro != "" and audioManager.get_playing("Battle Themes/" + _music_intro):
			audioManager.remove_audio_player(audioManager.get_audio_player_index(audioManager.get_audio_player_from_song("Battle Themes/" + _music_intro)))
	elif _is_boss and audioManager.overworldBattleMusic:
		for musicChanger in audioManager.musicChangers:
			musicChanger.stop_music_immediately()

func _turn_party_to_overworld():
	for bp in _party_BPs:
		bp.battleSprite.hideAway()

func _rotate_party_to_original_direction():
	for partyObj in _party_orig_objects:
		if is_instance_valid(partyObj):
			partyObj.rotate_to(_party_orig_dirs.pop_front(), .05)

func _courage_badge_swap(user: BattleParticipant): # suspend func
	InventoryManager.removeItemFromChar(user.stats.name, "CourageBadge")
	InventoryManager.addItem(user.stats.name, "FranklinBadge0.8")
	yield($Dialoguebox.start_from_string(tr("BATTLE_MSG_BADGE_REVEAL")), "completed")

func _reorganize_enemies(transition := true): # suspend func
	_buffer_reorganize = false
	# if there's a boss, we need a different pattern
	if _is_boss:
		# find the boss
		var bossEnemy
		for enemy in _enemy_BPs:
			if enemy.stats.get("boss") != null:
				if enemy.stats.boss:
					bossEnemy = enemy
					break
		
		# set it to the center
		# set enemies alternating, to the left/right
		var i = 0
		for enemyBP in _enemy_BPs:
			var battlesprite = enemyBP.battleSprite
			var position = Vector2(320/2, 147 )
	
	for i in range(_enemy_BPs.size()):
		# the ALGORITHm
		
		var battlesprite = _enemy_BPs[i].battleSprite
		var new_position = Vector2(320, 147)
		
		if !_enemy_BPs[i].stats.boss:
			var regEnemyCount = _enemy_BPs.size()
			var regEnemyIndex = i
			if _is_boss and _enemy_BPs.size() > 2:
				for j in range(_enemy_BPs.size()):
					if _enemy_BPs[j].stats.boss:
						regEnemyCount -= 1
						regEnemyIndex -= 1
			new_position.x /=  (regEnemyCount + 1)
			var topEnemyPosition = Vector2(new_position.x * (int(_enemy_BPs.size()/2.0) + 1), 147)
			var bottomEnemyPosition = Vector2(new_position.x, 147)
			new_position.x *= (regEnemyIndex + 1)
		
			var heightDifference = _get_y_curve_position(bottomEnemyPosition) - _get_y_curve_position(topEnemyPosition)
			new_position.y = _get_y_curve_position(new_position) - heightDifference/3
			if _is_boss:
				new_position.y -= 16
		else:
			new_position /= 2
			if _enemy_BPs.size() > 1:
				new_position.y += 16
		var texture_offset = battlesprite.rect_size / 2
#			var texture_offset = battlesprite.rect_size / 3
#			texture_offset.y += battlesprite.texture.get_height() /3
		new_position -= texture_offset
		
		# are we transitioning or naw?
		if transition:
			battlesprite.transitionTween.remove_all()
			battlesprite.transitionTween.interpolate_property(battlesprite, "rect_position", \
			battlesprite.rect_position, new_position, 0.4, \
			Tween.TRANS_EXPO, Tween.EASE_OUT)
			battlesprite.transitionTween.connect("tween_completed", self, \
			 "_on_reorganize_enemy_tween", [_enemy_BPs[i]], CONNECT_ONESHOT)
			battlesprite.transitionTween.start()
		else:
			battlesprite.rect_position = new_position
	if transition:
		# magic numbers, yet again! tsk tsk
		# the number is .2 seconds longer than the tween
		yield(get_tree().create_timer(.65), "timeout")
		_new_enemies.clear()
	else:
		yield(get_tree(), "idle_frame")
		return

func _get_y_curve_position(new_position: Vector2) -> float:
	var curve = 400 #The degree to which the enemies curve in a line, the smaller the number, the sharper the curve
	return new_position.y / 2 + pow((160 - new_position.x), 2) / (curve)

func _on_reorganize_enemy_tween(battlesprite, key, enemyBP: BattleParticipant):
	if enemyBP in _new_enemies:
		battlesprite.appear()

# Handle formatting of battlers, items and articles in battle text
# {name} is the actor's name, {target} is the target's name, {item} is the item name
# {n0}, {n1}, etc. are the articles for {name}
# {t0}, {t1}, etc. are the articles for the {target}
# {i0}, {i1}, etc. are the articles for the {item}
# {s0}, {s1}, etc. are the articles for {skill}
# {st0}, {st1}, etc. are the articles for {stat}
# {v0}, {v1}, etc. are the articles for {value}
# See list of articles (which also include pronouns and suffixes) in articles.txt
# Just use these tags in your strings this way and this method will format them
func _format_battle_text(text: String, actor: BattleParticipant = null, targets:Array=[], item_or_skill=null, value := 0, stat := "") -> String:
	var actor_name = actor.get_name() if actor else ""
	var actor_articles = TextTools.get_battler_articles(actor.stats, -1, actor.get_name()) if actor else []
	
	var item_or_skill_name = tr(item_or_skill.name) if item_or_skill else ""
	var item_or_skill_articles = TextTools.get_item_or_skill_articles(item_or_skill) if item_or_skill else []
	var skill_level = TextTools.get_skill_level(item_or_skill) if item_or_skill else ""
	var stat_name = TextTools.get_inline_stat_name(stat) if stat else ""
	var stat_articles = TextTools.get_inline_stat_articles(stat) if stat else []

	var target_name
	var target_articles
	if (targets.size() == 1):
		target_name = targets[0].get_name()
		target_articles = TextTools.get_battler_articles(targets[0].stats, -1, targets[0].get_name())
	elif (targets.size() > 1):
		# LOCALIZATION: If multiple targets, use "their", "the enemies", "Ninten's party" etc.
		if targets[0].get_type() == BattleParticipant.Type.ENEMY:
			target_name = "BATTLE_NAME_ENEMIES"
			target_articles = "BATTLE_NAME_ENEMIES_ART"
		else:
			target_name = "BATTLE_NAME_ALLIES"
			target_articles = "BATTLE_NAME_ALLIES_ART"
		target_name = _format_battle_text(target_name, null, [targets[0]])
		target_articles = Array(tr(target_articles).split(","))
		for i in target_articles.size():
			target_articles[i] = _format_battle_text(target_articles[i], null, [targets[0]])
	else:
		target_name = ""
		target_articles = []
		
	return tr(text).format({
		"name":tr(actor_name), 
		"target":target_name,
		"item":item_or_skill_name,
		"skill":item_or_skill_name,
		"skillLevel":skill_level,
		"stat":stat_name,
		"value":value,
		"wait":TextTools.CHAR_WAIT
		}).format(
			actor_articles, "{n_}"
		).format(
			target_articles, "{t_}"
		).format(
			item_or_skill_articles, "{i_}"
		).format(
			item_or_skill_articles, "{s_}"
		).format(
			stat_articles, "{st_}"
		).format(
			TextTools.get_number_articles(value), "{v_}"
		)

func _try_flee(action: Action): # suspend func
	_fleeing_attempts += 1
	if _player_adv:
		print("Fleeing thanks to player advantage")
		_flee()
	elif _fleeing_attempts >= FLEEING_MAX_ATTEMPTS:
		print("Fleeing after %s attempts" % FLEEING_MAX_ATTEMPTS)
		_flee()
	else:
		var chances_multiplier = 1

		var max_enemy_speed = 0
		for enemyBP in _get_conscious_enemies(true):
			max_enemy_speed = max(max_enemy_speed, enemyBP.get_stat("speed"))
			chances_multiplier *= enemyBP.get_vulnerab_multiplier("flee")
		
		var party_speed = 0
		for partyBP in _get_conscious_party(true):
			party_speed = max(party_speed, partyBP.get_stat("speed"))
			chances_multiplier *= partyBP.get_vulnerab_multiplier("flee")

		var chance = (FLEEING_CHANCES_BASE * chances_multiplier) + (party_speed - max_enemy_speed) + (_turns_count * FLEEING_CHANCES_INCREASE)
		print("Flee chance: %s" % chance)
		var r = randi() % 100 + 1
		if r < chance:
			_flee()
		else :
			yield($Dialoguebox.start_from_string(tr("BATTLE_MSG_FLEE_FAILED")), "completed")
			action.emit_signal("done")
