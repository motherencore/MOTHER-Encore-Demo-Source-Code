const HARD_TO_SOFT = {"p": "pi", "b": "bi", "f": "fi", "w": "wi", "m": "mi", "t": "ci", "d": "dzi", "s": "si", "z": "zi", "n": "ni", "ł": "l",
"r": "rz", "k": "c", "g": "dz", "ch": "sz", "st": "ści", "zd":"ździ", "sł": "śl", "zł": "źl", "sn": "śni", "zn": "źni"}

const HARD_EXCEPTIONS = ["k", "g", "ch"]

const I_OVER_Y = ["k", "g", "ć", "dź", "ś", "ź", "ń", "l", "ść", "źdź", "śl", "śń", "źń", "j", "i", "y"]

const POLISH_I_NAMES = ["alusi", "ani", "asi", "basi", "danusi", "dosi", "frani", "gabrysi", "geni", "gosi", "halusi", "hani", "jadzi", "jagusi", "joasi", "kasi", "kazi", "krysi", "mani", "marysi", "reni", "rysi", "soni", "stasi", "stasi", "stefci", "tosi", "wiesi", "władzi", "zosi", "zuzi"]

const GENITIVE		= 1
const DATIVE		= 2
const ACCUSATIVE 	= 3
const INSTRUMENTAL	= 4
const LOCATIVE		= 5
const VOCATIVE		= 6

const vowels = "aeiouyąęó"

func get_polish_declension(name, gender, case):
	var is_all_caps = (name == name.to_upper())
	var declined_name = get_polish_declension_proceed(name, gender, case)
	if is_all_caps:
		return declined_name.to_upper()
	else:
		return declined_name


func get_polish_declension_proceed(name, gender, case):
	var suffix = name[-1]
	if not suffix.to_lower() in vowels:
		suffix = ""
	
	var stem = name.trim_suffix(suffix)

	match suffix.to_lower():
		"a":
			# Feminine declension pattern
			return _get_feminine_declension(stem, case)

		"o", "":
			if gender == "F":
				return name
			# Masculine declension pattern
			return _get_masculine_declension(stem, case)

		"y":
			if gender == "F":
				return name
			# Adjective declension pattern, group 1
			return _get_adjective_declension(stem, 1, case)

		"i":
			if gender == "F":
				return name
			# Adjective declension pattern, group 2
			return _get_adjective_declension(stem, 2, case)

		_:
			return name


func _get_masculine_declension(stem, case):
	match case:
		GENITIVE, ACCUSATIVE:
			return stem + "a"
		DATIVE:
			return stem + "owi"
		INSTRUMENTAL:
			if stem.to_lower().ends_with("k") or stem.to_lower().ends_with("g"):
				return stem + "iem"
			else:
				return stem + "em"
		LOCATIVE, VOCATIVE:
			if _has_hard_final(stem, true):
				return _soften_final(stem) + "e"
			else:
				return stem + "u"


func _get_feminine_declension(stem, case):
	match case:
		GENITIVE:
			return _add_i_or_y(stem)
		DATIVE, LOCATIVE:
			if _has_hard_final(stem):
				return _soften_final(stem) + "e"
			else:
				return _add_i_or_y(stem)
		ACCUSATIVE:
			return stem + "ę"
		INSTRUMENTAL:
			return stem + "ą"
		VOCATIVE:
			return stem + "o"


func _get_adjective_declension(stem, group, case):
	var i = "i" if group == 2 else ""
	var yi = "i" if group == 2 else "y"

	match case:
		GENITIVE, ACCUSATIVE:
			return stem + i + "ego"
		DATIVE:
			return stem + i + "emu"
		INSTRUMENTAL, LOCATIVE:
			return stem + yi + "m"
		VOCATIVE:
			return stem + yi

func _add_i_or_y(string):
	if string.to_lower() in POLISH_I_NAMES: # If the stem ends with -i and it’s a native Polish name, we don’t add anything
		return string
	for final in I_OVER_Y:
		if string.to_lower().ends_with(final):
			return string + "i"
	return string + "y"

func _has_hard_final(string, excludeKGCh = false):
	for final in HARD_TO_SOFT:
		if ((not excludeKGCh) or (not final in HARD_EXCEPTIONS)) and string.to_lower().ends_with(final):
			return true
	return false

func _soften_final(string):
	for final in HARD_TO_SOFT:
		if string.to_lower().ends_with(final):
			return string.trim_suffix(final) + HARD_TO_SOFT[final]
