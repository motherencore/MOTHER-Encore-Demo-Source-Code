class_name TextTools

const DIALOG_HINT_COLOR = "ea8b2c"
const SPECIAL_KEY_LABELS = {KEY_UP: "↑", KEY_DOWN: "↓", KEY_LEFT: "←", KEY_RIGHT: "→", KEY_KP_MULTIPLY: "*", KEY_KP_DIVIDE: "/", KEY_KP_SUBTRACT: "-", KEY_KP_PERIOD: ".", KEY_KP_ADD: "+", KEY_KP_0: "0", KEY_KP_1: "1", KEY_KP_2: "2", KEY_KP_3: "3", KEY_KP_4: "4", KEY_KP_5: "5", KEY_KP_6: "6", KEY_KP_7: "7", KEY_KP_8: "8", KEY_KP_9: "9", KEY_SPACE: "KEYBOARD_SPACE"}
const PSI_LEVELS = "αβγΩΣ"

const CHAR_DELAY = "​"
const CHAR_PRINTING_FASTER = "⁪"
const CHAR_PRINTING_NORMAL = "⁫"
const CHAR_WAIT = "⁣"
const CHAR_BULLET = "⁤"

static func replace_text(string, context = globaldata, without_brackets := false):
	string = _tr(string)
	string = _replace_ifs(string)
	string = _replace_tags(string, context, without_brackets)
	var substitutions = {" - ": " – " , "(\\d+) (\\$)": '$1 $2',  "([   ])!": "$1¦" }
	var regex = RegEx.new()
	for pattern in substitutions:
		regex.compile(pattern)
		string = regex.sub(string, substitutions[pattern], true)
	return string
	
# General syntax: [Tag], [Tag:Param1,Param2,...], or [Tag123] (numeric parameter)
static func _replace_tags(string: String, context = globaldata, without_brackets := false):
	var startIndex := 0
	var regex := RegEx.new()
	if !without_brackets:
		regex.compile("\\[([A-Za-z_@/]+)(:[^\\]]+|\\d+)?\\]")
	else:
		regex.compile("^([A-Za-z_]+)(:[^\\]]+|\\d+)?$")
	var tag := regex.search(string)
	while tag:
		var result := tag.get_string()
		var tag_content := tag.get_string(1).to_lower()
		var tag_param := tag.get_string(2).trim_prefix(":")
		var tag_params := tag_param.split(":")
		var str_before := string.substr(0, tag.get_start())
		var str_after := string.substr(tag.get_end())
		match tag_content:
			"n":			# [N] returns Ninten's initial, for the NES joke in other languages
				result = context.ninten["nickname"][0]
			"favfood":		# [FavFood] returns the favorite food
				result = _cut_custom_name(context.favoriteFood, tag_content)
			"playername":	# [PlayerName] returns the player’s name
				result = _cut_custom_name(context.playerName, tag_content)
			"itemname": 	# [ItemName] returns the current item name
				result = _tr(global.item["name"]) if global.item else ""
			"itemreceiver":	# [ItemReceiver] returns the nickname of the party member receiving an item
				result = _cut_custom_name(global.receiver["nickname"], tag_content) if global.receiver else ""
			"itemart":		# [ItemArt0], [ItemArt1], etc., return the current item articles
				if global.item and tag_param:
					result = get_item_or_skill_articles(global.item, int(tag_param))
				else:
					result = ""
			"itemvalue":
				result = "%s" % globaldata.get_item_value(global.item, tag_param)
			"itemvalart":
				if tag_params.size() > 1:
					result = get_number_articles(globaldata.get_item_value(global.item, tag_params[0]), int(tag_params[1]))
				else:
					result = get_number_articles(globaldata.get_item_value(global.item), int(tag_param))
			"partylead":	# [PartyLead] returns the party leader's nickname
				result = _cut_custom_name(global.party[0]["nickname"], tag_content)
			"leadart":		# [LeadArt0], [LeadArt1], etc., return the party leader's articles
				result = get_battler_articles(global.party[0], int(tag_param))
			"receiverart":	# [ReceiverArt0], [ReceiverArt1], etc., return the item receiver's articles
				result = get_battler_articles(global.receiver, int(tag_param))
			"earnedcash":	# [EarnedCash] returns - and resets - the amount of money you've just earned
				result = var2str(context.earned_cash) # Dollar sign not included
				context.earned_cash = 0
				context.flags["earned_cash"] = false
			"currentcash":	# [CurrentCash] returns the amount of money on hand (without dollar sign)
				result = var2str(context.cash)
			"bankcash":		# [BankCash] returns the amount of money on bank (without dollar sign)
				result = var2str(context.bank)
			"tr":
				result = _tr(tag_param)
			"color":		# [color] returns the opening tag to set the text color to hint color
				result = "[color=#"+ DIALOG_HINT_COLOR + "]"
			"br":	# [br] returns a new line
				str_before = str_before.trim_suffix("\n")
				result = "\n"
			"delay":
				var duration = tag_params[0].to_float() if tag_params[0] else 10.0 # /!\ split never returns an empty array
				var repeat = tag_params[1].to_int() if tag_params.size() > 1 else 1
				var middle_text_speed = globaldata.TEXT_SPEEDS[globaldata.TEXT_SPEEDS.size() / 2]
				var invisible_chars = CHAR_DELAY.repeat(duration / (middle_text_speed * 10))	
				result = invisible_chars
				if repeat > 1:
					var slowed_down_part = ""
					var repeated_count = 0
					for i in range(repeat - 1):
						if i >= str_after.length() || str_after[i] in "{[":
							break
						slowed_down_part += str_after[i]
						slowed_down_part += invisible_chars
						repeated_count += 1
					str_after = slowed_down_part + str_after.substr(repeated_count)
			"faster":
				var param = int(clamp(int(tag_param), 1, 10)) if tag_param else 1
				result = CHAR_PRINTING_FASTER.repeat(param)
			"sudden":
				result = CHAR_PRINTING_FASTER.repeat(10)
			"/sudden", "/faster":
				result = CHAR_PRINTING_NORMAL
			"wait":
				result = CHAR_WAIT
			"@", "br@":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_BULLET
				if str_before:
					result = "\n" + result
			"wait@":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_WAIT + "\n" + CHAR_BULLET
			"waitbr":
				str_before = str_before.trim_suffix("\n")
				result = CHAR_WAIT + "\n"
			"fr_eli":		# [fr_eli] returns French elision ("e " or "'" if followed by vowel)
							# [fr_eli:***] returns French elision where the next word is ***
				if tag_param:
					var nickname = _replace_tags(tag_param, context, true)
					result = _get_french_elision(nickname)
				else:
					result = _get_french_elision(string.substr(tag.get_end()))
			"de_gen":		# [de_gen] returns German genitive suffix ("s" or "'" if after an s or x)
							# [de_gen:***] returns German genitive suffix where the previous word is ***
				if tag_param:
					var nickname = _replace_tags(tag_param, context, true)
					result = _get_german_genitive(nickname)
				else:
					result = _get_german_genitive(string.substr(0, tag.get_start()))
			"pl_decl":		# [pl_decl:name:gender:case] returns Polish declension for name
							# where "gender" is M or F and "case" is the index of the grammar case
				var nickname = _replace_tags(tag_params[0], context, true)
				result = _get_custom_name_declension(nickname, PolishDeclension, tag_params[1], int(tag_params[2]))
			"ru_decl":		# [ru_decl:name:gender:case] returns Russian declension for name
							# where "gender" is M or F and "case" is the index of the grammar case
				var nickname = _replace_tags(tag_params[0], context, true)
				result = _get_custom_name_declension(nickname, RussianDeclension, tag_params[1], int(tag_params[2]))
			"uk_decl":		# [uk_decl:name:gender:case] returns Ukrainian declension for name
							# where "gender" is M or F and "case" is the index of the grammar case
				var nickname = _replace_tags(tag_params[0], context, true)
				result = _get_custom_name_declension(nickname, UkrainianDeclension, tag_params[1], int(tag_params[2]))
			"ko_part":
				if tag_params.size() > 1:
					var nickname = _replace_tags(tag_params[0], context, true)
					result = _get_korean_particle(nickname, int(tag_params[1]))
				else:
					result = _get_korean_particle(string.substr(0, tag.get_start()), int(tag_params[0]))
			"plur_num":
				result = _get_plural_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2])
			"slav_num":
				result = _get_slavic_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3])
			"pl_num":
				result = _get_slavic_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3], true)
			"ja_num":
				tag_params.resize(7)
				result = _get_japanese_number_suffix(int(tag_params[0]), tag_params[1], tag_params[2], tag_params[3], tag_params[4], tag_params[5], tag_params[6])
			_:
				if tag_content.begins_with("ui_"):	# [ui_accept], [ui_cancel], etc., returns control keys
					result = get_key_name(tag_content)
				elif tag_content in global.POSSIBLE_PARTY_MEMBERS:
					if context.get(tag_content):
						result = context.get(tag_content)["nickname"]
						if tag_content in global.POSSIBLE_PLAYABLE_MEMBERS:
							result = _cut_custom_name(result, tag_content)
				elif StatusManager.does_ailment_exist(tag_content):
					result = "[font=res://Graphics/UI/Ailments/Ailments.tres][img]res://Graphics/UI/Ailments/%s.png[/img][/font]" % tag_content.to_lower()
				else:								# Unknown tags: doing nothing, moving the start index to prevent looping indefinitely
					startIndex = tag.get_start() + 1
					if not tag_content in ["i", "b", "img", "/img", "font", "/font", "/color"]:
						push_warning("UNKNOWN TAG: %s" % tag_content)

		string = str_before + result + str_after

		if without_brackets:
			break

		tag = regex.search(string, startIndex)
	
	return string

# In case the player switches language, the max lengths are different
static func _cut_custom_name(name, tag):
	var max_length = len(_tr("LONGEST_POSSIBLE_NAME"))
	if tag == "playername":
		max_length = len(_tr("LONGEST_POSSIBLE_PLAYER_NAME"))
	elif tag == "favfood":
		max_length = len(_tr("LONGEST_POSSIBLE_FOOD"))
	return name.substr(0, max_length)

static func _replace_ifs(string):
	var regex = RegEx.new()
	regex.compile("\\[if (\\w+)(:\\w+)?\\]((?:(?!\\[/?if [\\w:]+\\]).)*?)(\\[else\\]((?:(?!\\[/?if [\\w:]+\\]).)*?))?\\[/if\\]")
	var tag = regex.search(string)
	
	if tag:
		var condition = tag.get_string(1)
		var params = tag.get_string(2).trim_prefix(":").split(":")
		var content_if = tag.get_string(3)
		var content_else = tag.get_string(5)
		var before = string.substr(0, tag.get_start())
		var after = string.substr(tag.get_end())
		var condition_res = true
		match condition:
			"input":
				for param in params:
					match param:
						"gamepad":
							condition_res = condition_res if global.device == global.GAMEPAD else false
						"keyboard":
							condition_res = condition_res if global.device == global.KEYBOARD else false
						_:
							push_warning("UNKNOWN CONDITION: %s=%s" % [condition, param])
			"party":
				for param in params:
					match param:
						"plural":
							condition_res = condition_res if global.party.size() > 1 else false
						"singular":
							condition_res = false if global.party.size() > 1 else condition_res
						"female_lead":
							condition_res = condition_res if global.party[0] in [globaldata.ana, globaldata.pippi] else false
						"male_lead":
							condition_res = false if global.party[0] in [globaldata.ana, globaldata.pippi] else condition_res
			_:
				push_warning("UNKNOWN CONDITION: %s" % condition)
				condition_res = null
		var res
		if condition_res == null:
			res = before + after
		elif condition_res:
			res = before + content_if + after
		else:
			res = before + content_else + after
		if string == res:
			return res
		else:
			return _replace_ifs(res)
	
	else:
		return string

static func get_battler_articles(battler, article_idx : int = -1, battler_name = null):
	var article_str
	if battler.has("article"):
		article_str = _tr(battler.article)
	else:
		article_str = _tr("ARTICLES_DEFAULT")

	var article_array = article_str.split(",")

	if !battler_name:
		battler_name = battler.nickname

	for i in article_array.size():
		# In case the "articles" are actually alternative names, {0} reverts to the actual nickname (useful for languages with declensions)
		article_array[i] = article_array[i].format([battler_name])
		# French elision in the case of articles (for user-defined party member names)
		article_array[i] = replace_text(article_array[i])
	
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

static func get_item_or_skill_articles(item: Dictionary, article_idx: int = -1):
	var article_str := ""
	if item.has("article"):
		article_str = _tr(item.article)
	var article_array := article_str.split(",")
	
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

static func get_skill_level(skill):
	if skill.has("level") and skill.get("skillType") == "psi":
		var skill_level = int(skill["level"])
		if skill_level in range(0, PSI_LEVELS.length()):
			return _tr("BATTLE_LETTER_SPACING").format(["", PSI_LEVELS[skill_level]])
	return ""

static func get_inline_stat_name(stat):
	return _tr("INLINE_STAT_%s" % stat.to_upper())

static func get_inline_stat_articles(stat, article_idx: int = -1):
	var article_str = _tr("INLINE_STAT_%s_ARTICLE" % stat.to_upper())
	var article_array = article_str.split(",")

	if article_idx == -1:
		return Array(article_array)
	else:
		return article_array

static func get_number_articles(number: int, article_idx: int = -1):
	var article_array = _tr("ARTICLES_NUMBERS").split(",")

	for i in article_array.size():
		article_array[i] = article_array[i].format([number])
		article_array[i] = replace_text(article_array[i])
		
	if article_idx == -1:
		return Array(article_array)
	elif article_idx < article_array.size():
		return article_array[article_idx]
	else:
		return ""

static func _get_plural_number_suffix(number: int, singular: String, plural: String) -> String:
	if number >= 2:
		return plural
	else:
		return singular

static func _get_slavic_number_suffix(number: int, sing_suffix: String, paucal_suffix: String, plural_suffix: String, is_strict_singular := false) -> String:
	var units := number % 10
	var tens := (number % 100) / 10

	if units == 1 and tens != 1 and (!is_strict_singular or number == 1):
		return sing_suffix
	elif units in [2, 3, 4] and tens != 1:
		return paucal_suffix
	else:
		return plural_suffix

static func _get_japanese_number_suffix(number: int, general: String, alt: String, three := "", one := "", two := "", eight := "") -> String:
	var units := number % 10

	var exceptions_dict := { 1: one, 2: two, 3: three, 8: eight}
	for i in exceptions_dict:
		if exceptions_dict[i] and units == i:
			return exceptions_dict[i]

	if units in [1, 3, 6, 8, 0]:
		return alt

	return general

static func _get_french_elision(nextWord):
	nextWord = replace_text(nextWord)
	var vowels = "aeiouáàâäæéèêëíìîïóòôöœúùûü"
	if nextWord.length() > 0 and nextWord[0].to_lower() in vowels:
		return "'"
	else:
		return "e "

static func _get_german_genitive(prevWord):
	prevWord = replace_text(prevWord)
	if prevWord.ends_with('s') or prevWord.ends_with('x'):
		return "'"
	else:
		return "s"

static func _get_custom_name_declension(name: String, language: GDScript, gender: String, case: int) -> String:
	if name == "":
		return ""
	var is_all_caps := (name == name.to_upper())
	var declined_name = language.decline_name(name, gender, case)
	if is_all_caps:
		return declined_name.to_upper()
	else:
		return declined_name

static func _get_korean_particle(prevWord: String, type: int):
	if KoreanHangul.ends_with_vowel(prevWord, type == 4):
		return ["는","가","를","와","로"][type]
	else:
		return ["은","이","을","과","으로"][type]

static func get_item_doses_phrase(item_def: Dictionary = {}, remaining_uses := 0) -> String:
	var nb_uses: int = item_def.get("doses", 1)
	var csv_key := "INVENTORY_ITEM_USES_TOTAL"

	if nb_uses <= 1:
		return ""
	
	if remaining_uses in range(0, nb_uses):
		nb_uses = remaining_uses
		csv_key = "INVENTORY_ITEM_USES_LEFT"
		
	return format_text_with_context(csv_key, null, null, "", nb_uses)

static func get_key_name(key: String, device: int = global.device):
	var keyname = ""
	for event in InputMap.get_action_list(key):
		if (device == global.KEYBOARD and event is InputEventKey)\
		or (device == global.GAMEPAD and event is InputEventJoypadButton)\
		or (device == global.GAMEPAD and event is InputEventJoypadMotion):
			return get_key_name_from_event(event)

static func get_key_name_from_event(event):
	if event is InputEventKey:
		return get_key_from_scancode(event.scancode)
	elif event is InputEventJoypadButton:
		return _get_button_name(Input.get_joy_button_string(event.button_index))
	elif event is InputEventJoypadMotion:
		return

static func get_key_from_scancode(scancode):
	if scancode in SPECIAL_KEY_LABELS:
		return _tr(SPECIAL_KEY_LABELS[scancode])
	
	elif OS.is_scancode_unicode(scancode):
		if char(scancode) in "            ​  　﻿\t": # Filtering out non-printable characters
			return
		else:
			return char(scancode)
	
	elif scancode in globaldata.ALLOWED_KEYS:
		var key_str = OS.get_scancode_string(scancode)
		var key_translated = _tr("KEYBOARD_" + key_str.to_upper().replace(" ", "_"))
		if key_translated.begins_with("KEYBOARD_"):
			return key_str
		else:
			return key_translated

static func _get_button_name(button_string):
	var current_style = globaldata.buttonsStyle
	if current_style == globaldata.BtnStyles.DETECT:
		current_style = global.detect_buttons_style()
	match button_string:
		"Face Button Bottom":
			return "B✖A"[current_style]
		"Face Button Left":
			return "Y■X"[current_style]
		"Face Button Right":
			return "A●B"[current_style]
		"Face Button Top":
			return "X▲Y"[current_style]
		"DPAD Up":
			return "↑"
		"DPAD Down":
			return "↓"
		"DPAD Left":
			return "←"
		"DPAD Right":
			return "→"
		"L":
			return ["L", "L", "LB"][current_style]
		"R":
			return ["R", "R", "RB"][current_style]
		"L2":
			return ["ZL", "L2", "LT"][current_style]
		"R2":
			return ["ZR", "R2", "RT"][current_style]
		"L3":
			return ["LS", "L3", "L3"][current_style]
		"R3":
			return ["RS", "R3", "R3"][current_style]
		"Select":
			return ["-", "Share", "Back"][current_style]
		"Start":
			return ["+", "Optns", "Start"][current_style]
		_:
			return(button_string.replace(" ", "").substr(0, 6))

static func format_text_with_context(text: String, target = null, item = null, stat := "", value := 0):
	var target_name = target.nickname if target else ""
	var target_articles = get_battler_articles(target) if target else []
	var item_name = _tr(item.name) if item else ""
	var item_articles = get_item_or_skill_articles(item) if item else []
	var stat_name = get_inline_stat_name(stat) if stat else ""
	var stat_articles = get_inline_stat_articles(stat) if stat else []

	return _tr(text).format({
		"target": target_name,
		"item": item_name,
		"stat": stat_name,
		"value": value
		}).format(
			target_articles, "{t_}"
		).format(
			item_articles, "{i_}"
		).format(
			stat_articles, "{st_}"
		).format(
			get_number_articles(value), "{v_}"
		)
	
static func add_line_breaks(phrase: String, container: Control) -> String:
	var max_length: float = container.rect_size.x
	var font: Font = container.get_font("normal_font")
	var sep := _tr("WORD_SEPARATOR")
	var result := ""
	var existing_segments := phrase.split("\n")
	for segment in existing_segments:
		var words: PoolStringArray = segment.split(sep)
		var result_line := ""
		if words.size() > 0:
			result_line += words[0]
			for i in range(1, words.size()):
				if font.get_string_size(strip_bbcode(result_line + sep + words[i])).x > max_length:
					result += ("\n" if result != "" else "") + result_line
					result_line = ""
				else:
					result_line += sep
				result_line += words[i]
		if result_line != "":
			result += ("\n" if result != "" else "") + result_line
	return result

static func strip_bbcode(source: String) -> String:
	var img_regex = RegEx.new()
	img_regex.compile("\\[img.*?\\].*?\\[/img\\]")
	var ret = img_regex.sub(source, "——", true)
	var regex = RegEx.new()
	regex.compile("\\[(\\/?(b|i|u|s|code|center|right|fill|indent|url|font|color|table|cell)(=[^\\]]+)?)\\]")
	ret = regex.sub(ret, "", true)
	return ret

static func _tr(message) -> String:
	return TranslationServer.translate(message)
