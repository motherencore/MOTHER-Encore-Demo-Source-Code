extends CanvasLayer

#Other Scripts
#const Action = preload("res://Scripts/UI/Battle/Action.gd")
const BattleParticipant = preload("res://Scripts/UI/Battle/BattleParticpant.gd")

# HitNumber tscns
const risingNumTscn = preload("res://Nodes/Ui/Battle/RisingNumber.tscn")
const flyingNumTscn = preload("res://Nodes/Ui/Battle/FlyingNumber.tscn")
const smashAttackTscn = preload("res://Nodes/Ui/Battle/Smash.tscn")

# Item/Skill Pages

# Party Member Sprites
var statusBubbleTscn = preload("res://Nodes/Ui/Battle/StatusBubble.tscn")
var partyInfoTscn = preload("res://Nodes/Ui/Battle/PartyInfoPlate.tscn")
var defaultBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpriteDefault.tscn")
var nintenBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpriteNinten.tscn")
var lloydBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpriteLloyd.tscn")
var anaBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpriteAna.tscn")
var pippiBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpritePippi.tscn")
var teddyBattleSprite = preload("res://Nodes/Ui/Battle/BattleSpriteTeddy.tscn")

# Enemies
var enemySprite := preload("res://Nodes/Ui/Battle/EnemySprite.tscn")

# sfx
var soundEffects = {
	#encounter sounds
	"encounter": load("res://Audio/Sound effects/Battle Encounter/Encounter Enemy.mp3"),
	"playeradv": load("res://Audio/Sound effects/Battle Encounter/Encounter Player Advantage.mp3"),
	"enemyadv": load("res://Audio/Sound effects/Battle Encounter/Encounter Enemy Advantage.mp3"),
	"bossencounter": load("res://Audio/Sound effects/Battle Encounter/Encounter Boss.mp3"),
	#cursors
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"cursor2": load("res://Audio/Sound effects/Cursor 2.mp3"),
	"back": load("res://Audio/Sound effects/M3/curshoriz.wav"),
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
	
	#winning
	"cheering": load("res://Audio/Sound effects/M3/Cheering.mp3")
}


const gameover = preload("res://Nodes/Ui/GameOver.tscn")
const droppedItemNode = preload("res://Nodes/Overworld/Objects/Item.tscn")

#we do love hacky stuff out here
const enemyRename = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

# Classes
class Action extends Object:
	var user
	var priority = 0
	var targetType = TargetType.SELF
	signal done
	
	func _init(_user):
		user = _user

class SkillAction extends Action:
	var skill = {} setget setSkill
	var targets = []
	func _init(_user).(_user):
		pass
	
	func setSkill(newVal):
		if newVal.has("priority"):
			priority = newVal.priority
		if newVal.has("targetType"):
			targetType = newVal.targetType
		skill = newVal

class ItemAction extends SkillAction:
	var item = {} setget setItem
	var inv_idx = -1
	func _init(_user).(_user):
		pass
	
	func setItem(newVal):
		item = newVal
		if "battle_action" in item and item.battle_action != "":
			setSkill(globaldata.skills[item.battle_action])
		else:
			if newVal.has("action_one"):
				if newVal.action_one.has("targetType"):
					targetType = newVal.action_one.targetType
				else:
					targetType = TargetType.ALLY
			else:
				targetType = TargetType.ALLY
		if item.has("priority"):
			priority = item.priority
		

class GuardAction extends Action:
	func _init(_user).(_user):
		priority = 3

class FleeAction extends Action:
	func _init(_user).(_user):
		priority = 0

# enums
enum DamageType {DAMAGE, HEALING, NONE}
enum TargetType {ENEMY, ALLY, ANY, RANDOM_ENEMY, RANDOM_ALLY, SELF, ALL_ENEMIES, ALL_ALLIES}
enum menuPages {BATTLE = -1, ACTIONS, SPECIAL, ITEMS, TARGETS}

# Everyone in battle!
var battleParticipants := []
var partyBPs := []
var npcBPs := []
var enemyBPs := []


var loseBattle = false


# UI Cursor/ Menus
var menuPageStack := []
var cursorLocStack := []

# For PSI/SPECIAL Page
var skillPage = 0
var skillsPerPage = 3

# For ITEM Page
const itemPageSize = Vector2(2, 5)
var itemPageYOffset = 0

var selectedSkill := ""
var actionQueue := []
#var loadedItems := {}
var currPartyMem : int = -1

# page -1 (BATTLE) is used for when the actionQueue is actually being played out.
var cursorActive := true
var cursorLoc := Vector2(0,0)
var maxCursorLoc := Vector2(5,0)

var actionCursorHomePos := Vector2(5,3)

# battle data stuff
var stat_mod_step := 1/8

# for battle win stuff
var expPool = 0
var cashPool = 0
# an array of item name and drop chances
var itemPool = []
var queuedDroppedItems = []

# for prebattle transition
var enemiesShaking = false
var shakeTime = 0
var shakeFreq = 0.06

var battleBG
var musicIntro = ""
var music = ""

var partyOriginalPositions = []
var partyOriginalDirections = []

# when the battle is inactive, we stop taking input
var active = true
# for when actions are being done
var doingActions = false
var currentAction = null

# know if it's a boss encounter
var boss = false
var canRun = true

var playerAdv = false
var enemyAdv = false

var bufferedPlayerDefeat = []
var bufferReorganize = false
var newEnemies = []

var turn = 1

signal actionDone
signal roundDone
signal levelUpDone

func _init():
	randomize()
	for partyMember in global.party:
		add_party_member(partyMember, null)
	for partyNpc in global.partyNpcs:
		add_party_npc(partyNpc, null)
	for partyObj in global.partyObjects:
		var dir = Vector2.RIGHT
		if "direction" in partyObj:
			dir = partyObj.direction
		elif "input_vector" in partyObj:
			dir = partyObj.input_vector
		partyOriginalDirections.append(dir)
	
	global.inBattle = true

func _ready():
	add_party_info_plates()
	for i in range(enemyBPs.size()):
		add_enemy_battlesprite(enemyBPs[i])
	reorganize_enemies(false)
	add_players_sprites()
	$ActionMenuBox.connect("next", self, "action_selected")
	# when we know who up first, we want to change the icons accordingly
	add_actions_to_menu(get_conscious_party().front())
	$TargetsBox.partyBPs = partyBPs
	$TargetsBox.enemyBPs = enemyBPs

	$AnimationPlayer.play("transitionIn")
	$AnimationPlayer.connect("animation_finished", self, "start", [], CONNECT_ONESHOT)
	if music != "":
		audioManager.pause_all_music()
	for enemy in enemyBPs:
		if enemy["stats"].has("boss"):
			if enemy["stats"]["boss"] == true:
				boss = true
	if boss:
		$AudioStreamPlayer.stream = soundEffects["bossencounter"]
	elif playerAdv:
		$AudioStreamPlayer.stream = soundEffects["playeradv"]
	elif enemyAdv:
		$AudioStreamPlayer.stream = soundEffects["enemyadv"]
	else:
		$AudioStreamPlayer.stream = soundEffects["encounter"]
	
	$AudioStreamPlayer.play()
	
	if enemyAdv:
		$ActionMenuBox/Arrow.on = false
		$ActionMenuBox.hide()
		$InfoBox1.hide()

func start(anim = ""):
	# Enter "Actions" menu page
	if music != "":
		var intro = ""
		if musicIntro != "":
			intro = "Battle Themes/" + musicIntro
		audioManager.add_audio_player()
		audioManager.play_music_from_id(intro, "Battle Themes/" + music, audioManager.get_audio_player_count() - 1)
	if enemyAdv:
		currPartyMem = partyBPs.size()
		enemyAdv = false
	
	# activate statuses if there are any
	for partyBP in partyBPs:
		for status in partyBP.stats.status:
			do_status(partyBP, status, true)
			if partyBP.statusBubble:
				print("add ", globaldata.status_enum_to_name(status))
				partyBP.statusBubble.add_status(status)
	next_active_menu()

func _input(event):
	if !active or doingActions:
		return
	
	if OS.is_debug_build():
		# debug win battle instantly
		if event.is_action_pressed("ui_end") and $ActionMenuBox.cursor.on:
			$ActionMenuBox.hide()
			$InfoBox1.hide()
			var enemyArr = enemyBPs.duplicate()
			for enemyBP in enemyArr:
				enemyBP.defeat()
				enemyBPs.erase(enemyBP)
			play_sfx("enemydefeated")
			win()
	
	if (Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_toggle")) and currentAction == null:
		get_tree().set_input_as_handled()
		if leave_menu():
			play_sfx("back")

func goto_menu(menu, action = null):
	if !menuPageStack.empty():
		menuPageStack.back().hide()
	menu.enter(true, action)
	menuPageStack.push_back(menu)

# returns true if anything acutally happens
func leave_menu():
	if menuPageStack.size() > 1:
		menuPageStack.pop_back().exit()
		menuPageStack.back().enter()
		return true
	elif currPartyMem > 0 and currPartyMem < get_conscious_party().size():
		prev_active_menu()
		return true
	return false

# When an action is selected, we start an Action object that will be
# assembly-lined through menus
 
# When the last menu is completed, the Action object is then saved, and we move
# on to the next player
func action_selected(actionName):
	disconnect_menus()
	match(actionName):
		"Bash":
			var skillAction = SkillAction.new(partyBPs[currPartyMem])
			skillAction.skill = globaldata.skills["attack"]
			$TargetsBox.connect("next", self, "cache_player_action", [skillAction])
			goto_menu($TargetsBox, skillAction)
		"PSI":
			var skillAction = SkillAction.new(partyBPs[currPartyMem])
			$PSIBox.connect("next", self, "goto_menu", [$TargetsBox, skillAction])
			$TargetsBox.connect("next", self, "cache_player_action", [skillAction])
			goto_menu($PSIBox, skillAction)
		"Skills":
			var skillAction = SkillAction.new(partyBPs[currPartyMem])
			$SkillsBox.connect("next", self, "goto_menu", [$TargetsBox, skillAction])
			$TargetsBox.connect("next", self, "cache_player_action", [skillAction])
			goto_menu($SkillsBox, skillAction)
		"Items":
			var itemAction = ItemAction.new(partyBPs[currPartyMem])
			$ItemsBox.connect("next", self, "goto_menu", [$TargetsBox, itemAction])
			$TargetsBox.connect("next", self, "cache_player_action", [itemAction])
			goto_menu($ItemsBox, itemAction)
		"Defend":
			cache_player_action(GuardAction.new(partyBPs[currPartyMem]))
		"Run":
			cache_player_action(FleeAction.new(partyBPs[currPartyMem]))
		_:
			pass

func disconnect_menus():
	for connection in $TargetsBox.get_signal_connection_list("next"):
		$TargetsBox.disconnect(connection.signal, connection.target, connection.method)
	for connection in $PSIBox.get_signal_connection_list("next"):
		$PSIBox.disconnect(connection.signal, connection.target, connection.method)
	for connection in $SkillsBox.get_signal_connection_list("next"):
		$SkillsBox.disconnect(connection.signal, connection.target, connection.method)
	for connection in $ItemsBox.get_signal_connection_list("next"):
		$ItemsBox.disconnect(connection.signal, connection.target, connection.method)

func add_actions_to_menu(bp):
	$ActionMenuBox.resetActions()
	match(bp.stats.name):
		"ninten":
			if globaldata.ninten.learnedSkills != []:
				if bp.stats.equipment.weapon.begins_with("Bat") and globaldata.flags["bat"] and globaldata.ninten.learnedSkills.has("curveball"):
					$ActionMenuBox.addActions(["Skills", "PSI"])
				else:
					$ActionMenuBox.addActions(["PSI"])
		"lloyd":
			$ActionMenuBox.addActions(["Skills"])
		"ana":
			$ActionMenuBox.addActions(["PSI"])
	if bp.hasStatus(globaldata.ailments.Numb):
		$ActionMenuBox.addUnselectableActions(["Bash", "Skills", "Items"])
	if canRun or uiManager.battleFleeCutscene != "":
		$ActionMenuBox.addAction("Run")

func _physics_process(delta):
	if enemiesShaking:
		shakeTime += delta
		if shakeTime > shakeFreq:
			shakeTime -= shakeFreq
			for overworldSprite in $EnemyTransitions.get_children():
				overworldSprite.offset.x = rand_range(-4.0,4.0)
				overworldSprite.offset.y = rand_range(-4.0,4.0)

func add_party_member(stats, battlesprite):
	var bp = BattleParticipant.new()
	bp.stats = stats
	bp.id = battleParticipants.size()
	#look at ninten's equip inv for bat
	if bp.stats.name in ["ninten", "pippi"]:
		if "Bat" in bp.stats.equipment.weapon:
			bp.bashAnim = "bat"
		elif "Slingshot" in bp.stats.equipment.weapon:
			bp.bashAnim = "slingshot"
	for item in InventoryManager.Inventories[bp.stats.name]:
		var item_data = InventoryManager.Load_item_data(item.ItemName)
		if item_data.has("slot"):
			if item_data.slot == "" and item_data.has("passive_skills"):
				for passiveSkill in item_data.passive_skills:
					if !passiveSkill in bp.stats.passiveSkills:
						bp.stats.passiveSkills.append(passiveSkill)
	battleParticipants.append(bp)
	partyBPs.append(bp)

func add_party_npc(stats, battlesprite):
	var bp = BattleParticipant.new()
	bp.stats = stats
	bp.id = battleParticipants.size()
	npcBPs.append(bp)

func get_alive_targets_from_type(user, targetType):
	var targets = []
	var friendlies = get_conscious_party()
	var enemies = get_conscious_enemies()
	if user.isEnemy:
		friendlies = get_conscious_enemies()
		enemies = get_conscious_party()
	if user.stats.status.has(globaldata.ailments.Confused):
		if int(targetType) in [TargetType.RANDOM_ALLY, TargetType.ALLY, TargetType.RANDOM_ENEMY, TargetType.ENEMY]:
			targetType = TargetType.ANY
		elif targetType == TargetType.ALL_ENEMIES or targetType == TargetType.ALL_ALLIES:
			if (randi()%2+0) == 1:
				targetType = TargetType.ALL_ENEMIES
			else:
				targetType = TargetType.ALL_ALLIES
	match(int(targetType)):
		TargetType.ANY:
			# decide random!
			var all = []
			all.append_array(friendlies)
			all.append_array(enemies)
			var random = all[randi() % all.size()]
			targets.append(random)
		TargetType.ALL_ENEMIES:
			targets = enemies
		TargetType.RANDOM_ENEMY:
			continue
		TargetType.ENEMY:
			targets = [enemies[randi() % enemies.size()]]
		TargetType.ALL_ALLIES:
			targets = friendlies
		TargetType.RANDOM_ALLY:
			continue
		TargetType.ALLY:
			targets = [friendlies[randi() % friendlies.size()]]
		TargetType.SELF:
			targets = [user]
	return targets

func reset_page_stack():
	for page in range(menuPageStack.size()):
		menuPageStack.pop_back().exit()

func cache_player_action(action: Action):
	if action is GuardAction:
		action.user.battleSprite.play("guardPrep")
	elif action is ItemAction:
		action.user.battleSprite.play("itemPrep")
	elif action is SkillAction:
		if action.skill.name == "Bash" || (action.skill.has("skillType") and action.skill.skillType == "physical"):
			action.user.battleSprite.play(action.user.bashAnim + "Prep")
		else:
			action.user.battleSprite.play("psiPrep")
	
	cache_action(action)
	reset_page_stack()
	next_active_menu()

func tilt_bars(position):
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

func next_active_menu():
	#next player turn
	currPartyMem += 1
	#cycle through party members until we reach next concious party member
	while currPartyMem < partyBPs.size() and ( \
			!partyBPs[currPartyMem].isConscious() \
			or partyBPs[currPartyMem].hasStatus(globaldata.ailments.Sleeping)):
		currPartyMem += 1
	
	# when there is no party members left, start battle
	if currPartyMem >= partyBPs.size():
		if !playerAdv:
			cache_enemy_actions()
			yield(get_tree().create_timer(.3), "timeout")
		else:
			playerAdv = false
		do_actions()
	else:
		partyBPs[currPartyMem].battleSprite.showAndPlay("idle")
		add_actions_to_menu(partyBPs[currPartyMem])
		goto_menu($ActionMenuBox)

func prev_active_menu():
	actionQueue.pop_back()
	reset_page_stack()
	partyBPs[currPartyMem].battleSprite.hideAway()
	currPartyMem -= 1
	
	partyBPs[currPartyMem].battleSprite.play("idle", true)
	add_actions_to_menu(partyBPs[currPartyMem])
	goto_menu($ActionMenuBox)

func cache_action(action):
	actionQueue.append(action)

func add_party_info_plates():
	var partySize : int = partyBPs.size()
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
		var plate = partyInfoTscn.instance()
		plate.pName = partyBPs[i].stats.nickname
		plate.maxHP = partyBPs[i].get_stat("maxhp")
		plate.maxPP = partyBPs[i].get_stat("maxpp")
		$PartyInfo.add_child(plate)
		if partyBPs[i].stats.status.has(globaldata.ailments.Poisoned):
			plate.set_poisoned()
		plate.setHP(partyBPs[i].stats.hp, true)
		plate.setPP(partyBPs[i].stats.pp, true)
		plate.rect_position.x = firstPlacementX + (plateSize.x * i)
		plate.rect_position.y = 20
		plate.connect("hp_scroll_done", self, "check_player_defeated", [partyBPs[i]])
		plate.connect("hp_scroll_done", partyBPs[i], "hp_stopped_scrolling")
		plate.connect("pp_scroll_done", partyBPs[i], "pp_stopped_scrolling")
		partyBPs[i].partyInfo = plate
		
		var battleSprite
		match(partyBPs[i].stats.name):
			"ninten":
				battleSprite = nintenBattleSprite.instance()
			"lloyd":
				battleSprite = lloydBattleSprite.instance()
			"ana":
				battleSprite = anaBattleSprite.instance()
			"pippi":
				battleSprite = pippiBattleSprite.instance()
			"teddy":
				battleSprite = teddyBattleSprite.instance()
			_:
				battleSprite = defaultBattleSprite.instance()
		plate.add_child(battleSprite)
		partyBPs[i].battleSprite = battleSprite
		
		var statusBubble = statusBubbleTscn.instance()
		battleSprite.add_child(statusBubble)
		statusBubble.rect_position.x = battleSprite.rect_size.x/2
		statusBubble.rect_position.y += 16 #magic numbers, tsk tsk roka....
		partyBPs[i].statusBubble = statusBubble
		if !partyBPs[i].isConscious():
			partyBPs[i].defeat()

func add_enemy_battlesprite(enemyBP, transition = true):
	var spritePathP1 := "res://Graphics/Battle Sprites/"
	var spritePathP2 := ".png"
	var fullSpritePath : String = spritePathP1 + enemyBP.stats.sprite + spritePathP2
	var spriteExists := ResourceLoader.exists(fullSpritePath)
	var texture = enemySprite.instance()
	if spriteExists:
		texture.texture = load(fullSpritePath)
	else:
		print("could not load sprite: ", fullSpritePath)
		texture.texture = load(spritePathP1 + "invalidsprite.png")
	
	enemyBP.battleSprite = texture
	$Enemies.add_child(texture)
	# put texture off screen
	texture.rect_position = Vector2(320, 0) + texture.texture.get_size()
	texture.hide()
	var statusBubble = statusBubbleTscn.instance()
	texture.add_child(statusBubble)
	statusBubble.rect_position.x = texture.rect_size.x/2
	statusBubble.rect_position.y += 24 - texture.rect_size.y / 2 #magic numbers, tsk tsk roka....
	enemyBP.statusBubble = statusBubble

func flee():
	active = false
	for bp in partyBPs:
		if bp.isConscious() and bp.partyInfo.HP <= bp.partyInfo.get_current_HP():
			bp.partyInfo.stopScrolling()
	for onScreenEnemy in uiManager.onScreenEnemies:
		onScreenEnemy[1].activate()
	for enemy in enemyBPs:
		if enemy != null:
			if enemy.overworldObj != null:
				if enemy.overworldObj.has_method("stun"):
					enemy.overworldObj.stun()
					enemy.overworldObj.get_node("interact/CollisionShape2D").set_deferred("disabled", false)
					enemy.overworldObj.flash(3, 0.2, 0, true)
	#temp functionality
	end_battle(uiManager.battleFleeCutscene)

func win():
	active = false
	for onScreenEnemy in uiManager.onScreenEnemies:
		onScreenEnemy[1].activate()
	
	if (!audioManager.overworldBattleMusic) or (boss and audioManager.overworldBattleMusic):
		audioManager.pause_all_music()
		audioManager.add_audio_player()
		audioManager.play_music_from_id("You Win/YOUWON.mp3", "You Win/Victory.mp3", audioManager.get_audio_player_count()-1)
	
	#play_sfx("res://Audio/Sound effects/EB/wow.wav")
	
	#stop rolling hp
	# show player battle sprites + victory animation
	for bp in partyBPs:
		if bp.isConscious():
			if bp.partyInfo.HP <= bp.partyInfo.get_current_HP():
				bp.partyInfo.stopScrolling()
			bp.reset_all_stat_mods()
			# heal all non persistent ailments
			var status_to_remove = bp.stats.status.duplicate()
			for status in status_to_remove:
				if !status in globaldata.persistentAilments: 
					do_status(bp, status, false)
					bp.setStatus(status, false)
			if !bp.battleSprite.shown:
				bp.battleSprite.showIn()
			bp.battleSprite.play("victory", true)
			# save off stats to globaldata
#			for partyMem in global.party:
#				partyMem.stats = bp.stats
			
	
	connect("levelUpDone", self, "do_rewards", [], CONNECT_ONESHOT)
	
	$Dialoguebox.playWin()
	yield(get_tree().create_timer(3), "timeout")
	#text box
	var receiving = 0
	var receiving_party = []
	for i in partyBPs.size():
		if partyBPs[i].isConscious() and partyBPs[i].stats.level < globaldata.levelCap:
			receiving += 1
			receiving_party.append(partyBPs[i])
	
	var dialog = {}
	if receiving > 1:
		if receiving_party.size() == 2:
			dialog = {
				"0": {"text":  receiving_party[0].stats.nickname + " and " + receiving_party[1].stats.nickname + " gained " + str(int(round(expPool / receiving))) + " exp each."}
			}
		else:
			dialog = {
				"0": {"text": receiving_party[0].stats.nickname + " and " + receiving_party[0].stats.pronoun +" friends gained " + str(int(round(expPool / receiving))) + " exp each."}
			}
	elif receiving > 0:
		dialog = {
			"0": {"text": receiving_party[0].stats.nickname + " gained " + str(expPool) + " exp."}
		}
	else:
		match get_conscious_party().size():
			1:
				dialog = {
					"0": {"text": get_conscious_party()[0].stats.nickname + " gained 0 exp."}
				}
			2:
				dialog = {
					"0": {"text":  get_conscious_party()[0].stats.nickname + " and " + get_conscious_party()[1].stats.nickname + " gained 0 exp each."}
				}
			_:
				dialog = {
					"0": {"text": receiving_party[0].stats.nickname + " and " + receiving_party[0].stats.pronoun +" friends gained 0 exp each."}
				}
	$Dialoguebox.autoAdvanced = false
	$Dialoguebox.start(dialog)
	yield($Dialoguebox, "done")
	give_exp(0)
	give_cash()
	globaldata.flags["earned_cash"] = true

func do_rewards():
	# do we get an item???
	var droppedItem = ""
	var j = 0
	var dialog = {}
	var itemGiven = false
	for itemStat in itemPool:
		for item in itemStat.items:
			var r = randi() % 100 + 1
			if r <= item.chance:
				itemGiven = true
				droppedItem = item.item
				var itemName = InventoryManager.Load_item_data(droppedItem).name.english
				var itemArticle = InventoryManager.Load_item_data(droppedItem).article.english
				dialog[str(j)] = {"text": "The enemy dropped a present!", "goto": "%s" % (j + 1)}
				dialog[str(j + 1)] = {"text": "Inside, the present, there was " + itemArticle + " " + itemName + ".", "goto": "%s" % (j + 2)}
				j += 2
				#who has room in their inventory?
				var itemGet = false
				for partyMem in partyBPs:
					if !InventoryManager.isInventoryFull(partyMem.stats.name):
						if partyMem.isConscious():
							dialog[str(j)] = {
								"text": "%s took it." % partyMem.stats.nickname,
								"goto": "%s" % (j + 1),
								"soundeffect": "EB/itemget1.wav"
							}
							j += 1
						else:
							dialog[str(j)] = {
								"text": "The item was put inside %s's bag." % partyMem.stats.nickname,
								"goto": "%s" % (j + 1),
								"soundeffect": "EB/itemget1.wav"
							}
							j += 1
						InventoryManager.addItem(partyMem.stats.name, droppedItem)
						itemGet = true
						break
				#does it get dropped??
				if !itemGet:
					dialog[str(j)] = {"text": "But you can't carry any more stuff...", "goto": "%s" % (j + 1)}
					j += 1
					var dropItem = droppedItemNode.instance()
					# yo, I heard you like items, so I set an item to your item item
					dropItem.item = item.item
					queuedDroppedItems.append(dropItem)
#					if itemStat.overworld != null:
#						itemStat.overworld.queued_item = item.item
				break
		if itemGiven:
			break
	
	if uiManager.battleWinFlag != "" and globaldata.flags.has(uiManager.battleWinFlag):
		globaldata.flags[uiManager.battleWinFlag] = true
	
	if droppedItem != "":
		# remove last "goto"
		dialog[str(j-1)].erase("goto") 
		$Dialoguebox.connect("done", self, "end_battle", [uiManager.battleWinCutscene], CONNECT_ONESHOT)
		$Dialoguebox.start(dialog)
	else:
		end_battle(uiManager.battleWinCutscene)
	

func lose():
	reset_page_stack()
	active = false
	$ActionMenuBox.hide()
	$InfoBox1.hide()
	remove_battle_music()
	audioManager.pause_all_music()
	
	
	
	if !$Dialoguebox.finished:
		yield($Dialoguebox, "done")
	else:
		yield(get_tree().create_timer(0.5), "timeout")
	play_sfx("partylose")
	var dialog = {}
	dialog = {
		"0":{"text": "The party was defeated..."}
		}
	$Dialoguebox.start(dialog)
	yield($Dialoguebox, "done")
	var gameOver = gameover.instance()
	uiManager.add_ui(gameOver)
	yield(gameOver, "fade_done")
	#set up return TEMP
	for obj in global.partyObjects:
		obj.show()
	hide_battle_BG()
	global.inBattle = false
	uiManager.remove_ui(self)


func end_battle(cutscene = ""):
	$Dialoguebox.hide()
	$ActionMenuBox.hide()
	$InfoBox1.hide()
	if (!audioManager.overworldBattleMusic) or (boss and audioManager.overworldBattleMusic):
		#remove victory and level up tracks
		remove_battle_music()
		
		
		#resume overworld music
		if audioManager.get_audio_player(0) != null:
			if audioManager.get_audio_player(0).stream_paused:
				audioManager.music_fadein(0, audioManager.get_audio_player(0).volume_db, 3)
	
	audioManager.resume_all_music()
	$AnimationPlayer.play("transitionOut")
	drop_item_to_overworld()
	yield($AnimationPlayer, "animation_finished")
		
	# release player or play cutscene
	global.inBattle = false
	uiManager.remove_ui(self)
	if cutscene != "":
		global.set_dialog(cutscene, null)
		uiManager.open_dialogue_box()
	else:
		global.persistPlayer.unpause()
	uiManager.reset_battle_cutscenes()

func load_enemy(enemy: String) -> Dictionary:
	var file = File.new();
	var json = "res://Data/Battlers/" + enemy + ".json"
	var enemyData : Dictionary
	if file.file_exists(json):
		file.open(json, File.READ);
		enemyData = parse_json(file.get_as_text())
		file.close()
	else:
		print("could not load json: ", json)
		file.open("res://Data/Battlers/testenemy.json", File.READ)
		enemyData = parse_json(file.get_as_text())
		file.close()
	return enemyData

func add_enemy(enemyName, overworld_object):
	var newEnemyStats = load_enemy(enemyName)
	var newEnemy = BattleParticipant.new()
	newEnemy.id = battleParticipants.size()
	newEnemy.isEnemy = true
	# only matters for enemies
	newEnemy.filename = enemyName
	newEnemy.stats = newEnemyStats
	newEnemy.stats.boosts = {
		"maxhp": 0,
		"maxpp": 0,
		"offense": 0,
		"defense": 0,
		"iq": 0,
		"guts": 0,
		"speed": 0
	}
	# set a nickname! ! look through enemies to check if we need a unique one
	newEnemy.stats.nickname = newEnemy.stats.name
	if newEnemy.stats.nickname == "Pippi":
		newEnemy.stats.nickname = globaldata.pippi.nickname
	elif newEnemy.stats.nickname == "Teddy":
		newEnemy.stats.nickname = globaldata.teddy.nickname
	var count = 0
	for enemyBP in enemyBPs:
		if enemyBP.stats.nickname.begins_with(newEnemy.stats.name):
			if enemyBP.stats.nickname == newEnemy.stats.name:
				enemyBP.stats.nickname += " A"
			count += 1
	if count > 0:
		newEnemy.stats.nickname = newEnemy.stats.name + " " + enemyRename[count]
	newEnemy.stats.status = []
	if not "passiveSkills" in newEnemy.stats:
		newEnemy.stats.passiveSkills = []
	battleParticipants.append(newEnemy)
	if overworld_object != null and overworld_object.get("startingHP") != null:
		newEnemy.stats.hp = overworld_object.startingHP
	#then exps, cashes, and items!!
	expPool += newEnemy.stats.exp
	cashPool += newEnemy.stats.cash
	if newEnemy.stats.has("items"):
		if !boss:
			itemPool.append(
				{"items": newEnemy.stats.items,
				 "overworld": overworld_object})
		elif newEnemy.stats.boss:
			#only append boss item if it's a boss encounter
			itemPool.append(
				{"items": newEnemy.stats.items,
				 "overworld": overworld_object})
	enemyBPs.append(newEnemy)
	
	#next, we set up enemy transitions, if there is an overworld sprite
	var enemySpr = null
	if overworld_object != null:
		if overworld_object.has_method("die"):
			newEnemy.overworldObj = overworld_object
			overworld_object.connect("enemy_erased", newEnemy, "set_overworldObj_null")
		overworld_object.hide()
		enemySpr = overworld_object.duplicate_sprite()
		enemySpr.position = overworld_object.get_viewport().canvas_transform.xform(overworld_object.position)
	else:
		# otherwise, we just add an empty sprite
		enemySpr = Sprite.new()
	$EnemyTransitions.add_child(enemySpr)
	return newEnemy

func add_players_sprites():
#	var arr = [global.persistPlayer]
#	arr.append_array(global.partyObjects)
	for partyMem in global.partyObjects:
		partyMem.hide()
		var sprite = partyMem.duplicate_sprite()
		var tween = Tween.new()
		#jank. bad code. what r u doing roka
		
		sprite.show()
		sprite.position = partyMem.get_viewport().canvas_transform.xform(partyMem.position) - Vector2(0,4)
		if partyMem == global.persistPlayer:
			sprite.frame_coords = Vector2(3, 0)
			$PlayerTransitions.add_child(sprite)
		elif partyMem.partyMemberClass == global.party:
			sprite.frame_coords = Vector2(3, 0)
			$PlayerTransitions.add_child(sprite)
		else:
			sprite.frame_coords = Vector2(3, 2)
			$NpcTransitions.add_child(sprite)
		partyOriginalPositions.append(sprite.position)
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

func cache_enemy_actions():
	for enemy in enemyBPs:
		# add skill weights
		var allWeights := 0
		for skill in enemy.stats.skills:
			allWeights += skill.weight
		var i = rand_range(0.0, float(allWeights))
		print("rolled ", i, " out of ", allWeights)
		# find where the random number landed
		var chosenSkill = "bash"
		var currentWeight = 0
		for skill in enemy.stats.skills:
			currentWeight += skill.weight
			if i <= currentWeight:
				chosenSkill = skill.skill
				break
		var skillAction = SkillAction.new(enemy)
		skillAction.skill = globaldata.skills[chosenSkill]
		cache_action(skillAction)

func do_actions():
	doingActions = true
	$ActionMenuBox.hide()
	$InfoBox1.hide()
	actionQueue.sort_custom(self, "sort_by_priority")
	print("Doing actions!!")
	for i in range(actionQueue.size()):
		var action = actionQueue[i]
		if i < actionQueue.size() - 1:
			action.connect("done", self, "start_action", [actionQueue[i+1]], CONNECT_ONESHOT)
		else:
			action.connect("done", self, "new_round", [], CONNECT_ONESHOT || CONNECT_DEFERRED)
	start_action(actionQueue[0])

func new_round():
	if bufferReorganize:
		reorganize_enemies()
	currentAction = null
	doingActions = false
	# check for win
	var battleWon = true
	for enemy in enemyBPs:
		if enemy.isConscious():
			battleWon = false
	if battleWon:
		win()
		return
	
	# check for healed statuses and do passives
	for bp in get_conscious_party():
		for status in bp.stats.status:
			var roll = randi() % 100 + 1
			match(int(status)):
				globaldata.ailments.Blinded:
					if roll <= 20:
						yield(heal_status("blinded", bp), "completed")
				globaldata.ailments.Burned:
					if roll <= 20:
						yield(heal_status("burned", bp), "completed")
				globaldata.ailments.Numb:
					if roll <= 20:
						yield(heal_status("numb", bp), "completed")
				globaldata.ailments.Sleeping:
					if roll <= 20:
						yield(heal_status("sleeping", bp), "completed")
				globaldata.ailments.Poisoned:
					if roll <= 20:
						yield(heal_status("poisoned", bp), "completed")
				
		# DoPassive - End of turn (party members)
		for passive in bp.stats.passiveSkills:
			match(passive):
				_:
					pass
	for bp in get_conscious_enemies():
		for status in bp.stats.status:
			var roll = randi() % 100 + 1
			match(int(status)):
				globaldata.ailments.Burned:
					if roll <= 25:
						yield(heal_status("burned", bp), "completed")
				globaldata.ailments.Numb:
					if roll <= 25:
						yield(heal_status("numb", bp), "completed")
				globaldata.ailments.Sleeping:
					if roll <= 25:
						yield(heal_status("sleeping", bp), "completed")
		# DoPassive - End of turn (enemies)
		for passive in bp.stats.passiveSkills:
			match(passive):
				_:
					pass
	
	emit_signal("roundDone")
	yield(get_tree().create_timer(.4), "timeout")
	if !active:
		return
	# start new round!
	for action in actionQueue:
		action.free()
	actionQueue.clear()
	currPartyMem = -1
	cursorActive = true
	turn += 1
	next_active_menu()

func start_action(action):
	if bufferReorganize:
		yield(reorganize_enemies(), "completed")
		if !active:
			return
	currentAction = action
	# check for win
	var battleWon = true
	for enemy in enemyBPs:
		if enemy.isConscious():
			battleWon = false
	if battleWon:
		win()
		return
	
	if !action.user.isConscious():
		action.emit_signal("done")
		return
	
	if action.user.isEnemy:
		play_sfx("enemyturn")
		action.user.battleSprite.flash()
	elif !action is GuardAction:
		play_sfx("attack1")
	yield(get_tree().create_timer(.2), "timeout")
	if !active:
		return
	
	# this category handles both skills and items
	# because items just contain a skill 
	if action is SkillAction and !action is ItemAction:
		# TODO: check if the action is possible??
		# aka, what if we try to use a status healing item on someone whose status is now healed
		#      or what if we try to heal or attack someone who is unconscious
		retarget_action(action)
		do_skill_costs(action.skill, action.user, action.targets)

		var dialogName = action.user.stats.nickname
		var userPronoun = "its"
		var targetPronoun = "its"
		if action.user.stats.has("pronoun"):
			userPronoun = action.user.stats.pronoun
		if action.targets.size() > 1:
			targetPronoun = "their"
		elif action.targets[0].stats.has("pronoun"):
			targetPronoun = action.targets[0].stats.pronoun
		
		var dialog = {}
		if "dialog" in action.skill:
			dialog = {
				"0": {
					"text": action.skill.dialog.format({
						"name": dialogName,
						"target": action.targets[0].stats.nickname,
						"userpronoun": userPronoun,
						"targetpronoun": targetPronoun
						})
				}
			}
		# default dialogs for skill action
		else:
			if action.skill.skillType == "psi":
				if action.user.isEnemy:
					play_sfx("enemypsi")
				else:
					play_sfx("yourpsi")
				var level = globaldata.get_psi_level_ascii(action.skill.level)
				dialog = {
					"0": {"text": dialogName + " tried " + action.skill.name + " " + level + "!"}
				}
			else:
				dialog = {
					"0": {"text": dialogName + " attacks!"}
				}
		
		$Dialoguebox.connect("done", self, "do_screen_effect", [action], CONNECT_ONESHOT)
		$Dialoguebox.start(dialog)
	elif action is ItemAction:
		InventoryManager.dropItem(action.user.stats.name, action.inv_idx)
		play_battle_sprite_anim(action.user, "item", true)
		
		var dialogName = action.user.stats.nickname
		var userPronoun = "its"
		var targetPronoun = "its"
		if action.user.stats.has("pronoun"):
			userPronoun = action.user.stats.pronoun
		if action.targets.size() > 1:
			targetPronoun = "their"
		elif action.targets[0].stats.has("pronoun"):
			targetPronoun = action.targets[0].stats.pronoun
		
		var dialog = {}
		if "dialog" in action.skill:
			dialog = {
				"0": {
					"text": action.skill.dialog.format({
						"name": dialogName,
						"target": action.targets[0].stats.nickname,
						"userpronoun": userPronoun,
						"targetpronoun": targetPronoun
						})
				}
			}
		elif action is ItemAction:
			if dialogName != action.targets[0].stats.nickname:
				dialog = {
					"0": {"text": "%s uses %s on %s!" % [dialogName, action.item.name.english, action.targets[0].stats.nickname]}
				}
			else:
				dialog = {
					"0": {"text": "%s uses %s!" % [dialogName, action.item.name.english]}
				}
		
		if "battle_action" in action.item and action.item.battle_action != "":
			$Dialoguebox.connect("done", self, "do_screen_effect", [action], CONNECT_ONESHOT)
		else:
			$Dialoguebox.connect("done", self, "do_item", [action], CONNECT_ONESHOT)
		$Dialoguebox.start(dialog)
	elif action is GuardAction:
		do_guard(action)
	elif action is FleeAction:
		var dialog = {
			"0": {
				"text": "%s ran away!" % action.user.stats.nickname
			}
		}
		$Dialoguebox.start(dialog)
		yield($Dialoguebox, "done")
		tryFlee(action)

func retarget_action(action):
	# ANYWAY if there are no targets (or, they are unconcious), try again
	var targetOK = !action.targets.empty()
	for target in action.targets:
		if !target.isConscious():
			#redo targets, heck
			targetOK = false
	if !targetOK:
		# retargeting is not smart, but we can change that in the future lol
		if action is ItemAction:
			action.targets = get_alive_targets_from_type(action.user, TargetType.SELF)
		else:
			action.targets = get_alive_targets_from_type(action.user, action.skill.targetType)

func do_skill_costs(skill, user, targets):
	# subtract hp/pp costs
	if skill.hpCost > 0:
		user.stats.hp -= skill.hpCost
		if !user.isEnemy:
			user.partyInfo.setHP(user.stats.hp)
	if skill.ppCost > 0:
		user.stats.pp -= skill.ppCost
		if !user.isEnemy:
			user.partyInfo.setPP(user.stats.pp)

func do_skill(action, i = 0):
	if !action.user.isConscious():
		action.emit_signal("done")
		return
	if !action.user.isEnemy:
		play_sfx(action.skill.useSound)
		if i == 0:
			if action.skill.name == "Attack":
				play_battle_sprite_anim(action.user, action.user.bashAnim, true)
				if action.user.battleSprite.animationPlayer.has_animation(action.user.bashAnim):
					yield(action.user.battleSprite, "apply_damage")
			else:
				play_battle_sprite_anim(action.user, action.skill.userAnim, true)
		
	else:
		if i == 0 and action.skill.damageType == DamageType.DAMAGE and action.skill.skillType == "physical":
			action.user.battleSprite.attack()
			yield(action.user.battleSprite, "apply_damage")
	if i < action.targets.size():
		yield(do_pre_hit_effect(action, i), "completed")
		var skill = action.skill
		var user = action.user
		var target = action.targets[i]
		var val = 0
		
		if !target.isConscious():
			action.emit_signal("done")
			return
		# if this is healing
		# damage skill!
		if skill.damageType == DamageType.DAMAGE:
			var hitRoll = randi() % 100 + 1
			# blind check!
			if user.hasStatus(globaldata.ailments.Blinded):
				var blindRoll = randi() % 100 + 1
				if blindRoll <= 60:
					hitRoll = -1
			if hitRoll >= skill.failChance:
				# DoPassive - On getting hit
				for passive in target.stats.passiveSkills:
					match(passive):
						"reflect_beam_courage":
							if skill.name == "PK Beam" and skill.level == 2 and !target.isEnemy:
								$AudioStreamPlayer.stream = soundEffects["franklinbadge"]
								$AudioStreamPlayer.play()
								Input.start_joy_vibration(0, 0.3, 0.6, 0.5)
								var dialog = {}
								dialog = {
									"0": {"text": "%s's %s shined a bright light!" % [target.stats.nickname, globaldata.items["CourageBadge"].name.english], "goto": "1"},
									"1": {"text": "It reflected the beam back!"}
								}
								$Dialoguebox.start(dialog)
								yield($Dialoguebox, "done")
								var temp = target
								# flip flop the target and the user
								target = user
								user = temp
						"reflect_beam":
							if skill.name == "PK Beam" and skill.level == 2 and !target.isEnemy:
								$AudioStreamPlayer.stream = soundEffects["franklinbadge"]
								$AudioStreamPlayer.play()
								Input.start_joy_vibration(0, 0.3, 0.6, 0.5)
								var dialog = {}
								dialog = {
									"0": {"text": "%s's %s reflected the beam back!" % [target.stats.nickname, globaldata.items["FranklinBadge0.8"].name.english]}
								}
								$Dialoguebox.start(dialog)
								yield($Dialoguebox, "done")
								var temp = target
								# flip flop the target and the user
								target = user
								user = temp
						"reflect_lightning":
							if skill.name == "PK Thunder":
								$AudioStreamPlayer.stream = soundEffects["franklinbadge"]
								$AudioStreamPlayer.play()
								Input.start_joy_vibration(0, 0.3, 0.6, 0.5)
								var dialog = {}
								dialog = {
									"0": {"text": "%s's %s reflected the lightning back!" % [target.stats.nickname, globaldata.items["FranklinBadge"].name.english]}
								}
								$Dialoguebox.start(dialog)
								yield($Dialoguebox, "done")
								var temp = target
								# flip flop the target and the user
								target = user
								user = temp
				
				var mod = 0
				var useFlyingNum
				var canSmash = false
				if skill.skillType == "physical":
					canSmash = true
					useFlyingNum = true
					mod = user.get_stat("offense")
				elif skill.skillType == "psi":
					useFlyingNum = false
					mod = user.get_stat("iq") / 5
				
				var defense = target.get_stat("defense")
				if target.defending:
					defense *= 2.0
				
				# check for smash attack
				
				var smashRoll = randi() % 100 + 1
				var smashed = false
				var adrenaline = false
				# smash chance is either 5/100 or guts/5
				if !action.user.isEnemy:
					if action.user.stats.hp <= 0:
						adrenaline = true
					if "Slingshot" in user.stats.equipment.weapon:
						canSmash = false
				
				
				if smashRoll <= max(5, floor(user.get_stat("guts")/5)) and user.get_stat("guts") > 0 and canSmash:
					# SMAAAAAAASH
					smashed = true
					val = max(1, (2 * (skill.damage + mod - (defense/2.0))))
				else:
					val = max(1, skill.damage + mod - (defense/2.0))
					# apply variance
					if adrenaline:
						val *= 1.5
					val = max(1, floor(val + (randf() * skill.variance) - skill.variance/2.0))
				
				
				apply_damage(target, val)
				
				if smashed:
					var smashAttack = create_smash_attack(target)
					$SMASHBOX.add_child(smashAttack)
					play_sfx("smash", 1)
					Input.start_joy_vibration(0, 1, 1, 0.4)
					global.start_slowmo(0.5, 0.5)
				elif target.isEnemy:
					play_sfx(action.skill.hitSound, 1)
					Input.start_joy_vibration(0, 0.5, 0.8, 0.2)
				
				var damageNum = str(val)
				if adrenaline:
					damageNum = damageNum + "!"
				var risingNum = create_rising_num(damageNum, target, useFlyingNum)
				risingNum.run()
				do_hit_effect(action, i)
				
				for status in skill.statusEffects:
					yield(try_status(status.name, status.chance, target), "completed")
				
				# DoPassive - On attack did hit
				for passive in user.stats.passiveSkills:
					match(passive):
						"reflect_beam_courage":
							if !user.isEnemy:
								if skill.name == "PK Beam" and skill.level == 2:
									yield(courage_badge_swap(user), "completed")
			else:
				var risingNum = create_rising_num("Miss", target)
				risingNum.run()
				
				target.battleSprite.dodge()
				if target.isEnemy:
					$AudioStreamPlayer.stream = soundEffects["miss"]
					$AudioStreamPlayer.play()
				else:
					$AudioStreamPlayer.stream = soundEffects["dodge"]
					$AudioStreamPlayer.play()
				
		# for healin skills
		elif skill.damageType == DamageType.HEALING:
			val = skill.damage + int(user.get_stat("iq") / 5)
			#apply healing with variance!
			val = floor(val + (randf() * skill.variance) - skill.variance/2.0)
			apply_healing(target, val)
			Input.start_joy_vibration(0, 0.3, 0, 0.3)
			print(target.stats.nickname, " is healed by ", str(val), "!")
			var risingNum = create_rising_num(str(val), target)
			risingNum.add_color_override("font_color", Color("00ee44"))
			risingNum.run()
			do_hit_effect(action, i)
		# for non hp stuff
		else:
			#free space~!! dumbass lloyd shit go here for now
			for status in skill.statusEffects:
				yield(try_status(status.name, status.chance, target), "completed")
			if action.skill.name == "Spy":
				var dialog = {}
				if "description" in action.targets[0].stats:
					dialog = {
						"0": {"text": "Name: " + action.targets[0].stats.nickname, "goto": "1"},
						"1": {"text": action.targets[0].stats.description},
					}
				else:
					dialog = {
						"0": {"text": action.user.stats.nickname + " could not gather any information from the enemy!"}
					}
				$Dialoguebox.start(dialog)
				yield($Dialoguebox, "done")
			elif action.skill.name == "escapeCrumbs":
				if canRun:
					flee()
				else:
					var dialog = {
						"0": {"text": "Couldn't run!"}
					}
					$Dialoguebox.start(dialog)
					yield($Dialoguebox, "done")
			elif "allies" in action.skill and !action.skill.allies.empty():
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
					var enemyBP = add_enemy(chosenAlly, null)
					add_enemy_battlesprite(enemyBP, false)
					enemyBP.battleSprite.show()
					newEnemies.append(enemyBP)
					bufferReorganize = true
		
		if skill.statusHeals != []:
			if skill.statusAmountHealed > 0:
				for i in skill.statusAmountHealed:
					for status in target.stats.status:
						if globaldata.status_enum_to_name(status) in skill.statusHeals:
							yield(heal_status(globaldata.status_enum_to_name(status), target), "completed")
							break
			elif skill.statusAmountHealed == -1:
				for status in skill.statusHeals:
					yield(heal_status(status, target), "completed")
				
		if "statMods" in skill:
			for stat in skill.statMods:
				yield(mod_stat(stat, skill.statMods[stat], target), "completed")
				if !active:
					return
		yield(get_tree().create_timer(.175), "timeout")
		if !active:
			return
		do_skill(action, i + 1)
	else:
		#check if we buffered any player knockouts
		if !bufferedPlayerDefeat.empty():
			for partyBp in bufferedPlayerDefeat:
				check_player_defeated(partyBp)
			bufferedPlayerDefeat.clear()
		if !active:
			return
		#check for status effect damage
		if action.user.hasStatus(globaldata.ailments.Burned):
			yield(get_tree().create_timer(.2), "timeout")
			if !active:
				return
			var val = randi() % 6 + 3
			var risingNum = create_rising_num(str(val), action.user, true)
			risingNum.add_color_override("font_color", Color.red * .9)
			risingNum.run()
			yield(get_tree().create_timer(.2), "timeout")
			if !active:
				return
		else:
			yield(get_tree().create_timer(.4), "timeout")
			if !active:
				return
		
		if !action.user.isEnemy and !action.user.defending:
			action.user.battleSprite.hideAway()
		action.emit_signal("done")

func darken_bg():
	$BGDarkinator/AnimationPlayer.play("darken")

func undarken_bg():
	$BGDarkinator/AnimationPlayer.play("undarken")

func start_joy_vibration(device = 0, weak_magnitude = 0.0, strong_magnitude = 0.0, duration = 0):
	Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)

func do_screen_effect(action):
	if action.skill.useSound and action.skill.useSound in soundEffects:
		$AudioStreamPlayer.stream = soundEffects[action.skill.useSound]
		$AudioStreamPlayer.play()
	
	if !action.user.isEnemy and action.skill.has("screenEffect"): 
		if $ScreenEffect/AnimationPlayer.has_animation(action.skill.screenEffect):
			$ScreenEffect/AnimationPlayer.play(action.skill.screenEffect)
		else:
			do_skill(action)
			return
	elif action.user.isEnemy and action.skill.has("enemyScreenEffect"):
		if $ScreenEffect/AnimationPlayer.has_animation(action.skill.enemyScreenEffect):
			$ScreenEffect/AnimationPlayer.play(action.skill.enemyScreenEffect)
		else:
			do_skill(action)
			return
	else:
		do_skill(action)
		return
	
	darken_bg()
	yield($ScreenEffect/AnimationPlayer, "animation_finished")
	do_skill(action)
	undarken_bg()
	


func do_pre_hit_effect(action, idx):
	if !action.skill.has("preHitEffect") or !$PreHitEffect/AnimationPlayer.has_animation(action.skill.preHitEffect):
		yield(get_tree(), "idle_frame")
		return
	
	#this is the stupidist way to find our target's ui in the scene, but we living it up out here
	var targetPos = Vector2()
	# first, check if we are a party member
	for i in range(partyBPs.size()):
		if partyBPs[i] == action.targets[idx]:
			targetPos = $PartyInfo.get_child(i).rect_global_position
			targetPos += $PartyInfo.get_child(i).rect_size/2
	# in case its an enemy we are looking for, we use battleId instead
	if targetPos == Vector2.ZERO:
		var id = action.targets[idx].id - partyBPs.size()
		targetPos = action.targets[idx].battleSprite.rect_global_position + action.targets[idx].battleSprite.rect_size/2
	
	darken_bg()
	$PreHitEffect/AnimationPlayer.play(action.skill.preHitEffect)
	$PreHitEffect/AnimationPlayer.advance(0)
	$PreHitEffect.rect_position = targetPos - $PreHitEffect.rect_size/2
	yield($PreHitEffect/AnimationPlayer, "animation_finished")
	undarken_bg()

func do_hit_effect(action, idx):
	if !action.skill.has("hitEffect") or !$HitEffect/AnimationPlayer.has_animation(action.skill.hitEffect):
		yield(get_tree(), "idle_frame")
		return
	
	#this is the stupidist way to find our target's ui in the scene, but we living it up out here
	var targetPos = Vector2()
	# first, check if we are a party member
	for i in range(partyBPs.size()):
		if partyBPs[i] == action.targets[idx]:
			targetPos = $PartyInfo.get_child(i).rect_global_position
			targetPos += $PartyInfo.get_child(i).rect_size/2
	# in case its an enemy we are looking for, we use battleId instead
	if targetPos == Vector2.ZERO:
		var id = action.targets[idx].id - partyBPs.size()
		targetPos = action.targets[idx].battleSprite.rect_global_position + action.targets[idx].battleSprite.rect_size/2
	
	if action.skill.hitSound and action.skill.hitSound in soundEffects:
		$AudioStreamPlayer.stream = soundEffects[action.skill.hitSound]
	
	$HitEffect/AnimationPlayer.play(action.skill.hitEffect)
	$HitEffect/AnimationPlayer.advance(0)
	$HitEffect.rect_position = targetPos - $HitEffect.rect_size/2

#mainly used for stat buffs/debuffs
func do_hit_effect_by_anim(anim, target):
	if !$HitEffect/AnimationPlayer.has_animation(anim):
		yield(get_tree(), "idle_frame")
		return
	
	var targetPos = Vector2()
	# first, check if we are a party member
	targetPos = target.battleSprite.rect_global_position + target.battleSprite.rect_size/2
	
	$HitEffect/AnimationPlayer.play(anim)
	$HitEffect/AnimationPlayer.advance(0)
	$HitEffect.rect_position = targetPos - $HitEffect.rect_size/2

func do_guard(action):
	action.user.defending = true
	if !is_connected("roundDone", self, "undo_guard"):
		connect("roundDone", self, "undo_guard", [], CONNECT_ONESHOT)
	action.emit_signal("done")

func undo_guard():
	for partyMember in partyBPs:
		if partyMember.defending:
			partyMember.defending = false
			partyMember.battleSprite.hideAway()

func do_item(action):
	if !action.user.isConscious():
		action.emit_signal("done")
		return
	retarget_action(action)
	var item = action.item
	for target in action.targets:
		if target.isConscious():
			if item.HPrecover > 0:
				play_sfx("healHP", 1)
				apply_healing(target, item.HPrecover)
				var risingNum = create_rising_num(str(item.HPrecover), target)
				risingNum.add_color_override("font_color", Color("00ee44"))
				risingNum.run()
			if item.PPrecover > 0:
				play_sfx("healPP", 1)
				apply_restore_pp(target, item.PPrecover)
				var risingNum = create_rising_num(str(item.PPrecover), target)
				risingNum.add_color_override("font_color", Color.aqua)
				risingNum.run()
			if "status_heals" in item:
				play_sfx("healstatus", 1)
				for status in item.status_heals:
					yield(heal_status(status, action.user), "completed")
					if !active:
						return
			yield(get_tree().create_timer(.15), "timeout")
			if !active:
				return
	action.emit_signal("done")

func apply_healing(target, val):
	if !target.isConscious():
		return
	target.stats.hp += val
	target.stats.hp = min(target.stats.hp, target.get_stat("maxhp"))
	if !target.isEnemy:
		target.partyInfo.setHP(target.stats.hp)

func apply_restore_pp(target, val):
	if !target.isConscious():
		return
	target.stats.pp += val
	target.stats.pp = min(target.stats.pp, target.get_stat("maxpp"))
	if !target.isEnemy:
		target.partyInfo.setPP(target.stats.pp)

func apply_damage(target, val):
	if !target.isConscious():
		return
	var oldHP = target.stats.hp
	target.stats.hp -= val
	target.stats.hp = max(target.stats.hp, 0)
	if !target.isEnemy:
		target.partyInfo.setHP(target.stats.hp)
		if target.defending:
			play_sfx("hurt2")
			target.battleSprite.play("guard")
			Input.start_joy_vibration(0, 0.5, 0.5, 0.2)
		elif val > (1.0/16.0) * target.get_stat("maxhp"):
			Input.start_joy_vibration(0, 0.8, 0.8, 0.3)
			play_sfx("hurt2")
			target.battleSprite.bounceUpHit(min(val / (target.get_stat("maxhp") / 2), 3))
			
			target.partyInfo.quake(.1, 1.5)
		else:
			Input.start_joy_vibration(0, 0.5, 0.5, 0.2)
			play_sfx("hurt1")
			target.partyInfo.quake(.1)
			target.battleSprite.shake(val / (target.get_stat("maxhp") / 2))
		if target.hasStatus(globaldata.ailments.Sleeping):
			var roll = randi() % 100 + 1
			if roll <= 25:
				yield(heal_status("Sleeping", target), "completed")
		if target.stats.hp <= 0:
			play_sfx("mortaldamage")
			Input.start_joy_vibration(0, 1, 1, 0.4)
			if oldHP > 0:
				var dialog = {
				"0": {"text": "%s took mortal damage!" % [target.stats.nickname]}
				}
				$Dialoguebox.start(dialog)
				yield($Dialoguebox, "done")
		
	else:
		if target.stats.hp == 0:
			# DoPassive - On enemy defeated
			if currentAction != null:
				for passive in currentAction.user.stats.passiveSkills:
					match(passive):
						_:
							pass
			target.defeat()
			enemyBPs.erase(target)
			if !enemyBPs.empty():
				bufferReorganize = true
		else:
			target.battleSprite.hit()
			if target.hasStatus(globaldata.ailments.Sleeping):
				var roll = randi() % 100 + 1
				if roll <= 25:
					yield(heal_status("Sleeping", target), "completed")

func drain_pp(target, drainer, val):
	if !target.isConscious():
		return
	#remove pp from target
	var oldPP = target.stats.pp
	target.stats.pp -= val
	target.stats.pp = max(target.stats.pp, 0)
	
	if !target.isEnemy:
		target.partyInfo.setPP(target.stats.pp)
	#give pp to drainer
	if drainer != null:
		var difference = oldPP - target.stats.pp 
		if difference < 0:
			difference = 0
		drainer.stats.pp += difference
		create_rising_num(difference, drainer)
	
		if !drainer.isEnemy:
			drainer.partyInfo.setPP(drainer.stats.pp)

func try_status(status_name, chance, target):
	if !target.isConscious():
		yield(get_tree(), "idle_frame")
		return
	var status = globaldata.status_name_to_enum(status_name)
	if status == -1:
		push_warning("Invalid status effect !" + status_name + " skipping...")
		yield(get_tree(), "idle_frame")
		return
	if target.hasStatus(status):
		yield(get_tree(), "idle_frame")
		return
	var r = randi() % 100 + 1
	if r <= chance:
		play_sfx("statusafflicted")
		target.setStatus(status, true)
		do_status(target, status, true)
		var dialog = {
			"0": {"text": "oh no!! %s caught the %s!!" % [target.stats.nickname, status_name]}
		}
		match(status):
			globaldata.ailments.Blinded:
				dialog["0"].text = "%s can't see!" % target.stats.nickname
			globaldata.ailments.Burned:
				dialog["0"].text = "%s caught on fire!" % target.stats.nickname
			globaldata.ailments.Confused:
				dialog["0"].text = "%s felt a little strange!" % target.stats.nickname
			globaldata.ailments.Numb:
				dialog["0"].text = "%s felt numb!" % target.stats.nickname
			globaldata.ailments.Forgetful:
				dialog["0"].text = "%s can't seem to concentrate!" % target.stats.nickname
			globaldata.ailments.Sleeping:
				dialog["0"].text = "%s fell asleep!" % target.stats.nickname
			globaldata.ailments.Poisoned:
				dialog["0"].text = "%s got poisoned!" % target.stats.nickname
		$Dialoguebox.start(dialog)
		yield($Dialoguebox, "done")
	else:
		yield(get_tree(), "idle_frame")
		return

func heal_status(status_name, target):
	var status = globaldata.status_name_to_enum(status_name)
	if status == -1:
		push_warning("Invalid status effect " + status_name + " skipping...")
		yield(get_tree(), "idle_frame")
		return
	if !target.hasStatus(status):
		yield(get_tree(), "idle_frame")
		return
	target.setStatus(status, false)
	do_status(target, status, false)
	var dialog = {
		"0": {"text": "%s has been cured of %s!" % [target.stats.nickname, status_name]}
	}
	match(status):
		globaldata.ailments.Asthma:
			dialog["0"].text = "%s could breathe again!" % target.stats.nickname
		globaldata.ailments.Blinded:
			dialog["0"].text = "%s could see again!" % target.stats.nickname
		globaldata.ailments.Burned:
			dialog["0"].text = "%s's burns went away!" % target.stats.nickname
		globaldata.ailments.Cold:
			dialog["0"].text = "%s's cold went away!" % target.stats.nickname
		globaldata.ailments.Confused:
			dialog["0"].text = "%s is no longer confused!" % target.stats.nickname
		globaldata.ailments.Forgetful:
			dialog["0"].text = "%s's head became clear!" % target.stats.nickname
		globaldata.ailments.Nausea:
			dialog["0"].text = "%s is no longer nauseous!" % target.stats.nickname
		globaldata.ailments.Numb:
			dialog["0"].text = "%s softened up!" % target.stats.nickname
		globaldata.ailments.Mushroomized:
			dialog["0"].text = "The mushroom fell off of %s's head!" % target.stats.nickname
		globaldata.ailments.Poisoned:
			dialog["0"].text = "The poison was removed from %s's body!" % target.stats.nickname
		globaldata.ailments.Sleeping:
			dialog["0"].text = "%s woke up!" % target.stats.nickname
		globaldata.ailments.Sunstroked:
			dialog["0"].text = "%s no longer has sunstroke!" % target.stats.nickname
		globaldata.ailments.Unconscious:
			dialog["0"].text = "%s was revived!" % target.stats.nickname
		

	$Dialoguebox.start(dialog)
	yield($Dialoguebox, "done")

func do_status(bp, status, on):
#	print("Status is ", status_name)
	# any init or cleanup happens here for statuses
	match(status):
		globaldata.ailments.Poisoned:
			if !bp.isEnemy:
				if on:
					bp.partyInfo.decScrollSpeedMod = 1.5
					bp.partyInfo.set_poisoned()
				else:
					bp.partyInfo.decScrollSpeedMod = 1.0
					bp.partyInfo.set_cured_poison()

func mod_stat(stat, amt, target):
	var dialog = {}
	if amt + target.statMods[stat] > 6:
		amt = 6 - target.statMods[stat]
	elif amt + target.statMods[stat] < -6:
		amt = -6 - target.statMods[stat]
	if target.statMods[stat] < 6:
		#if amt + target.statMods[stat] >= 6:
		#	amt = target.statMods[stat] + amt - 6
		var statRaise = max(3, floor(target.get_base_stat(stat)/8)) * amt
		if sign(amt) > 0:
			play_sfx("statup", 1)
			Input.start_joy_vibration(0, 0.3, 0, 0.2)
			if stat in ["offense", "defense", "speed"]:
				do_hit_effect_by_anim("stat_" + stat + "_up", target)
			dialog = {
				"0": {"text": "%s's %s went up by %s!" % [
					target.stats.nickname,
					globaldata.capitalize_stat(stat),
					str(statRaise)]
					}
			}
		elif sign(amt) < 0:
			play_sfx("statdown", 1)
			Input.start_joy_vibration(0, 0.3, 0, 0.2)
			if stat in ["offense", "defense", "speed"]:
				do_hit_effect_by_anim("stat_" + stat + "_down", target)
			dialog = {
				"0": {"text": "%s's %s went down by %s!" % [
					target.stats.nickname,
					globaldata.capitalize_stat(stat), 
					str(abs(statRaise))]
					}
			}
		target.add_stat_mod(stat, amt)
	elif target.statMods[stat] >= 6:
		dialog = {
				"0": {"text": "%s's %s could not go any higher." % [
					target.stats.nickname,
					globaldata.capitalize_stat(stat)]
					}
			}
	elif target.statMods[stat] <= -6:
		dialog = {
				"0": {"text": "%s's %s could not go any lower." % [
					target.stats.nickname,
					globaldata.capitalize_stat(stat)]
					}
			}
	if dialog != {}:
		$Dialoguebox.start(dialog)
		yield($Dialoguebox, "done")

func sort_by_priority(a, b):
	if a.priority > b.priority:
		return true
	# when in the same priority, speed matters
	elif a.priority == b.priority:
		return sort_by_speed(a, b)
	else:
		return false

func sort_by_speed(a, b):
	if a.user.get_stat("speed") > b.user.get_stat("speed"):
		return true
	# we dont randomize if both speeds are the same, godot doesn't like that
	else:
		return false

func create_rising_num(text, who, flyingNum = false):
	var risingNum
	if !flyingNum:
		risingNum = risingNumTscn.instance()
	else:
		risingNum = flyingNumTscn.instance()
	risingNum.text = text
	add_child(risingNum)
	var targetPos = Vector2()
	# first, check if we are a party member
	if !who.isEnemy:
		targetPos = who.partyInfo.rect_global_position
		targetPos.x += who.partyInfo.rect_size.x/2
	else:
		# in case its an enemy we are looking for, we use battleId instead
		targetPos = who.battleSprite.rect_global_position + who.battleSprite.rect_size/2
	targetPos -= risingNum.rect_size/2
	risingNum.rect_position = targetPos
	return risingNum

func create_smash_attack(who):
	$BGDarkinator/AnimationPlayer.play("smash")
	var smashAttack = smashAttackTscn.instance()
	var targetPos = Vector2()
	# first, check if we are a party member
	if !who.isEnemy:
		targetPos = who.partyInfo.rect_global_position
		targetPos.x += who.partyInfo.rect_size.x/2
	else:
		# in case its an enemy we are looking for, we calc it differently
		targetPos = who.battleSprite.rect_global_position + who.battleSprite.rect_size/2
	# make the smash a little higher above where the rising num will be 
	targetPos.y -= 32
#	targetPos -= smashAttack.rect_size/2
	smashAttack.position = targetPos
	return smashAttack

func play_battle_sprite_anim(user, anim, override = false):
	if !user.isEnemy:
		user.battleSprite.play(anim, override)

func get_conscious_party():
	var arr = []
	for partyMember in partyBPs:
		if partyMember.isConscious():
			arr.append(partyMember)
	return arr

func get_conscious_enemies():
	var arr = []
	for enemy in enemyBPs:
		if enemy.isConscious():
			arr.append(enemy)
	return arr

func show_enemy_sprites():
	for enemy in $Enemies.get_children():
#		$EnemyTransitions.get_child(0).queue_free()
		enemy.show()
		enemy.appear()
		yield(get_tree().create_timer(.1), "timeout")
	enemiesShaking = false

func check_player_defeated(partyMem):
	if active and !enemyBPs.empty():
		if partyMem.partyInfo.HP == 0:
			if doingActions and !currentAction.user.isEnemy and \
			   ($ScreenEffect/AnimationPlayer.is_playing() or $PreHitEffect/AnimationPlayer.is_playing()):
				bufferedPlayerDefeat.append(partyMem)
			else:
				defeat_player(partyMem)

func defeat_player(partyMem):
	# DoPassive - On party member defeat
	for passive in partyMem.stats.passiveSkills:
		match(passive):
			_:
				pass
	play_sfx("playerdefeated")
	Input.start_joy_vibration(0, 1, 1, 0.5)
	# undo status before becoming unconcious
	print("Removing all statuses for unconcious!")
	var status_to_remove = partyMem.stats.status.duplicate()
	for status in status_to_remove:
		print(globaldata.status_enum_to_name(status))
		do_status(partyMem, status, false)
		partyMem.setStatus(status, false)
	partyMem.defeat()
	if get_conscious_party().empty():
		if uiManager.battleLoseCutscene != "":
			loseBattle = true
			active = false
			end_battle(uiManager.battleLoseCutscene)
		else:
			lose()
			

func revive_party():
	for i in global.party:
		i.status.clear()
		if i == global.party[0]:
			i.hp = i.maxhp
			i.pp = i.maxpp
		else:
			i.status.append(globaldata.ailments.Unconscious)
			i.pp = i.maxpp

func remove_enemy_transitions():
	for enemy in $Enemies.get_children():
		$EnemyTransitions.get_child(0).queue_free()
		yield(get_tree().create_timer(.1), "timeout")

func jump_to_partyinfo():
	yield(get_tree().create_timer(.2), "timeout")
	for i in range($PlayerTransitions.get_child_count()):
		yield(get_tree().create_timer(.1), "timeout")
		var sprite = $PlayerTransitions.get_child(i)
		var partyInfo = $PartyInfo.get_child(i)
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
		
		#jank. bad code. what r u doing roka
		sprite.frame_coords = Vector2(0, 18)
		tween.start()
	jump_to_side()

func jump_to_side():
	yield(get_tree().create_timer(.2), "timeout")
	for i in range($NpcTransitions.get_child_count()):
		yield(get_tree().create_timer(.1), "timeout")
		var sprite = $NpcTransitions.get_child(i)
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
		tween.connect("tween_all_completed", sprite, "hide", [], CONNECT_DEFERRED)
		
		#jank. bad code. what r u doing roka
		sprite.frame_coords = Vector2(2, 18)
		tween.start()

func enemy_to_position():
	start_enemy_shaking()
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

func start_enemy_shaking():
	enemiesShaking = true

func play_sfx(sfxName, channel = 0):
	if !soundEffects.has(sfxName):
		return
	audioManager.play_sfx(soundEffects[sfxName], "BattleSfx" + str(channel))

func give_exp(i):
	var receiving = 0
	for i in partyBPs.size():
		if partyBPs[i].isConscious() and partyBPs[i].stats.level < globaldata.levelCap:
			receiving += 1
	if i >= receiving:
		emit_signal("levelUpDone")
		return
	var partyMem = partyBPs[i]
	if !partyMem.isConscious() or partyMem.stats.level >= globaldata.levelCap:
		give_exp(i + 1)
		return
	
	# give exp
	partyMem.stats.exp += int(round(expPool/ receiving))
	check_level_up(i)

func give_cash():
	globaldata.earned_cash += cashPool
	globaldata.bank += cashPool

func check_level_up(i):
	var partyMem = partyBPs[i]
	
	# check exp calc
	var nextLvl = partyMem.stats.level + 1
	var expNeeded = int(nextLvl * nextLvl * (nextLvl + 1) * .75)
	
	# do level up, if enough exp!!
	if partyMem.stats.exp >= expNeeded:
		level_up(i)
	else:
		give_exp(i + 1)



func level_up(i):
	var partyMem = partyBPs[i]
	if (!audioManager.overworldBattleMusic) or (boss and audioManager.overworldBattleMusic):
		play_sfx('cheering')
		if !audioManager.get_playing("You Win/LVLUP.mp3"):
			#audioManager.music_fadeout(audioManager.get_audio_player_count()-1, 0.2)
			audioManager.pause_all_music()
			audioManager.add_audio_player()
			audioManager.play_music_from_id("", "You Win/LVLUP.mp3", audioManager.get_audio_player_count() - 1)
		var startTime = audioManager.get_audio_player_from_song("You Win/LVLUP.mp3").get_playback_position()
		var partyMemLevelUp = "You Win/LVLUP_" + partyMem.stats.name + ".mp3"
		if !audioManager.get_playing(partyMemLevelUp):
			audioManager.add_audio_player()
			audioManager.play_music_from_id("", partyMemLevelUp, audioManager.get_audio_player_count() - 1, startTime)
	
	partyMem.stats.level += 1
	var dialog = {
		"0": {"text": "%s leveled up to %s!" % [partyMem.stats.nickname, str(partyMem.stats.level)]}
	}
	var j = 0
	for stat in globaldata.player_stat_target_table[partyMem.stats.name]:
		var gain = get_stat_growth(partyMem, stat)
		if gain > 0:
			partyMem.stats[stat] += gain
			j += 1
			# give the previous dialog somewhere to go
			dialog[str(j-1)].goto = str(j) 
			# add the new dialog
			if stat == "maxhp":
				# let the numbers roll
				partyBPs[i].partyInfo.maxHP = partyMem.get_stat("maxhp")
				partyBPs[i].partyInfo.setHP(partyBPs[i].stats.hp + gain)
				# also update the current
				stat = "hp"
				partyMem.stats[stat] += gain
			elif stat == "maxpp":
				# let the numbers roll
				partyBPs[i].partyInfo.maxPP = partyMem.get_stat("maxpp")
				partyBPs[i].partyInfo.setPP(partyBPs[i].stats.pp + gain)
				# also update the current
				stat = "pp"
				partyMem.stats[stat] += gain
			
			stat = globaldata.capitalize_stat(stat)
			dialog[str(j)] = {
				"text": "%s raised by %s." % [stat, str(gain)]
			}
	
	# check skill table
	for level in partyMem.stats.level + 1:
		if globaldata.player_learn_skill_table[partyMem.stats.name].has(level):
			var newSkill = globaldata.player_learn_skill_table[partyMem.stats.name][level]
			if !globaldata[partyMem.stats.name].learnedSkills.has(newSkill):
				j += 1
				var skillName = globaldata.skills[newSkill].name
				var skillLevel = ""
				if globaldata.skills[newSkill].has("level") and globaldata.skills[newSkill]["skillType"] == "psi":
					skillLevel = int(globaldata.skills[newSkill]["level"])
					skillLevel = " " + globaldata.get_psi_level_ascii(skillLevel)
				var flagTrue = true
				if globaldata.player_learn_skill_table_flags[partyMem.stats.name].has(newSkill):
					if !globaldata.flags[globaldata.player_learn_skill_table_flags[partyMem.stats.name][newSkill]]:
						flagTrue = false
				
				#secretely give the move to the party member if the flag is false
				if flagTrue:
					# give the previous dialog somewhere to go
					dialog[str(j-1)].goto = str(j) 
					# add the new dialog
					dialog[str(j)] = {
						"text": "%s learned %s%s!" % [partyMem.stats.nickname, skillName, skillLevel],
						"soundeffect": "M3/Learned PSI.wav"
					}
				globaldata[partyMem.stats.name].learnedSkills.append(newSkill)
	
	$Dialoguebox.connect("done", self, "check_level_up", [i], CONNECT_ONESHOT | CONNECT_DEFERRED)
	$Dialoguebox.start(dialog)

func get_stat_growth(partyMem, stat):
	var statArr = globaldata.player_stat_target_table[partyMem.stats.name][stat]
	var low_i = floor(partyMem.stats.level/10)
	var high_i = low_i + 1
	var interp = floor(lerp(statArr[low_i], statArr[high_i], (int(partyMem.stats.level) % 10)/10.0))
	var gain = 0
	match(stat):
#		"hp":
#			gain = max(0, interp - partyMem.stats.hp)
#		"pp":
#			gain = max(0, interp - partyMem.stats.pp)
		_:
#			var r = 4.0/50.0
#			gain = floor(((statArr * (partyMem.stats.level - 1)) - ((partyMem.stats[stat] - 2) * 10)) * r)
			gain = interp - partyMem.stats[stat]
	return gain

func hide_battle_BG():
	uiManager.remove_ui(battleBG)
	global.currentCamera.get_node("Tween").set_active(true)
	global.currentCamera.reset()

func hide_enemies():
	$Enemies.hide()

func drop_item_to_overworld():
	yield(get_tree().create_timer(0.8), "timeout")
	var playerPos = global.persistPlayer.get_viewport().canvas_transform.xform(global.persistPlayer.position)
	for droppedItem in queuedDroppedItems:
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
	for droppedItem in queuedDroppedItems:
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

func jump_to_overworld():
	if loseBattle and uiManager.battleLoseCutscene != "":
		for i in global.partyObjects.size():
			global.partyObjects[i].show()
		revive_party()
	else:
		partyOriginalPositions.clear()
		for partyMem in global.partyObjects:
			partyOriginalPositions.append(partyMem.get_viewport().canvas_transform.xform(partyMem.position) - Vector2(0,4))
		jump_npcs_to_overworld()
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
				sprite.position.x, partyOriginalPositions[i].x, 0.55, \
				Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(sprite, "position:y", \
				sprite.position.y, partyOriginalPositions[i].y - 24, 0.35, \
				Tween.TRANS_QUAD, Tween.EASE_OUT)
			tween.interpolate_property(sprite, "position:y", \
				partyOriginalPositions[i].y - 24, partyOriginalPositions[i].y + 4, 0.2, \
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
			tween.connect("tween_all_completed", global.partyObjects[i], "show", [])
			tween.connect("tween_all_completed", global.partyObjects[i], "set_direction", [Vector2(0, -1)])
			tween.connect("tween_all_completed", global.partyObjects[i].sprite, "set", ["frame_coords", Vector2(3,3)])
			
			if !partyBPs[i].isConscious():
				pass
			#jank. bad code. what r u doing roka
			
			sprite.frame_coords = Vector2(3, 18)
			tween.start()
			yield(get_tree().create_timer(.05), "timeout")

func jump_npcs_to_overworld():
	for i in range($NpcTransitions.get_child_count()):
		var sprite = $NpcTransitions.get_child(i)
		# set sprite back in position
		sprite.show()
#		sprite.position.y = 180
		sprite.scale = Vector2.ONE
		
		# do the tween stuff
		var tween = Tween.new()
		sprite.add_child(tween)
		tween.interpolate_property(sprite, 
		"position:x", \
			sprite.position.x, partyOriginalPositions[i + global.party.size()].x, 0.55, \
			Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(sprite, "position:y", \
			sprite.position.y, partyOriginalPositions[i + global.party.size() - 1].y - 24, 0.35, \
			Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.interpolate_property(sprite, "position:y", \
			partyOriginalPositions[i + global.party.size() - 1].y - 24, partyOriginalPositions[i + global.party.size()].y + 4, 0.2, \
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
		tween.connect("tween_all_completed", global.partyObjects[i + global.party.size()], "show", [])
		tween.connect("tween_all_completed", global.partyObjects[i + global.party.size()], "set_direction", [Vector2(0, -1)])
		tween.connect("tween_all_completed", global.partyObjects[i + global.party.size()].sprite, "set", ["frame_coords", Vector2(3,3)])
		
		if !npcBPs[i].isConscious():
			pass
		#jank. bad code. what r u doing roka
		
		sprite.frame_coords = Vector2(3, 18)
		tween.start()
		yield(get_tree().create_timer(.05), "timeout")

func remove_battle_music():
	var winThemes = [
		load("res://Audio/Music/You Win/YOUWON.mp3"),
		load("res://Audio/Music/You Win/Victory.mp3"),
		load("res://Audio/Music/Boss Win.mp3"),
		load("res://Audio/Music/You Win/LVLUP.mp3"),
		load("res://Audio/Music/You Win/LVLUP_ninten.mp3"),
		load("res://Audio/Music/You Win/LVLUP_ana.mp3"),
		load("res://Audio/Music/You Win/LVLUP_lloyd.mp3"),
		load("res://Audio/Music/You Win/LVLUP_pippi.mp3"),
		load("res://Audio/Music/You Win/LVLUP_teddy.mp3")
	]
	for audioPlayer in audioManager.get_audio_player_list():
		if audioPlayer.stream in winThemes:
			audioManager.remove_audio_player(audioManager.get_audio_player_id(audioPlayer))
	if music != "":
		if audioManager.get_playing("Battle Themes/" + music):
			audioManager.remove_audio_player(audioManager.get_audio_player_id(audioManager.get_audio_player_from_song("Battle Themes/" + music)))
		if audioManager.get_playing("Battle Themes/" + musicIntro):
			audioManager.remove_audio_player(audioManager.get_audio_player_id(audioManager.get_audio_player_from_song("Battle Themes/" + musicIntro)))
	elif boss and audioManager.overworldBattleMusic:
		for musicChanger in audioManager.musicChangers:
			musicChanger.stop_music_immediately()
	audioManager.remove_all_unplaying()

func turn_party_to_overworld():
	for bp in partyBPs:
		bp.battleSprite.hideAway()

func rotate_party_to_original_direction():
	for partyObj in global.partyObjects:
		partyObj.rotate_to(partyOriginalDirections.pop_front(), .05)

func courage_badge_swap(user):
	InventoryManager.removeItemFromChar(user.stats.name, "CourageBadge")
	InventoryManager.addItem(user.stats.name, "FranklinBadge0.8")
	user.stats.passiveSkills.erase("reflect_beam_courage")
	var item_data = InventoryManager.Load_item_data("FranklinBadge0.8")
	if item_data.has("slot"):
		if item_data.slot == "" and item_data.has("passive_skills"):
			for passiveSkill in item_data.passive_skills:
				if !passiveSkill in user.stats.passiveSkills:
					user.stats.passiveSkills.append(passiveSkill)
	var dialog = {}
	dialog = {
		"0": {"text": "The %s turned out to be the %s!" % [globaldata.items["CourageBadge"].name.english, globaldata.items["FranklinBadge0.8"].name.english]}
	}
	$Dialoguebox.start(dialog)
	yield($Dialoguebox, "done")

func reorganize_enemies(transition = true):
	bufferReorganize = false
	# if there's a boss, we need a different pattern
	if boss:
		# find the boss
		var bossEnemy
		for enemy in enemyBPs:
			if enemy.stats.get("boss") != null:
				if enemy.stats.boss:
					bossEnemy = enemy
					break
		
		# set it to the center
		# set enemies alternating, to the left/right
		var i = 0
		for enemyBP in enemyBPs:
			var battlesprite = enemyBP.battleSprite
			var position = $Enemies.rect_size/2 

	for i in range(enemyBPs.size()):
		# the ALGORITHm
		var battlesprite = enemyBPs[i].battleSprite
		var new_position = $Enemies.rect_size
		new_position.x /=  (enemyBPs.size() + 1)
		new_position.x *= (i + 1)
		new_position.y = new_position.y / 2
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
			 "_on_reorganize_enemy_tween", [enemyBPs[i]], CONNECT_ONESHOT)
			battlesprite.transitionTween.start()
		else:
			battlesprite.rect_position = new_position
	if transition:
		# magic numbers, yet again! tsk tsk
		# the number is .2 seconds longer than the tween
		yield(get_tree().create_timer(.65), "timeout")
		newEnemies.clear()
	else:
		return

func _on_reorganize_enemy_tween(battlesprite, key, enemyBP):
	if enemyBP in newEnemies:
		battlesprite.appear()

func tryFlee(action):
	var enemySpd = 0
	for enemyBP in get_conscious_enemies():
		enemySpd = max(enemySpd, enemyBP.get_stat("speed"))
		
	var partySpd = 0
	for partyBP in get_conscious_party():
		partySpd = max(partySpd, partyBP.get_stat("speed"))
	
	var chance = wrapi(enemySpd - partySpd + (10 * turn), 0, 100)
	print("flee chance: ", chance)
	var r = randi() % 100 + 1
	print("flee roll: ", r)
	if r < chance:
		# flee success!
		flee()
	else:
		var dialog = {
			"0": {"text": "Couldn't run!"}
		}
		$Dialoguebox.start(dialog)
		yield($Dialoguebox, "done")
		action.emit_signal("done")
