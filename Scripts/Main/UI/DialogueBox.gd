extends "res://Scripts/Main/UI/Functions.gd"

# node refs
onready var nameLabel = $Dialoguebox/Namebox/Name
onready var dialogueLabel = $Dialoguebox/ClipBox/Dialogue
onready var dotLabel = $Dialoguebox/ClipBox/DippinDots
onready var camera = $Camera2D
onready var actorChar = preload("res://Nodes/Reusables/actor.tscn")

signal done
signal finalPhrase(phrase)

#dialog and timing vars

var unpausePlayer = true
var actors := {}
var dialog := {}
var phraseNum = 0
var finished = false
var item_not_given = false
var textSpeed = 0.01
var t = 0
var select = 0
var selected = 0
var options = []
var currPhrase = 0
var queued_battle = false
var autoAdvance = false
var canInput = true
var setRespawn = false


func _ready():
	nameLabel.connect("item_rect_changed", self, "set_nametag")
	Input.action_release("ui_cancel")
	Input.action_release("ui_toggle")
	Input.action_release("ui_accept")
	global.cutscene = true
	global.persistPlayer.pause()
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.close()
	$Dialoguebox/Arrow.hide()
	uiManager.blackBars.open()
	dialog = getDialog()
	textSpeed = globaldata.textSpeed
	currPhrase = dialog[str(phraseNum)]
	dialogueLabel.visible_characters = 0
	dialogueLabel.bbcode_text = ""
	dotLabel.bbcode_text = ""
	nextPhrase()

func _process(delta):
	if !finished:
		t += delta
		$Dialoguebox/Cursor_Down.hide()
		if t > textSpeed:
			dialogueLabel.visible_characters += 1
			if $AudioStreamPlayer.stream != null:
				$AudioStreamPlayer.set_pitch_scale(rand_range(0.85,1.0))
				$AudioStreamPlayer.play()
			t -= textSpeed
		if dialogueLabel.visible_characters >= len(dialogueLabel.text):
			finish()
		
	if !dialogueLabel.visible_characters == len(dialogueLabel.text):
		
		if global.talker != null and currPhrase.has("text"):
			if currPhrase["text"] != "":
				global.talker.talking = true
	else:
		$AudioStreamPlayer.stop()
		if global.talker != null:
			global.talker.talking = false

func finish():
	finished = true
	if $WaitTimer.time_left == 0 and canInput:
		$Dialoguebox/Cursor_Down.show()
		if autoAdvance:
			next_dialog()
	if select > 0:
		$Dialoguebox/Arrow.show()
		$Dialoguebox/Arrow.on = true
		$Dialoguebox/Arrow.set_cursor_from_index(0, false)
		$Dialoguebox/Options.show()
		$Dialoguebox/Cursor_Down.hide()
	else:
		selected = 0
		$Dialoguebox/Arrow.hide()
		$Dialoguebox/Arrow.on = false
		$Dialoguebox/Options.hide()

func _input(event):
	if !$AnimationPlayer.is_playing() and $WaitTimer.time_left == 0 and canInput:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle"):
			if finished:
				if currPhrase.has("goto") or currPhrase.has("if"):
					next_dialog()
					$InputSound.play()
				elif currPhrase.has("options"):
					if event.is_action_pressed("ui_accept"):
						var option = options[$Dialoguebox/Arrow.cursor_index]
						$Dialoguebox/Arrow.hide()
						phraseNum = str2var(currPhrase["options"][option])
						for i in get_node("Dialoguebox/Options").get_children():
							get_node("Dialoguebox/Options").remove_child(i)
						select = 0
						selected = 0
						options.clear()
						clear_dialogue()
						nextPhrase()
						$InputSound.play()
						
					elif (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_toggle")) and currPhrase["options"].has("cancel"):
						$Dialoguebox/Arrow.hide()
						phraseNum = str2var(currPhrase["options"]["cancel"])
						for i in get_node("Dialoguebox/Options").get_children():
							get_node("Dialoguebox/Options").remove_child(i)
						select = 0
						selected = 0
						options.clear()
						clear_dialogue()
						nextPhrase()
				else:
					endDialogue()
			else:
				dialogueLabel.visible_characters = len(dialogueLabel.text)
				finish()

func getDialog() -> Dictionary:
	var f = File.new()

	if f.file_exists(global.dialogue):
		pass
	else:
		global.set_dialog("error", null)

	f.open(global.dialogue, File.READ)
	var json = f.get_as_text()
	
	var output = parse_json(json)
	
	if typeof(output) == TYPE_DICTIONARY:
		return output
	else:
		return {}

func nextPhrase() -> void:
	$WaitTimer.stop()
	canInput = true
	autoAdvance = false
	t = 0
	
	$Dialoguebox/Arrow.cursor_index = 0
	currPhrase = dialog[str(phraseNum)]
	
	if currPhrase.has("text"):
		currPhrase["text"] = globaldata.replaceText(currPhrase["text"])
	
	select = 0
	finished = false
	
	if phraseNum == 0:
		dialogueLabel.remove_line(1)
		dotLabel.remove_line(1)
	
	
	
	if currPhrase.has("cleardialog"):
		if currPhrase["cleardialog"]:
			clear_dialogue()
	
	# Set Dialogue
	if currPhrase.has("text"):
		show_box(true)
		
		dialogueLabel.bbcode_text += "\n" + currPhrase["text"]
		# add dot, assuming no options on this
		dotLabel.bbcode_text += "\n@"
		
		print(strip_bbcode(currPhrase["text"]))
		adjustDotSpacing(currPhrase["text"])
	
	if currPhrase.has("wait"):
		$WaitTimer.start(currPhrase["wait"])
	
	if currPhrase.has("caninput"):
		canInput = currPhrase["caninput"]
	else:
		canInput = true
	
	if currPhrase.has("autoadvance"):
		autoAdvance = currPhrase["autoadvance"]
	else:
		autoAdvance = false
	
	if currPhrase.has("showbox"):
		show_box(currPhrase["showbox"])
	
	# Parse Commands
	if currPhrase.has("commands"):
		for command in currPhrase["commands"]:
			var expression = Expression.new()
			expression.parse(command)
			var result = expression.execute([], self)
			print(result)  # 20
			
	
	if currPhrase.has("changescene"):
		_change_scene(currPhrase["changescene"])
	
	# Play object function
	if currPhrase.has("objectfunction"):
		var objects = currPhrase["objectfunction"]
		for i in objects:
			var object = global.currentScene.get_node(i)
			if object.has_method(objects[i]):
				object.call_deferred(objects[i])
	
	if currPhrase.has("ovbattlemusic"):
		audioManager.set_overworld_battle_music(currPhrase["ovbattlemusic"])
	
	if currPhrase.has("musicloop"):
		var music = ""
		if currPhrase.has("music"):
			music = currPhrase["music"]
		audioManager.add_audio_player()
		audioManager.play_music_from_id(music, currPhrase["musicloop"], audioManager.get_audio_player_count() - 1)
	elif currPhrase.has("music"):
		if currPhrase["music"] != "":
			audioManager.add_audio_player()
			audioManager.play_music_from_id(currPhrase["music"], "", audioManager.get_audio_player_count() - 1)
		else:
			audioManager.music_fadeout(0, 2)
	
	if currPhrase.has("musicvolume"):
		yield(get_tree(), "idle_frame")
		audioManager.music_fadeto(0, currPhrase["musicvolume"])
	
	if currPhrase.has("sound"):
		$AudioStreamPlayer.stream = load("res://Audio/Sound effects/text/" + currPhrase["sound"] +".mp3")
	else:
		$AudioStreamPlayer.stream = null
	
	if currPhrase.has("soundeffect"):
		audioManager.play_sfx(load("res://Audio/Sound effects/" + currPhrase["soundeffect"]), "dialogBoxSound")
	
	if currPhrase.has("font"):
		if currPhrase["font"] == "EBZ":
			$Dialoguebox/ClipBox/Dialogue.add_font_override("font",load("res://Fonts/saturn.tres"))
	
	#replace npcs with actors
	if currPhrase.has("actors"):
		actors = currPhrase["actors"]
		for i in actors:
			if actors[i] == "leader" or actors[i] == "player":
				actors[i] = global.persistPlayer
			elif actors[i] in global.partyMembers:
				var party = global.party + global.partyNpcs
				for partyMember in global.partyObjects.size():
					if party[partyMember]["name"] == str(actors[i]):
						actors[i] = global.partyObjects[partyMember]
			elif actors[i] == "talker":
				actors[i] = global.talker
			else:
				actors[i] = global.currentScene.get_node(str2var(actors[i]))
		for actor in actors:
			var newActor = actorChar.instance()
			actors[actor].get_parent().call_deferred("add_child_below_node", actors[actor], newActor)
			yield(newActor, "ready")
			newActor.replace_npc(actors[actor])
			actors[actor] = newActor
			global.add_persistent(newActor)
			global.add_persistent(newActor.replaced)
			if newActor.replaced.get("active"):
				newActor.replaced.active = false
				newActor.replaced.set_physics_process(false)
			
	
	#add a party member
	if currPhrase.has("setpartymembers"):
		for i in currPhrase["setpartymembers"]:
			if globaldata.get(i) in global.party:
				if global.partyObjects.size() > 1 and !currPhrase["setpartymembers"][i]:
					global.party.erase(globaldata.get(i))
			elif currPhrase["setpartymembers"][i]:
				global.party.append(globaldata.get(i)) 
		global.create_party_followers()
	
	#add a npc party member
	if currPhrase.has("setpartynpcs"):
		for i in currPhrase["setpartynpcs"]:
			if globaldata.get(i) in global.partyNpcs:
				if global.partyObjects.size() > 1 and !currPhrase["setpartynpcs"][i]:
					global.partyNpcs.erase(globaldata.get(i))
			elif currPhrase["setpartynpcs"][i]:
				global.partyNpcs.append(globaldata.get(i)) 
		global.create_party_followers()
	
	#change the npc an actor replaces
	if currPhrase.has("changereplaced"):
		for i in currPhrase["changereplaced"]:
			var replacement = null
			if currPhrase["changereplaced"][i] in global.partyMembers:
				var party = global.party + global.partyNpcs
				for partyMember in global.partyObjects.size():
					if party[partyMember]["name"] == str(currPhrase["changereplaced"][i]):
						replacement = global.partyObjects[partyMember]
						replacement.hide()
			else:
				replacement = global.currentScene.get_node(currPhrase["changereplaced"][i])
			actors[i].change_replaced(replacement)
	
	#Change talker
	if currPhrase.has("talker"):
		if !currPhrase["talker"] in ["null", "none", ""]:
			global.talker = actors[currPhrase["talker"]]
		else: 
			global.talker = null
	
	#teleports an actor to a spot instantly
	if currPhrase.has("teleportactors"):
		for i in currPhrase["teleportactors"]:
			actors[i].global_position = Vector2(currPhrase["teleportactors"][i]["x"], currPhrase["teleportactors"][i]["y"])
	
	#teleports the party to a location on the map
	if currPhrase.has("teleportparty"):
		var newPos = Vector2.ZERO
		if currPhrase["teleportparty"].has("x"):
			newPos.x = currPhrase["teleportparty"]["x"]
		if currPhrase["teleportparty"].has("y"):
			newPos.y = currPhrase["teleportparty"]["y"]
		global.persistPlayer.position = newPos
		if global.partySize > 1:
			for i in global.partySpace.size():
				global.partySpace.push_front(global.persistPlayer.position)
				global.partySpace.pop_back()
			for i in range(1, global.partyObjects.size()):
				global.partyObjects[i].position = global.persistPlayer.position
				global.partyObjects[i].initiate()
				global.partyObjects[i].disappear()
	
	#For setting multiple actor's 
	if currPhrase.has("actorsdir"):
		for i in currPhrase["actorsdir"]:
			var turner = actors[i]
			var direction = Vector2.ZERO
			if currPhrase["actorsdir"][i].has("x"):
				direction.x = currPhrase["actorsdir"][i]["x"]
			if currPhrase["actorsdir"][i].has("y"):
				direction.y = currPhrase["actorsdir"][i]["y"]
			turner.direction = direction
			turner.blend_position(direction)
				#turner.blend_position(direction)
	
	#stop an actor's looping movement
	if currPhrase.has("stopactorsloop"):
		for i in currPhrase["stopactorsloop"]:
			actors[i].stop_loop()
	
	#set if the actor's direction is set to their walk direction
	if currPhrase.has("actorsblend"):
		for i in currPhrase["actorsblend"]:
			actors[i].set_blending(currPhrase["actorsblend"][i])
	
	#set an actor's shadow
	if currPhrase.has("actorsshadow"):
		for i in currPhrase["actorsshadow"]:
			actors[i].set_shadow(currPhrase["actorsshadow"][i])
	
	#actor movements
	if currPhrase.has("actorsmove"):
		for i in currPhrase["actorsmove"]:
			var character = currPhrase["actorsmove"][i]
			var movingActor = actors[i]
			var positions := []
			var animation = ""
			var speed = 64
			var type = "0"
			var moonwalk = false
			var loop = false
			if character.has("movement"):
				var position = character["movement"]
				for j in character["movement"]:
					if j.has("wait"):
						positions.append(j["wait"])
					else:
						var vector2 = Vector2(j["x"],j["y"])
						positions.append(vector2)
			if character.has("animation"):
				animation = character["animation"]
			if character.has("speed"):
				speed = character["speed"]
			if character.has("type"):
				type = character["type"]
			if character.has("moonwalk"):
				moonwalk = character["moonwalk"]
			if character.has("loop"):
				loop = character["loop"]
			movingActor.move_queue(positions, animation, speed, type, moonwalk, loop)
	
	#For turning multiple actors' direction
	if currPhrase.has("actorsturn"):
		for i in currPhrase["actorsturn"]:
			var turner = actors[i]
			var direction = Vector2.ZERO
			var speed = 0.08
			var queue = false
			if currPhrase["actorsturn"][i].has("x"):
				direction.x = currPhrase["actorsturn"][i]["x"]
			if currPhrase["actorsturn"][i].has("y"):
				direction.y = currPhrase["actorsturn"][i]["y"]
			if currPhrase["actorsturn"][i].has("actor"):
				direction = turner.position.direction_to(actors[currPhrase["actorsturn"][i]["actor"]].position)
			if currPhrase["actorsturn"][i].has("speed"):
				speed = currPhrase["actorsturn"][i]["speed"]
			if currPhrase["actorsturn"][i].has("queue"):
				queue = currPhrase["actorsturn"][i]["queue"]
			turner.rotate_to(direction, speed, queue)
	
	#Make actor shake
	if currPhrase.has("actorsshake"):
		for i in currPhrase["actorsshake"]:
			var shaked = actors[i]
			var length = 1.0
			var magnitude = Vector2.ZERO
			var queue = false
			if currPhrase["actorsshake"][i].has("x"):
				magnitude.x = currPhrase["actorsshake"][i]["x"]
			if currPhrase["actorsshake"][i].has("y"):
				magnitude.y = currPhrase["actorsshake"][i]["y"]
			if currPhrase["actorsshake"][i].has("length"):
				length = currPhrase["actorsshake"][i]["length"]
			if currPhrase["actorsshake"][i].has("queue"):
				queue = currPhrase["actorsshake"][i]["queue"]
			shaked.shake(magnitude, length, queue)
	
	#Make actor jump
	if currPhrase.has("actorsjump"):
		for i in currPhrase["actorsjump"]:
			#height is how high in pixels the jump is, length is how long the jump lasts and times is how many times it happens
			var jumper = actors[i]
			var height = 8
			var speed = 0.2
			var times = 1
			var queue = false
			var crouch = false
			var shadow = true
			if currPhrase["actorsjump"][i].has("height"):
				height = currPhrase["actorsjump"][i]["height"]
			if currPhrase["actorsjump"][i].has("speed"):
				speed = currPhrase["actorsjump"][i]["speed"]
			if currPhrase["actorsjump"][i].has("length"):
				speed = currPhrase["actorsjump"][i]["length"]
			if currPhrase["actorsjump"][i].has("times"):
				times = currPhrase["actorsjump"][i]["times"]
			if currPhrase["actorsjump"][i].has("queue"):
				queue = currPhrase["actorsjump"][i]["queue"]
			if currPhrase["actorsjump"][i].has("shadow"):
				shadow = currPhrase["actorsjump"][i]["crouch"]
			if currPhrase["actorsjump"][i].has("crouch"):
				crouch = currPhrase["actorsjump"][i]["crouch"]
			jumper.jump(height, speed, times, queue, shadow, crouch)
	
	#Make actor animate
	if currPhrase.has("actorsanim"):
		for i in currPhrase["actorsanim"]:
			var animated = actors[i]
			var type = 0 #if type = 0, then use animationTree, if type = 1, then use animationPlayer
			var speed = 1.0
			var queue = false
			if currPhrase["actorsanim"][i].has("type"):
				type = currPhrase["actorsanim"][i]["type"]
			if currPhrase["actorsanim"][i].has("speed"):
				speed = currPhrase["actorsanim"][i]["speed"]
			if currPhrase["actorsanim"][i].has("queue"):
				queue = currPhrase["actorsanim"][i]["queue"]
			animated.play_anim(currPhrase["actorsanim"][i]["anim"], type, speed, queue)
	
	#erase an actor from a scene
	if currPhrase.has("eraseactors"):
		for i in currPhrase["eraseactors"]:
			if currPhrase["eraseactors"][i] == true:
				if global.talker == actors[i]:
					global.talker = null
				global.persistArray.erase(actors[i].replaced)
				global.persistArray.erase(actors[i])
				actors[i].replaced.queue_free()
				actors[i].queue_free()
				actors.erase(i)
	
	#Make the player emote
	if currPhrase.has("emoteplayer"):
		global.persistPlayer.emotes.animaPlayer.play(currPhrase["emoteplayer"])
	
	#A simple way of getting the talker to emote
	if currPhrase.has("emotenpc"):
		if global.talker != null:
			global.talker.emotes.animaPlayer.play(currPhrase["emotenpc"])
	
	#Make specific actor play an emote
	if currPhrase.has("emoteactors"):
		for i in currPhrase["emoteactors"]:
			var emoter = actors[i]
			emoter.emotes.animaPlayer.play(currPhrase["emoteactors"][i])
	
	#Shake camera
	if currPhrase.has("shakecam"):
		var size = str(currPhrase["shakecam"]["size"])
		var length = 0.2
		var direction = Vector2.ONE
		if currPhrase["shakecam"].has("length"):
			length = currPhrase["shakecam"]["length"]
		if currPhrase["shakecam"].has("x"):
			direction.x = currPhrase["shakecam"]["x"]
		if currPhrase["shakecam"].has("y"):
			direction.y = currPhrase["shakecam"]["y"]
		match size:
			"small":
				Input.start_joy_vibration(0, 0.4, 0.3, length)
				global.currentCamera.shake_camera(2, length, direction)
			"medium":
				Input.start_joy_vibration(0, 0.5, 0.6, length)
				global.currentCamera.shake_camera(4, length, direction)
			"big":
				Input.start_joy_vibration(0, 0.7, 0.8, length)
				global.currentCamera.shake_camera(6, length, direction)
	
	#Set current camera
	if currPhrase.has("changecam"):
		if currPhrase["changecam"] == "none" or currPhrase["changecam"] == "null"  or currPhrase["changecam"] == "":
			camera.set_current()
		else:
			actors[currPhrase["changecam"]].camera.set_current()
	
	#Move camera to a position on the map. 
	#You can set it to an actor to move the camera to the actor's position
	#Or you can set it to a coordinate on the map with "x" and "y". If one of them isn't there, it'll just default to the currentCamera's x or y
	if currPhrase.has("movecam"):
		var camX = global.currentCamera.global_position.x
		var camY = global.currentCamera.global_position.y
		var time = 1.0
		if currPhrase["movecam"].has("actor"): #moves camera to actor
			if currPhrase["movecam"]["actor"] == "parent":
				camX = global.currentCamera.get_parent().global_position.x
				camY = global.currentCamera.get_parent().global_position.y
			else:
				camX = actors[currPhrase["movecam"]["actor"]].global_position.x
				camY = actors[currPhrase["movecam"]["actor"]].global_position.y
		else:
			if currPhrase["movecam"].has("x"):
				camX = currPhrase["movecam"]["x"]
			if currPhrase["movecam"].has("y"):
				camY = currPhrase["movecam"]["y"]
		if currPhrase["movecam"].has("length"):
			time = currPhrase["movecam"]["length"]
		global.currentCamera.move_camera(camX, camY, time)
	
	#Return camera to parent. "returncam" is equal to the time it takes for the camera to go back to the original position
	if currPhrase.has("returncam"):
		global.currentCamera.return_camera(currPhrase["returncam"])
	
	#make fade focus on a position or actor
	if currPhrase.has("fadefocus"):
		uiManager.fade.focus_object(actors[currPhrase["fadefocus"]])
	
	#Fade in
	if currPhrase.has("fadein"):
		var color = Color.black
		var speed = 1.0
		if currPhrase["fadein"].has("speed"):
			speed = currPhrase["fadein"]["speed"]
		if currPhrase["fadein"].has("color"):
			color = Color(currPhrase["fadein"]["color"])
		uiManager.fade.fade_in(currPhrase["fadein"]["anim"],color, speed)
	
	#Fade out
	if currPhrase.has("fadeout"):
		var color = Color.black
		var speed = 1
		if currPhrase["fadeout"].has("speed"):
			speed = currPhrase["fadeout"]["speed"]
		if currPhrase["fadeout"].has("color"):
			color = Color(currPhrase["fadeout"]["color"])
		uiManager.fade.fade_out(currPhrase["fadeout"]["anim"],color, speed)
	
	#Set fade cut
	if currPhrase.has("fadesize"):
		var speed = 1.0
		
		uiManager.fade.set_cut(currPhrase["fadesize"]["size"])
	
	
	#make the fade spin, only works if it's a circle fade.
	if currPhrase.has("fadespin"):
		if currPhrase["fadespin"]:
			uiManager.fade.toggle_spin()
	
	#Enable flag
	if currPhrase.has("flag"):
		var flag = str(currPhrase["flag"])
		if globaldata.flags.has(flag):
			globaldata.flags[flag] = true
	
	#Disable flag
	if currPhrase.has("unflag"):
		var flag = str(currPhrase["unflag"])
		if globaldata.flags.has(flag):
			globaldata.flags[flag] = false
	
	#set respawn point at the end of the cutscene
	if currPhrase.has("setrespawn"):
		setRespawn = currPhrase["setrespawn"]
	
	
	# Parse Options
	if currPhrase.has("options"):
		for i in get_node("Dialoguebox/Options").get_children():
			get_node("Dialoguebox/Options").remove_child(i)
		options.clear()
		dialogueLabel.bbcode_text += "\n"
		dotLabel.bbcode_text += "\n"
		var optionNode = load("res://Nodes/Ui/DialogueOptions.tscn")
		select = 0
		selected = 0
		for i in currPhrase["options"]:
			var nickname = ""
			var canAppend = true
			if i == "chkninten" or i == "chklloyd" or i == "chkana" or i == "chkteddy" or i == "chkpippi":
				var actualName
				canAppend = false
				nickname = i.replace("chk", "")
				for member in global.party.size():
					if global.party[member]["name"] == nickname:
						nickname = global.party[member]["nickname"]
						canAppend = true
						break
			if nickname == "":
				nickname = i
			if canAppend and i != "cancel":
				var option = optionNode.instance()
				get_node("Dialoguebox/Options").add_child(option)
				option.text = nickname
				option.set_name(nickname)
				options.append(i)
				select += 1
		$Dialoguebox/Arrow.global_position = $Dialoguebox/Options.get_child(0).rect_global_position + Vector2(-5,5)
	
	# Set Name
	if currPhrase.has("name"):
		currPhrase["name"] = globaldata.replaceText(currPhrase["name"])
		var old_name = nameLabel.text
		nameLabel.text = str(currPhrase["name"])
		if $Dialoguebox/Namebox.rect_position.y != -15 :
			$NameAnim.play("Open")
			if !currPhrase.has("cleardialog"):
				clear_dialogue()
				dialogueLabel.bbcode_text += "\n" + currPhrase["text"]
				# add dot, assuming no options on this
				dotLabel.bbcode_text += "\n@"
				adjustDotSpacing(currPhrase["text"])
		
		elif old_name != currPhrase["name"]:
			if phraseNum != 0:
				if !currPhrase.has("cleardialog"):
					clear_dialogue()
					dialogueLabel.bbcode_text += "\n" + currPhrase["text"]
					# add dot, assuming no options on this
					dotLabel.bbcode_text += "\n@"
					adjustDotSpacing(currPhrase["text"])
	else:
		var old_name = nameLabel.text
		nameLabel.text = ""
		if $Dialoguebox/Namebox.rect_position.y != 0:
			$NameAnim.play("Close")
		if old_name != nameLabel.text and phraseNum != 0:
			if !currPhrase.has("cleardialog"):
				clear_dialogue()
			if currPhrase.has("text"):
				
				dialogueLabel.bbcode_text += "\n" + currPhrase["text"]
				# add dot, assuming no options on this
				dotLabel.bbcode_text += "\n@"
				adjustDotSpacing(currPhrase["text"])
	
	#Save game
	if currPhrase.has("save"):
		uiManager.open_save()
	
	#Toggle cashBox
	if currPhrase.has("cash"):
		if currPhrase["cash"] == false:
			uiManager.cash.close()
		else:
			uiManager.cash.open()
	#Give/Remove Money
	if currPhrase.has("givecash"):
		globaldata.cash += currPhrase["givecash"]
		uiManager.cash.update()
	#Heal Party Members
	if currPhrase.has("heal"):
		var character = str(currPhrase["heal"])
		if character != "All" and character != "all":
			if !globaldata[character]["status"].has(globaldata.ailments.Unconscious):
				globaldata[character]["hp"] = globaldata[character]["maxhp"] + globaldata[character]["boosts"]["maxhp"]
		else:
			for i in global.party:
				i.hp = i.maxhp + i.boosts.maxhp
	#Restore PP
	if currPhrase.has("restorepp"):
		var character = str(currPhrase["restorepp"])
		if character != "All":
			globaldata[character]["pp"] = globaldata[character]["maxpp"] + globaldata[character]["boosts"]["maxpp"]
		else:
			for i in global.party:
				i.pp = i.maxpp + i.boosts.maxpp
	#Cure Status
	if currPhrase.has("cure"):
		var character = str(currPhrase["cure"]["character"])
		var status = str(currPhrase["cure"]["status"])
		if character != "All":
			if status != "All":
				globaldata[character]["status"].erase(globaldata.ailments[status])
				if status == "Unconscious":
					globaldata[character]["hp"] = globaldata[character]["maxhp"] + globaldata[character]["boosts"]["maxhp"]
			else:
				globaldata[character]["status"].clear()
		else:
			if status != "All":
				for i in global.party:
					i.status.erase(globaldata.ailments[status])
					if status == "Unconscious":
						i.hp = i.maxhp
			else:
				for i in global.party:
					i.status.clear()
					if i.hp <= 0:
						i.hp = i.maxhp
		for i in global.partyObjects:
			i._spritesheet()
	
	if currPhrase.has("givestatus"):
		for character in currPhrase["givestatus"]:
			var status = str(currPhrase["givestatus"][character])
			globaldata.give_status(character, status)
	
	if currPhrase.has("openshop"):
		uiManager.open_shop(currPhrase.openshop)
	
	if currPhrase.has("use_atm"):
		if currPhrase["use_atm"]:
			uiManager.open_atm()
	
	
	#Give Item
	if currPhrase.has("item"):
		var item = InventoryManager.Load_item_data(currPhrase["item"])
		item_not_given = true #check if the item is given or not, if the item is not given, it will go to "inv_full" instead of "goto"
		if InventoryManager.hasInventorySpace():
			item_not_given = false
		if item.has("keyitem"):
			if item["keyitem"]:
				item_not_given = false
		InventoryManager.giveItemAvailable(currPhrase["item"])
	
	#Take Item
	if currPhrase.has("removeitem"):
		
		if InventoryManager.checkItemForAll(currPhrase["removeitem"]):
			InventoryManager.removeItem(currPhrase["removeitem"])

	#Start battle with current NPC
	if currPhrase.has("battler"):
		var battler = currPhrase["battler"]
		var enemy = currPhrase["battler"]["enemy"]
		var actor = null
		if currPhrase["battler"]["actor"] != "":
			if currPhrase["battler"]["actor"] == "talker":
				actor = global.talker
			else:
				actor = actors[currPhrase["battler"]["actor"]]
			actor.drafted = true
			if currPhrase["battler"].has("keep"):
				actor.keepAfterBattle = currPhrase["battler"]["keep"]
		uiManager.onScreenEnemies.append([enemy, actor])
		uiManager.update_enemy_ids()
		queued_battle = true
		print("queuing battle")
	
	if !currPhrase.has("text") and !currPhrase.has("wait"):
		next_dialog()
	
	if currPhrase.has("learnskills"):
		var partymembres = currPhrase["learnskills"]
		for i in partymembres:
			globaldata[i]["learnedSkills"].append(partymembres[i])
	
	#play cutscene after winning after the battle
	if currPhrase.has("batwincutscene"):
		uiManager.battleWinCutscene = currPhrase["batwincutscene"]
	
	#play cutscene after fleeing after the battle
	if currPhrase.has("batfleecutscene"):
		uiManager.battleFleeCutscene = currPhrase["batfleecutscene"]
	
	#play cutscene after being defeated after the battle
	if currPhrase.has("batlosecutscene"):
		uiManager.battleLoseCutscene = currPhrase["batlosecutscene"]
	
	#set a flag to true after winning a battle
	if currPhrase.has("batwinflag"):
		uiManager.battleWinFlag = currPhrase["batwinflag"]
	
	#fully heal player or party after losing a battle
	if currPhrase.has("batloseheal"):
		uiManager.battleLoseHeal = currPhrase["batloseheal"]
	
	#unpause the player or not once the dialog sequence is done
	if currPhrase.has("unpauseplayer"):
		unpausePlayer = currPhrase["unpauseplayer"]

func endDialogue():
	Input.action_release("ui_cancel")
	Input.action_release("ui_toggle")
	Input.action_release("ui_accept")
	clear_dialogue()
	remove_dialog_box()
	$AudioStreamPlayer.volume_db = -80
	$Dialoguebox/ClipBox/Dialogue.hide()
	if unpausePlayer:
		global.persistPlayer.unpause()
	global.cutscene = false
	if global.talker != null:
		global.talker.talking = false
	if nameLabel.text != "":
		$NameAnim.play("Close")
	uiManager.blackBars.close()
	uiManager.cash.close()
	uiManager.set_telepathy_effect(false)
	
	if actors.size() != 0:
		for i in actors:
			if !queued_battle:
				actors[i].update_npcs()
			elif !actors[i].drafted:
				actors[i].update_npcs()
			else:
				global.remove_persistent(actors[i])
				global.remove_persistent(actors[i].replaced)
	
		#update partyMember path
		if global.partySize > 1:
			var partyMembers = global.partyObjects.duplicate()
			
			partyMembers.invert()
			for i in global.partySpace.size():
				global.partySpace.push_front(partyMembers[0].position)
				global.partySpace.pop_back()
			
			for i in partyMembers.size() - 1:
				var maxDist = round(max(abs(partyMembers[i].position.x-partyMembers[i + 1].position.x), abs(partyMembers[i].position.y-partyMembers[i + 1].position.y)))
				if maxDist > 0:
					for dist in maxDist + 1:
						global.partySpace.push_front(lerp(partyMembers[i].position, partyMembers[i+1].position.round(), (dist+1)/maxDist))
						global.partySpace.pop_back()
				
				partyMembers[i].set_physics_process(true)
				partyMembers[i].find_path()
				partyMembers[i].active = true
	
	if global.talker != null:
		global.talker.pause = false
		global.talker = null
	if uiManager.check_keys(global.currentScene.name) > 0:
		uiManager.key.open()
	if queued_battle:
		var canRun = false
		uiManager.start_battle(0, canRun)
		global.currentCamera.get_node("Tween").set_active(false)
	else:
		global.currentCamera.return_camera(0.5)
		global.currentCamera.return_offset(0.5)
		if setRespawn:
			global.set_respawn()
	emit_signal("done")
	emit_signal("finalPhrase", phraseNum)
	global.emit_signal("cutscene_ended")
	phraseNum = 0

func adjustDotSpacing(line):
	line = strip_bbcode(line)
	var font = dialogueLabel.get_font("normal_font")
	var lineSize = font.get_wordwrap_string_size(line, dialogueLabel.rect_size.x)
	if lineSize.y > font.get_height():
		dotLabel.bbcode_text += "\n".repeat(int(floor(lineSize.y/font.get_height()) - 1))

func clear_dialogue():
	dialogueLabel.bbcode_text = ""
	dotLabel.bbcode_text = ""
	dialogueLabel.visible_characters = 0

func next_dialog():
	if currPhrase.has("if"):
		var condition = true
		for cond in currPhrase["if"]:
			if currPhrase["if"].has("or") and cond != "or" and cond != "goto":
				condition = true
			#Check if the player does or doesn't have enough inventory space
			if "hascash" in cond:
				if globaldata.cash < currPhrase["if"]["hascash"]:
					condition = false
					if !currPhrase["if"].has("or"):
						break
			#Check if the player does or doesn't have enough inventory space
			if "invspace" in cond:
				if InventoryManager.hasInventorySpace() != currPhrase["if"]["invspace"]:
					condition = false
					if !currPhrase["if"].has("or"):
						break
			#Check if the player has a certain item
			if "hasitem" in cond:
				if !InventoryManager.checkItemForAll(currPhrase["if"][cond]):
					condition = false
					if !currPhrase["if"].has("or"):
						break
			#Check if the leader is a certain character
			if "leader" in cond:
				if global.party[0]["name"] != currPhrase["if"]["leader"]:
					condition = false
					if !currPhrase["if"].has("or"):
						break
			#Check if the player has certain party members
			if "haspartymembers" in cond:
				var hasPartyMember = true
				for memberName in currPhrase["if"]["haspartymembers"]:
					var hasMember = false
					for member in global.party.size():
						if global.party[member]["name"] == memberName:
							hasMember = true
							if !currPhrase["if"].has("or"):
								break
					if hasMember != currPhrase["if"]["haspartymembers"][memberName]:
						condition = false
						hasPartyMember = false
						if !currPhrase["if"].has("or"):
							break
				if !hasPartyMember:
					if !currPhrase["if"].has("or"):
						break
			#Check if the party has enough members
			if "partysize" in cond:
				condition = false
				match currPhrase["if"][cond]["symbol"]:
					">":
						if global.party.size() > currPhrase["if"][cond]["size"]:
							condition = true
					">=":
						if global.party.size() >= currPhrase["if"][cond]["size"]:
							condition = true
					"<":
						if global.party.size() < currPhrase["if"][cond]["size"]:
							condition = true
					"<=":
						if global.party.size() <= currPhrase["if"][cond]["size"]:
							condition = true
					"=":
						if global.party.size() == currPhrase["if"][cond]["size"]:
							condition = true
				if !condition:
					if !currPhrase["if"].has("or"):
						break
			#Check if character has status
			if "hasstatus" in cond:
				var hasStatus = true
				var status = currPhrase["if"][cond]["status"]
				var character = currPhrase["if"][cond]["character"]
				for member in global.party.size():
					if global.party[member]["name"] == character:
						if status != "":
							if !global.party[member]["status"].has(globaldata.ailments[str2var(status)]):
								condition = false
								hasStatus = false
								break
						else:
							if global.party[member]["status"].size() != 0:
								condition = false
								hasStatus = false
								break
				if !hasStatus:
					if !currPhrase["if"].has("or"):
						break
						
			#Check if certain flags in globalData are true or false
			if "flags" in cond:
				var flagCorrect = true
				for flagName in currPhrase["if"]["flags"]:
					if globaldata.flags[flagName] != currPhrase["if"]["flags"][flagName]:
						condition = false
						flagCorrect = false
						if !currPhrase["if"].has("or"):
							break
				if !flagCorrect:
					if !"or" in currPhrase["if"]:
						break
			if currPhrase["if"].has("or"):
				if condition:
					break
		if condition: #check if all of these are true to go to this "goto"
			phraseNum = str2var(currPhrase["if"]["goto"])
			nextPhrase()
		elif currPhrase.has("goto"): #else, it goes to the regular "goto"
			phraseNum = str2var(currPhrase["goto"])
			nextPhrase()
		else:
			endDialogue()
	elif currPhrase.has("goto"):
		phraseNum = str2var(currPhrase["goto"])
		nextPhrase()
	else:
		endDialogue()

func show_box(show):
	if show and $Dialoguebox.rect_position.y != 120:
		$AnimationPlayer.play("Open")
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_open.wav"), "menu_open")
	if !show and $Dialoguebox.rect_position.y != 180:
		$AnimationPlayer.play("Close")
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_close.wav"), "menu_close")
		clear_dialogue()

func set_nametag():
	var new_size = nameLabel.rect_size.x + 20
	var old_size = $Dialoguebox/Namebox.rect_size.x 
	if new_size != old_size:
		$Tween.interpolate_property($Dialoguebox/Namebox, "rect_size", 
			Vector2(old_size, 47), Vector2(new_size, 47), 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.start()
		
		$Tween.interpolate_property(nameLabel, "percent_visible", 
			0 / nameLabel.rect_size.x, 1, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.start()
	else:
		$Dialoguebox/Namebox.rect_size.x = nameLabel.rect_size.x + 20

func remove_dialog_box():
	if $Dialoguebox.rect_position.y != 180:
		$AnimationPlayer.play("Close")
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_close.wav"), "menu_close")
		yield($AnimationPlayer, "animation_finished")
	uiManager.remove_ui(self)

func strip_bbcode(source:String) -> String:
	var regex = RegEx.new()
	regex.compile("\\[.+?\\]")
	return regex.sub(source, "", true)

func _on_WaitTimer_timeout():
	$Dialoguebox/Cursor_Down.show()
	if autoAdvance:
		next_dialog()

func _change_scene(targetScene):
	global.goto_scene("res://Maps/" + targetScene + ".tscn")
	
	var cam = global.currentCamera
	cam.limit_top = -10000000
	cam.limit_left = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000
	cam.smoothing_enabled = false
