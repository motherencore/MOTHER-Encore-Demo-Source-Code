extends AbstractDialogueBox

signal done
signal end_gameover(try_again)

# node refs
onready var _name_label := $Dialoguebox/Namebox/ClipBox/Name
onready var _options_grid := $Dialoguebox/Options
onready var _camera := $Camera2D
onready var ActorChar := preload("res://Nodes/Reusables/actor.tscn")

var unpausePlayer = true
var actors := {}
var _item_not_given := false
var _options_count := 0
var _options := []
var _queued_battle := false
var _can_input := true
var _set_respawn := false
var _dialogue_box_shown := false
var _name_box_shown := false

func _ready():
	_dialogue_box_node = $Dialoguebox
	_dialogue_label = $Dialoguebox/ClipBox/HBoxContainer/Dialogue
	_bullet_label = $Dialoguebox/ClipBox/HBoxContainer/DippinDots
	_cursor_down_sprite = $Dialoguebox/Cursor_Down
	_name_label.connect("item_rect_changed", self, "_set_nametag")
	Input.action_release("ui_cancel")
	Input.action_release("ui_accept")
	global.cutscene = true
	global.persistPlayer.pause()
	uiManager.close_key_indicator()
	$Dialoguebox/Arrow.hide()
	uiManager.toggle_black_bars(true)
	_dialog = _get_dialog()
	_dialogue_label.visible_characters = 0
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	if _dialog:
		_handle_phrase()

# Override
func _advance_printing(delta):
	._advance_printing(delta)

	if !_dialogue_label.visible_characters >= len(_get_no_br_dialog_content()):
		if global.talker != null and _curr_phrase.has("text"):
			if _curr_phrase["text"] != "":
				global.talker.talking = true
	else:
		if global.talker != null:
			global.talker.talking = false

func _print_new_line():
	_dialogue_label.bbcode_text += "\n"
	_bullet_label.bbcode_text += "\n"

func _finish_phrase():
	_finished = true
	_add_dialog_options()
	if $WaitTimer.time_left == 0 and _can_input:
		_cursor_down_sprite.show()
		if _auto_advance:
			next_phrase()

# Override
func _action_press(btn_next := false, btn_cancel := false):
	if !$AnimationPlayer.is_playing() and $WaitTimer.time_left == 0 and _can_input:
		if !_finished and !_stopped:
			if btn_cancel:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_B
			else:
				_speed_multiplier_from_input = SPEED_UP_FROM_PRESS_A
		elif btn_next:
			if _finished:
				if _curr_phrase.has("options"):
					var option = _options[$Dialoguebox/Arrow.cursor_index]
					if btn_cancel and _curr_phrase["options"].has("cancel"):
						option = "cancel"
					if _curr_phrase["options"][option]:
						_phrase_num = str2var(_curr_phrase["options"][option])
					else:
						_end_dialogue()
					$Dialoguebox/Arrow.hide()
					for i in _options_grid.get_children():
						i.hide()
					_options_count = 0
					_options.clear()
					_clear_dialogue()
					_handle_phrase()
					$InputSound.play()
				else:
					next_phrase(true)
			elif _stopped:
				_stopped = false
				$InputSound.play()

func _get_dialog() -> Dictionary:
	if !global.dialogue:
		return {}
		
	var f := File.new()

	if f.file_exists(global.dialogue[0][0]):
		pass
	else:
		global.dialogue.clear()
		global.set_dialog("error")

	f.open(global.dialogue[0][0], File.READ)
	var yaml := f.get_as_text()
	
	var output = globaldata.parse_yaml(yaml)
	
	global.talker = global.dialogue[0][1]
	global.dialogue.pop_front()
	
	if typeof(output) == TYPE_DICTIONARY:
		return output
	else:
		return {}

# Override
func _handle_phrase() -> void:
	$WaitTimer.stop()
	_can_input = true
	_auto_advance = false
	_speed_multiplier_from_input = 1
	_speed_multiplier_from_tags = 1
	_t = 0
	
	$Dialoguebox/Arrow.cursor_index = 0
	_curr_phrase = _dialog.get(str(_phrase_num), {})
	
	_options_count = 0
	_finished = false
	
	if _phrase_num == 0:
		_dialogue_label.remove_line(1)
		_bullet_label.remove_line(1)
	
	
	#Give Item (this has to be handled before the text, in case the [ItemReceiver] is mentionned in dialogue)
	if _curr_phrase.has("item"):
		var item = InventoryManager.Load_item_data(_curr_phrase["item"])
		_item_not_given = true #check if the item is given or not, if the item is not given, it will go to "inv_full" instead of "goto"
		if InventoryManager.has_inventory_space():
			_item_not_given = false
		if item.get("keyitem", false):
			_item_not_given = false
		InventoryManager.add_item_available(_curr_phrase["item"])
	
	
	if _curr_phrase.has("cleardialog"):
		if _curr_phrase["cleardialog"]:
			_clear_dialogue()
	
	# Set Dialogue
	if _curr_phrase.has("text"):
		_curr_phrase["text"] = TextTools.add_line_breaks(TextTools.replace_text(_curr_phrase["text"]), _dialogue_label)

		_show_box(true, _curr_phrase.get("boxsound", true))
		
		_print_dialogue_segment(true)
	
	if _curr_phrase.has("wait"):
		$WaitTimer.start(_curr_phrase["wait"])
	
	if _curr_phrase.has("caninput"):
		_can_input = _curr_phrase["caninput"]
	else:
		_can_input = true
	
	if _curr_phrase.has("autoadvance"):
		_auto_advance = _curr_phrase["autoadvance"]
	else:
		_auto_advance = false
	
	if _curr_phrase.has("showbox"):
		_show_box(_curr_phrase["showbox"], _curr_phrase.get("boxsound", true))
	
	# Parse Commands
	if _curr_phrase.has("commands"):
		for command in _curr_phrase["commands"]:
			var expression = Expression.new()
			expression.parse(command)
			var result = expression.execute([], self)
			print(result)  # 20
			
	
	if _curr_phrase.has("changescene"):
		_change_scene(_curr_phrase["changescene"])
	
	# Play object function
	if _curr_phrase.has("objectfunction"):
		var objects = _curr_phrase["objectfunction"]
		for i in objects:
			var object = global.currentScene.get_node_or_null(i)
			if object != null and object.has_method(objects[i]):
				object.call_deferred(objects[i])
	
	if _curr_phrase.has("ovbattlemusic"):
		audioManager.set_overworld_battle_music(_curr_phrase["ovbattlemusic"])
	
	if _curr_phrase.has("musicloop"):
		var music = ""
		if _curr_phrase.has("music"):
			music = _curr_phrase["music"]
		audioManager.add_audio_player()
		audioManager.play_music_on_latest_player(music, _curr_phrase["musicloop"])
	elif _curr_phrase.has("music"):
		if _curr_phrase["music"] != "":
			audioManager.add_audio_player()
			audioManager.play_music_on_latest_player(_curr_phrase["music"], "")
		else:
			audioManager.music_fadeout(0, 2)
	
	if _curr_phrase.has("musicvolume"):
		yield(get_tree(), "idle_frame")
		audioManager.music_fadeto(0, _curr_phrase["musicvolume"])
	
	if _curr_phrase.get("sound", null):
		if !_curr_phrase["sound"].begins_with("res://"):
			_curr_phrase["sound"] = "res://Audio/Sound effects/text/" + _curr_phrase["sound"]
		$AudioStreamPlayer.stream = load(_curr_phrase["sound"] +".mp3")
	else:
		$AudioStreamPlayer.stream = null
	
	if _curr_phrase.has("soundeffect"):
		if !_curr_phrase["soundeffect"].begins_with("res://"):
			_curr_phrase["soundeffect"] = "res://Audio/Sound effects/" + _curr_phrase["soundeffect"]
		audioManager.play_sfx(load(_curr_phrase["soundeffect"]), "dialogBoxSound")
	
	if _curr_phrase.has("font"):
		if _curr_phrase["font"] == "EBZ" or _curr_phrase["font"] == "Saturn":
			_dialogue_label.add_font_override("normal_font",load("res://Fonts/saturn.tres"))
			_bullet_label.add_font_override("normal_font",load("res://Fonts/saturn.tres"))
	
	#replace npcs with actors
	if _curr_phrase.has("actors"):
		actors = _curr_phrase["actors"]
		for i in actors:
			actors[i] = _actor_strings_to_node(actors[i])
		for actor in actors:
			var newActor = ActorChar.instance()
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
	if _curr_phrase.has("setpartymembers"):
		for i in _curr_phrase["setpartymembers"]:
			if globaldata.get(i) in global.party:
				if global.partyObjects.size() > 1 and !_curr_phrase["setpartymembers"][i]:
					global.party.erase(globaldata.get(i))
			elif _curr_phrase["setpartymembers"][i]:
				global.party.append(globaldata.get(i)) 
		global.emit_signal("party_changed")
		global.create_party_followers()
	
	#add a npc party member
	if _curr_phrase.has("setpartynpcs"):
		for i in _curr_phrase["setpartynpcs"]:
			if globaldata.get(i) in global.partyNpcs:
				if global.partyObjects.size() > 1 and !_curr_phrase["setpartynpcs"][i]:
					global.partyNpcs.erase(globaldata.get(i))
			elif _curr_phrase["setpartynpcs"][i]:
				global.partyNpcs.append(globaldata.get(i)) 
		global.emit_signal("party_changed")
		global.create_party_followers()
	
	#change the npc an actor replaces
	if _curr_phrase.has("changereplaced"):
		for i in _curr_phrase["changereplaced"]:
			var replacement = _actor_strings_to_node(_curr_phrase["changereplaced"][i])
			if replacement in global.partyObjects:
				replacement.hide()
			actors[i].change_replaced(replacement)
	
	if _curr_phrase.has("mutetalker"):
		if global.talker != null:
			global.talker.mute = _curr_phrase["mutetalker"]
	
	#Change talker
	if _curr_phrase.has("talker"):
		if _curr_phrase["talker"]:
			global.talker = actors[_curr_phrase["talker"]]
		else: 
			global.talker = null
	
	
	#teleports an actor to a spot instantly
	if _curr_phrase.has("teleportactors"):
		for i in _curr_phrase["teleportactors"]:
			actors[i].global_position = Vector2(_curr_phrase["teleportactors"][i]["x"], _curr_phrase["teleportactors"][i]["y"])
	
	#teleports the party to a location on the map
	if _curr_phrase.has("teleportparty"):
		var newPos = Vector2.ZERO
		if _curr_phrase["teleportparty"].has("x"):
			newPos.x = _curr_phrase["teleportparty"]["x"]
		if _curr_phrase["teleportparty"].has("y"):
			newPos.y = _curr_phrase["teleportparty"]["y"]
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
	if _curr_phrase.has("actorsdir"):
		for i in _curr_phrase["actorsdir"]:
			var turner = actors[i]
			var direction = Vector2.ZERO
			if _curr_phrase["actorsdir"][i].has("x"):
				direction.x = _curr_phrase["actorsdir"][i]["x"]
			if _curr_phrase["actorsdir"][i].has("y"):
				direction.y = _curr_phrase["actorsdir"][i]["y"]
			turner.direction = direction
			turner.blend_position(direction)
				#turner.blend_position(direction)
	
	#stop an actor's looping movement
	if _curr_phrase.has("stopactorsloop"):
		for i in _curr_phrase["stopactorsloop"]:
			actors[i].stop_loop()
	
	#set if the actor's direction is set to their walk direction
	if _curr_phrase.has("actorsblend"):
		for i in _curr_phrase["actorsblend"]:
			actors[i].set_blending(_curr_phrase["actorsblend"][i])
	
	#set an actor's shadow
	if _curr_phrase.has("actorsshadow"):
		for i in _curr_phrase["actorsshadow"]:
			actors[i].set_shadow(_curr_phrase["actorsshadow"][i])
	
	#actor movements
	if _curr_phrase.has("actorsmove"):
		for i in _curr_phrase["actorsmove"]:
			var character = _curr_phrase["actorsmove"][i]
			var movingActor = actors[i]
			var positions := []
			var animation := ""
			var speed: float = 64.0
			var type := "0"
			var moonwalk := false
			var loop := false
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
	if _curr_phrase.has("actorsturn"):
		for i in _curr_phrase["actorsturn"]:
			var turner = actors[i]
			var direction = Vector2.ZERO
			var speed = 0.08
			var queue = false
			if _curr_phrase["actorsturn"][i].has("x"):
				direction.x = _curr_phrase["actorsturn"][i]["x"]
			if _curr_phrase["actorsturn"][i].has("y"):
				direction.y = _curr_phrase["actorsturn"][i]["y"]
			if _curr_phrase["actorsturn"][i].has("actor"):
				direction = turner.position.direction_to(actors[_curr_phrase["actorsturn"][i]["actor"]].position)
			if _curr_phrase["actorsturn"][i].has("speed"):
				speed = _curr_phrase["actorsturn"][i]["speed"]
			if _curr_phrase["actorsturn"][i].has("queue"):
				queue = _curr_phrase["actorsturn"][i]["queue"]
			turner.rotate_to(direction, speed, queue)
	
	#Make actor shake
	if _curr_phrase.has("actorsshake"):
		for i in _curr_phrase["actorsshake"]:
			var shaked = actors[i]
			var length = 1.0
			var magnitude = Vector2.ZERO
			var queue = false
			if _curr_phrase["actorsshake"][i].has("x"):
				magnitude.x = _curr_phrase["actorsshake"][i]["x"]
			if _curr_phrase["actorsshake"][i].has("y"):
				magnitude.y = _curr_phrase["actorsshake"][i]["y"]
			if _curr_phrase["actorsshake"][i].has("length"):
				length = _curr_phrase["actorsshake"][i]["length"]
			if _curr_phrase["actorsshake"][i].has("queue"):
				queue = _curr_phrase["actorsshake"][i]["queue"]
			shaked.shake(magnitude, length, queue)
	
	#Make actor jump
	if _curr_phrase.has("actorsjump"):
		for i in _curr_phrase["actorsjump"]:
			#height is how high in pixels the jump is, length is how long the jump lasts and times is how many times it happens
			var jumper = actors[i]
			var height = 8
			var speed = 0.2
			var times = 1
			var queue = false
			var crouch = false
			var shadow = true
			if _curr_phrase["actorsjump"][i].has("height"):
				height = _curr_phrase["actorsjump"][i]["height"]
			if _curr_phrase["actorsjump"][i].has("speed"):
				speed = _curr_phrase["actorsjump"][i]["speed"]
			if _curr_phrase["actorsjump"][i].has("length"):
				speed = _curr_phrase["actorsjump"][i]["length"]
			if _curr_phrase["actorsjump"][i].has("times"):
				times = _curr_phrase["actorsjump"][i]["times"]
			if _curr_phrase["actorsjump"][i].has("queue"):
				queue = _curr_phrase["actorsjump"][i]["queue"]
			if _curr_phrase["actorsjump"][i].has("shadow"):
				shadow = _curr_phrase["actorsjump"][i]["crouch"]
			if _curr_phrase["actorsjump"][i].has("crouch"):
				crouch = _curr_phrase["actorsjump"][i]["crouch"]
			jumper.jump(height, speed, times, queue, shadow, crouch)
	
	#Make actor animate
	# anim: name of the animation
	# anim_speed: playback speed
	# queue: have the animation play after other actions or not
	# type: 1 for special animation, 0 for regular animation
	if _curr_phrase.has("actorsanim"):
		for i in _curr_phrase["actorsanim"]:
			var animated = actors[i]
			var speed = 1.0
			var queue = false
			var type = 0
			if _curr_phrase["actorsanim"][i].has("speed"):
				speed = _curr_phrase["actorsanim"][i]["speed"]
			if _curr_phrase["actorsanim"][i].has("queue"):
				queue = _curr_phrase["actorsanim"][i]["queue"]
			if _curr_phrase["actorsanim"][i].has("type"):
				type = _curr_phrase["actorsanim"][i]["type"]
			animated.play_anim(_curr_phrase["actorsanim"][i]["anim"], speed, queue, type)
	
	#erase an actor from a scene
	if _curr_phrase.has("eraseactors"):
		for i in _curr_phrase["eraseactors"]:
			if _curr_phrase["eraseactors"][i] == true:
				if global.talker == actors[i]:
					global.talker = null
				global.persistArray.erase(actors[i].replaced)
				global.persistArray.erase(actors[i])
				actors[i].replaced.queue_free()
				actors[i].queue_free()
				actors.erase(i)
	
	#Make the player emote
	if _curr_phrase.has("emoteplayer"):
		global.persistPlayer.emotes.animaPlayer.play(_curr_phrase["emoteplayer"])
	
	#A simple way of getting the talker to emote
	if _curr_phrase.has("emotenpc"):
		if global.talker != null:
			global.talker.emotes.animaPlayer.play(_curr_phrase["emotenpc"])
	
	#Make specific actor play an emote
	if _curr_phrase.has("emoteactors"):
		for i in _curr_phrase["emoteactors"]:
			var emoter = actors[i]
			emoter.emotes.animaPlayer.play(_curr_phrase["emoteactors"][i])
	
	#Shake camera
	if _curr_phrase.has("shakecam"):
		var size = str(_curr_phrase["shakecam"]["size"])
		var length = 0.2
		var direction = Vector2.ONE
		if _curr_phrase["shakecam"].has("length"):
			length = _curr_phrase["shakecam"]["length"]
		if _curr_phrase["shakecam"].has("x"):
			direction.x = _curr_phrase["shakecam"]["x"]
		if _curr_phrase["shakecam"].has("y"):
			direction.y = _curr_phrase["shakecam"]["y"]
		match size:
			"small":
				global.start_joy_vibration(0, 0.4, 0.3, length)
				global.currentCamera.shake_camera(2, length, direction)
			"medium":
				global.start_joy_vibration(0, 0.5, 0.6, length)
				global.currentCamera.shake_camera(4, length, direction)
			"big":
				global.start_joy_vibration(0, 0.7, 0.8, length)
				global.currentCamera.shake_camera(6, length, direction)
	
	#Set current camera
	if _curr_phrase.has("changecam"):
		if !_curr_phrase["changecam"]:
			_camera.set_current()
		else:
			actors[_curr_phrase["changecam"]].camera.set_current()
	
	#Move camera to a position on the map. 
	#You can set it to an actor to move the camera to the actor's position
	#Or you can set it to a coordinate on the map with "x" and "y". If one of them isn'_t there, it'll just default to the currentCamera's x or y
	if _curr_phrase.has("movecam"):
		var cam_pos = global.currentCamera.global_position
		var time = 1.0
		if _curr_phrase["movecam"].has("actor"): #moves camera to actor
			if _curr_phrase["movecam"]["actor"] == "parent":
				cam_pos = global.currentCamera.get_parent().global_position
			else:
				cam_pos = actors[_curr_phrase["movecam"]["actor"]].global_position
		else:
			if _curr_phrase["movecam"].has("x"):
				cam_pos.x = _curr_phrase["movecam"]["x"]
			if _curr_phrase["movecam"].has("y"):
				cam_pos.y = _curr_phrase["movecam"]["y"]
		if _curr_phrase["movecam"].has("length"):
			time = _curr_phrase["movecam"]["length"]
		global.currentCamera.move_camera(cam_pos, time)
	
	#Return camera to parent. "returncam" is equal to the time it takes for the camera to go back to the original position
	if _curr_phrase.has("returncam"):
		global.currentCamera.return_camera(_curr_phrase["returncam"])
	
	#make fade focus on a position or actor
	if _curr_phrase.has("fadefocus"):
		uiManager.fade.focus_object(actors[_curr_phrase["fadefocus"]])
	
	#Fade in
	if _curr_phrase.has("fadein"):
		var color = Color.black
		var speed = 1.0
		if _curr_phrase["fadein"].has("speed"):
			speed = _curr_phrase["fadein"]["speed"]
		if _curr_phrase["fadein"].has("color"):
			color = Color(_curr_phrase["fadein"]["color"])
		uiManager.fade.fade_in(_curr_phrase["fadein"]["anim"],color, speed)
	
	#Fade out
	if _curr_phrase.has("fadeout"):
		var color = Color.black
		var speed = 1
		if _curr_phrase["fadeout"].has("speed"):
			speed = _curr_phrase["fadeout"]["speed"]
		if _curr_phrase["fadeout"].has("color"):
			color = Color(_curr_phrase["fadeout"]["color"])
		uiManager.fade.fade_out(_curr_phrase["fadeout"]["anim"],color, speed)
	
	#Set fade cut
	if _curr_phrase.has("fadesize"):
		var speed = 1.0
		
		uiManager.fade.set_cut(_curr_phrase["fadesize"]["size"])
	
	#make the fade spin, only works if it's a circle fade.
	if _curr_phrase.has("fadespin"):
		if _curr_phrase["fadespin"]:
			uiManager.fade.toggle_spin()
	
	#disable/enable telepathy effect 
	#telepathyeffect: null (disable telepathy)
	#telepathyeffect: actorName (enable telepathy and focus towards actor)
	if _curr_phrase.has("telepathyeffect"):
		if _curr_phrase["telepathyeffect"] == null:
			uiManager.set_telepathy_effect(false)
		else:
			uiManager.set_telepathy_effect(true, actors[_curr_phrase["telepathyeffect"]])
	
	#Enable flags
	if _curr_phrase.has("setflags"):
		_change_flags(_curr_phrase["setflags"], true)

	#Disable flags
	if _curr_phrase.has("unsetflags"):
		_change_flags(_curr_phrase["unsetflags"], false)
	
	#set respawn point at the end of the cutscene
	if _curr_phrase.has("setrespawn"):
		_set_respawn = _curr_phrase["setrespawn"]
	
	#set respawn point at the end of the cutscene
	if _curr_phrase.has("name") and _curr_phrase.has("text"):
		_curr_phrase["name"] = TextTools.replace_text(_curr_phrase["name"])
		var old_name = _name_label.text
		_name_label.text = str(_curr_phrase["name"])
		if !_name_box_shown:
			$NameAnim.play("Open")
			_name_box_shown = true
			if !_curr_phrase.has("cleardialog"):
				_clear_dialogue()
				_print_dialogue_segment(true)
		
		elif old_name != _curr_phrase["name"]:
			if _phrase_num != 0:
				if !_curr_phrase.has("cleardialog"):
					_clear_dialogue()
					_print_dialogue_segment(true)
	elif not _curr_phrase.has("name"):
		var old_name = _name_label.text
		_name_label.text = ""
		if _name_box_shown:
			$NameAnim.play("Close")
			_name_box_shown = false
		if old_name != _name_label.text and _phrase_num != 0:
			if !_curr_phrase.has("cleardialog"):
				_clear_dialogue()
			if _curr_phrase.has("text"):
				_print_dialogue_segment(true)
	
	#Save game
	if _curr_phrase.has("save"):
		uiManager.open_save()
	
	#Toggle cashBox
	if _curr_phrase.has("cash"):
		if _curr_phrase["cash"] == false:
			uiManager.cash.close()
		else:
			uiManager.cash.open()
	#Give/Remove Money
	if _curr_phrase.has("givecash"):
		globaldata.cash += _curr_phrase["givecash"]
		uiManager.cash.update()
	#Heal Party Members
	if _curr_phrase.has("heal"):
		var character = str(_curr_phrase["heal"])
		if character.to_lower() != "all":
			if !StatusManager.is_unconscious(globaldata[character]):
				globaldata[character]["hp"] = globaldata[character]["maxhp"] + globaldata[character]["boosts"]["maxhp"]
		else:
			for i in global.party:
				if !StatusManager.is_unconscious(i):
					i.hp = i.maxhp + i.boosts.maxhp
	#Restore PP
	if _curr_phrase.has("restorepp"):
		var character = str(_curr_phrase["restorepp"])
		if character != "All":
			globaldata[character]["pp"] = globaldata[character]["maxpp"] + globaldata[character]["boosts"]["maxpp"]
		else:
			for i in global.party:
				i.pp = i.maxpp + i.boosts.maxpp
	#Cure Status
	if _curr_phrase.has("cure"):
		var character = str(_curr_phrase["cure"]["character"])
		var status = str(_curr_phrase["cure"]["status"])
		if character != "All":
			if status != "All":
				StatusManager.remove_status(globaldata[character], status.to_lower())
				if status.to_lower() == StatusManager.AILMENT_UNCONSCIOUS:
					globaldata[character]["hp"] = globaldata[character]["maxhp"] + globaldata[character]["boosts"]["maxhp"]
			else:
				globaldata[character]["status"].clear()
		else:
			if status != "All":
				for i in global.party:
					StatusManager.remove_status(i, status)
					if status.to_lower() == StatusManager.AILMENT_UNCONSCIOUS:
						i.hp = i.maxhp
			else:
				for i in global.party:
					i.status.clear()
					if i.hp <= 0:
						i.hp = i.maxhp
		for i in global.partyObjects:
			i.spritesheet()
	
	if _curr_phrase.has("givestatus"):
		for character in _curr_phrase["givestatus"]:
			var status = str(_curr_phrase["givestatus"][character])
			StatusManager.add_status(globaldata[character], status)
	
	if _curr_phrase.has("openshop"):
		uiManager.open_shop(_curr_phrase.openshop)
	
	if _curr_phrase.get("openstorage", false):
		uiManager.open_storage()
	
	if _curr_phrase.get("use_atm", false):
		uiManager.open_atm()
	
	if _curr_phrase.has("keyboard"):
		uiManager.open_keyboard(_curr_phrase["keyboard"])
	
	#Take Item
	if _curr_phrase.has("removeitem"):
		if InventoryManager.check_item_for_all(_curr_phrase["removeitem"]):
			InventoryManager.remove_item(_curr_phrase["removeitem"])

	if _curr_phrase.has("transformitem"):
		InventoryManager.transform_item_for_all(_curr_phrase["transformitem"])

	#Start battle with current NPC
	if _curr_phrase.has("battler"):
		var battler = _curr_phrase["battler"]
		var enemy = _curr_phrase["battler"]["enemy"]
		var actor = null
		if _curr_phrase["battler"]["actor"] != "":
			if _curr_phrase["battler"]["actor"] == "talker":
				actor = global.talker
			else:
				actor = actors[_curr_phrase["battler"]["actor"]]
			actor.drafted = true
			if _curr_phrase["battler"].has("keep"):
				actor.keepAfterBattle = _curr_phrase["battler"]["keep"]
		uiManager.onScreenEnemies.append([enemy, actor])
		uiManager.update_enemy_ids()
		_queued_battle = true
		print("queuing battle")
	
	if !_curr_phrase.has("text") and !_curr_phrase.has("wait"):
		next_phrase()
	
	if _curr_phrase.has("learnskills"):
		var skill_per_members = _curr_phrase["learnskills"]
		for member in skill_per_members:
			var skill = skill_per_members[member]
			if skill == "All":
				for existing_skill in globaldata.skills:
					if not existing_skill in globaldata[member]["learnedSkills"]:
						globaldata[member]["learnedSkills"].append(existing_skill)
			else:
				globaldata[member]["learnedSkills"].append(skill)
	
	#play cutscene after winning after the battle
	if _curr_phrase.has("batwincutscene"):
		uiManager.battleWinCutscene = _curr_phrase["batwincutscene"]
	
	#play cutscene after fleeing after the battle
	if _curr_phrase.has("batfleecutscene"):
		uiManager.battleFleeCutscene = _curr_phrase["batfleecutscene"]
	
	#play cutscene after being defeated after the battle
	if _curr_phrase.has("batlosecutscene"):
		uiManager.battleLoseCutscene = _curr_phrase["batlosecutscene"]
	
	#set a flag to true after winning a battle
	if _curr_phrase.has("batwinflag"):
		uiManager.battleWinFlag = _curr_phrase["batwinflag"]
	
	#set a flag to true for the rematch cutscene
	if _curr_phrase.has("batrematchflag"):
		uiManager.battleRematchFlag = _curr_phrase["batrematchflag"]
	
	#fully heal player or party after losing a battle
	if _curr_phrase.has("batloseheal"):
		uiManager.battleLoseHeal = _curr_phrase["batloseheal"]
	
	#unpause the player or not once the dialog sequence is done
	if _curr_phrase.has("unpauseplayer"):
		unpausePlayer = _curr_phrase["unpauseplayer"]


func _add_dialog_options():
	# Parse Options
	if _curr_phrase.has("options"):
		for i in _options_grid.get_children():
			i.hide()
		_options.clear()
		_print_new_line()
		var optionNode = load("res://Nodes/Ui/DialogueOptions.tscn")
		_options_count = 0

		var visibleOptions = {}

		for i in _curr_phrase["options"]:
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
				# Bulding a dictionary with all the _options that will actually appear in the dialogue box
				visibleOptions[i] = nickname

		# Now we know the exact number of visible _options because they are stored inside visibleOptions
		_options_count = visibleOptions.size()

		if _options_count == 4:					# 2×2 layout if 4 _options
			_options_grid.columns = 2
		else:
			_options_grid.columns = 3
		if _options_count > 3:
			_print_new_line()

		# The nodes already exist, we’re just showing them
		# (it works better that way, especially the cursor positionning)
		var idx = 0
		for i in visibleOptions:
			var option = _options_grid.get_child(idx)
			var nickname = visibleOptions[i]
			option.text = nickname
			option.set_name(nickname)
			option.show()
			_options.append(i)
			idx += 1

		$Dialoguebox/Arrow.show()
		$Dialoguebox/Arrow.on = true
		$Dialoguebox/Arrow.set_cursor_from_index(0, false)
		_options_grid.show()
		_cursor_down_sprite.hide()
	else:
		$Dialoguebox/Arrow.hide()
		$Dialoguebox/Arrow.on = false
		_options_grid.hide()

# Override
func _end_dialogue():
	Input.action_release("ui_cancel")
	Input.action_release("ui_accept")
	_clear_dialogue()
	
	global.phoneLocation = ""
	
	$AudioStreamPlayer.volume_db = -80
	_dialogue_label.hide()
	if unpausePlayer:
		global.persistPlayer.unpause()
	global.cutscene = false
	if global.talker != null:
		global.talker.stop_interaction()
		global.talker = null
	if _name_label.text != "":
		$NameAnim.play("Close")
	uiManager.toggle_black_bars(false)
	uiManager.cash.close()
	uiManager.set_telepathy_effect(false)
	
	if actors.size() != 0:
		for i in actors:
			if !_queued_battle:
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
	
	uiManager.update_key_indicator()
	if _queued_battle:
		var canRun = false
		uiManager.start_battle(0, canRun)
		global.currentCamera.get_node("Tween").set_active(false)
	else:
		global.currentCamera.return_camera(0.5)
		global.currentCamera.return_offset(0.5)
		if _set_respawn:
			global.set_respawn()
	emit_signal("done")
	global.emit_signal("cutscene_ended")
	_phrase_num = 0
	_remove_dialog_box()

func _clear_dialogue():
	_dialogue_label.bbcode_text = ""
	_bullet_label.bbcode_text = ""
	_dialogue_label.visible_characters = 0

# Override
func next_phrase(with_sound = false):
	if _curr_phrase.has("sendsignal"):
		var signal = _curr_phrase["sendsignal"]
		if typeof(signal) != TYPE_ARRAY:
			signal = [signal]
		self.callv("emit_signal", signal)

	if _curr_phrase.has("if"):
		var all_ifs = _curr_phrase["if"]
		if typeof(all_ifs) != TYPE_ARRAY:
			all_ifs = [_curr_phrase["if"]]

		for curr_if in all_ifs:
			var condition = true
			for cond in curr_if:
				var is_actual_condition = !cond in ["or", "goto"]
				if curr_if.has("or") and is_actual_condition:
					condition = true
				#Check if the player does or doesn'_t have enough inventory space
				if "hascash" in cond:
					if globaldata.cash < curr_if["hascash"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player does or doesn'_t have enough inventory space
				if "invspace" in cond:
					if InventoryManager.has_inventory_space() != curr_if["invspace"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player has a certain item
				if "hasitem" in cond:
					if !InventoryManager.check_item_for_all(curr_if[cond]):
						print("checkItem")
						condition = false
						if !curr_if.has("or"):
							break
				#Check if an item is in storage
				if "hasinstorage" in cond:
					if !InventoryManager.check_item_in_storage(curr_if[cond]):
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the leader is a certain character
				if "leader" in cond:
					if global.party[0]["name"] != curr_if["leader"]:
						condition = false
						if !curr_if.has("or"):
							break
				#Check if the player has certain party members (including party NPCs)
				if "haspartymembers" in cond:
					var hasPartyMember = true
					for memberName in curr_if["haspartymembers"]:
						var hasMember = false
						var all_party = global.party + global.partyNpcs
						for member in all_party.size():
							if all_party[member]["name"] == memberName:
								hasMember = true
								if !curr_if.has("or"):
									break
						if hasMember != curr_if["haspartymembers"][memberName]:
							condition = false
							hasPartyMember = false
							if !curr_if.has("or"):
								break
					if !hasPartyMember:
						if !curr_if.has("or"):
							break
				#Check if the party has enough members
				if "partysize" in cond:
					condition = false
					match curr_if[cond]["symbol"]:
						">":
							if global.party.size() > curr_if[cond]["size"]:
								condition = true
						">=":
							if global.party.size() >= curr_if[cond]["size"]:
								condition = true
						"<":
							if global.party.size() < curr_if[cond]["size"]:
								condition = true
						"<=":
							if global.party.size() <= curr_if[cond]["size"]:
								condition = true
						"=":
							if global.party.size() == curr_if[cond]["size"]:
								condition = true
					if !condition:
						if !curr_if.has("or"):
							break
				#Check if character has status
				if "hasstatus" in cond:
					var hasStatus = true
					var status = curr_if[cond]["status"]
					var character = curr_if[cond]["character"]
					for member in global.party.size():
						if global.party[member]["name"] == character:
							if status != "":
								if !StatusManager.has_status(global.party[member], status.to_lower()):
									condition = false
									hasStatus = false
									break
							else:
								if global.party[member]["status"].size() != 0:
									condition = false
									hasStatus = false
									break
					if !hasStatus:
						if !curr_if.has("or"):
							break
							
				#Check if certain flags in globalData are true or false
				if "flags" in cond:
					var flagCorrect = true
					for flagName in curr_if["flags"]:
						if globaldata.flags[flagName] != curr_if["flags"][flagName]:
							condition = false
							flagCorrect = false
							if !curr_if.has("or"):
								break
					if !flagCorrect:
						if !"or" in curr_if:
							break
				if curr_if.has("or") and is_actual_condition:
					if condition:
						break
			if condition: #check if all of these are true to go to this "goto"
				if with_sound:
					$InputSound.play()
				_phrase_num = str2var(curr_if["goto"])
				_handle_phrase()
				return

	if _curr_phrase.has("goto"):
		if with_sound:
			$InputSound.play()
		_phrase_num = str2var(_curr_phrase["goto"])
		_handle_phrase()
	else:
		_end_dialogue()

# Override
func _show_box(show, sfx = true):
	if show and !_dialogue_box_shown:
		_dialogue_box_shown = true
		$AnimationPlayer.play("Open")
		if sfx:
			audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_open.wav"), "menu_open")
		set_process_input(true)
		set_physics_process(true)
	if !show and _dialogue_box_shown:
		_dialogue_box_shown = false
		$AnimationPlayer.play("Close")
		if sfx:
			audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_close.wav"), "menu_close")
		_clear_dialogue()
		set_process_input(false)
		set_physics_process(false)

func _set_nametag():
	var new_size = _name_label.rect_size.x + 20
	var old_size = $Dialoguebox/Namebox.rect_size.x 
	if new_size != old_size:
		$Tween.interpolate_property($Dialoguebox/Namebox, "rect_size", 
			Vector2(old_size, 47), Vector2(new_size, 47), 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		$Tween.start()
	else:
		$Dialoguebox/Namebox.rect_size.x = _name_label.rect_size.x + 20

func _remove_dialog_box():
	if $Dialoguebox.rect_position.y != 180:
		$AnimationPlayer.play("Close")
		audioManager.play_sfx(load("res://Audio/Sound effects/M3/menu_close.wav"), "menu_close")
		yield($AnimationPlayer, "animation_finished")
	uiManager.remove_ui(self)
	
	if !global.dialogue.empty():
		uiManager.open_dialogue_box()

func _on_WaitTimer_timeout():
	_cursor_down_sprite.show()
	if _auto_advance:
		next_phrase()

func _change_scene(targetScene):
	global.goto_scene("res://Maps/" + targetScene + ".tscn")
	
	var cam = global.currentCamera
	cam.limit_top = -10000000
	cam.limit_left = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000
	cam.smoothing_enabled = false

func _actor_strings_to_node(actors_strings):
	if typeof(actors_strings) != TYPE_ARRAY:
		actors_strings = [actors_strings]

	for actor_str in actors_strings:
		if actor_str == "leader" or actor_str == "player":
			return global.persistPlayer
		elif actor_str == "talker":
			return global.talker
		elif actor_str in global.POSSIBLE_PARTY_MEMBERS:
			var party = global.party + global.partyNpcs
			for partyMember in global.partyObjects.size():
				if party[partyMember]["name"] == str(actor_str):
					return global.partyObjects[partyMember]
		else:
			var node = global.currentScene.get_node_or_null(str2var(actor_str))
			if node != null:
				return node

func _change_flags(flags, value):
	if typeof(flags) != TYPE_ARRAY:
		flags = [flags]
	for flag in flags:
		if globaldata.flags.has(flag):
			globaldata.flags[flag] = value
