class_name PolishDeclension
extends CustomNameDeclension

enum Cases {NOMINATIVE, GENITIVE, DATIVE, ACCUSATIVE, INSTRUMENTAL, LOCATIVE, VOCATIVE}

const HARD_TO_SOFT := {"p": "pi", "b": "bi", "f": "fi", "w": "wi", "m": "mi", "t": "ci", "d": "dzi", "s": "si", "z": "zi", "n": "ni", "ł": "l",
"r": "rz", "k": "c", "g": "dz", "ch": "sz", "st": "ści", "zd":"ździ", "sł": "śl", "zł": "źl", "sn": "śni", "zn": "źni"}

const HARD_EXCEPTIONS := ["k", "g", "ch"]

const I_OVER_Y := ["k", "g", "ć", "dź", "ś", "ź", "ń", "l", "ść", "źdź", "śl", "śń", "źń", "j", "i", "y"]

const POLISH_I_NAMES := ["alusi", "ani", "asi", "basi", "danusi", "dosi", "frani", "gabrysi", "geni", "gosi", "halusi", "hani", "jadzi", "jagusi", "joasi", "kasi", "kazi", "krysi", "mani", "marysi", "reni", "rysi", "soni", "stasi", "stasi", "stefci", "tosi", "wiesi", "władzi", "zosi", "zuzi"]

const vowels := "aeiouyąęó"

# Gender: "M" or "F"
# Case: 1 (genitive), 2 (dative), 3 (accusative), 4 (instrumental), 5 (locative) or 6 (vocative)
static func decline_name(name: String, gender: String, case: int) -> String:
	if case == Cases.NOMINATIVE or not case in Cases.values():
		return name

	var suffix := name[-1]
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

static func _get_masculine_declension(stem: String, case: int) -> String:
	if stem.to_lower().ends_with("ek"):
		stem = stem.trim_suffix("ek") + "k"
	match case:
		Cases.GENITIVE, Cases.ACCUSATIVE:
			return stem + "a"
		Cases.DATIVE:
			return stem + "owi"
		Cases.INSTRUMENTAL:
			if stem.to_lower().ends_with("k") or stem.to_lower().ends_with("g"):
				return stem + "iem"
			else:
				return stem + "em"
		Cases.LOCATIVE, Cases.VOCATIVE:
			if _has_hard_final(stem, true):
				return _soften_final(stem) + "e"
			else:
				return stem + "u"
		_:
			assert(false, "Unexpected case for Polish adjective declension: %s" % case)
			return ""

static func _get_feminine_declension(stem: String, case: int) -> String:
	match case:
		Cases.GENITIVE:
			return _add_i_or_y(stem)
		Cases.DATIVE, Cases.LOCATIVE:
			if _has_hard_final(stem):
				return _soften_final(stem) + "e"
			else:
				return _add_i_or_y(stem)
		Cases.ACCUSATIVE:
			return stem + "ę"
		Cases.INSTRUMENTAL:
			return stem + "ą"
		Cases.VOCATIVE:
			if stem.to_lower() in POLISH_I_NAMES:
				return stem + "u"
			else:
				return stem + "o"
		_:
			assert(false, "Unexpected case for Polish feminine declension: %s" % case)
			return ""

static func _get_adjective_declension(stem: String, group: int, case: int) -> String:
	var i := "i" if group == 2 else ""
	var yi := "i" if group == 2 else "y"

	match case:
		Cases.GENITIVE, Cases.ACCUSATIVE:
			return stem + i + "ego"
		Cases.DATIVE:
			return stem + i + "emu"
		Cases.INSTRUMENTAL, Cases.LOCATIVE:
			return stem + yi + "m"
		Cases.VOCATIVE:
			return stem + yi
		_:
			assert(false, "Unexpected case for Polish adjective declension: %s" % case)
			return ""

static func _add_i_or_y(string: String) -> String:
	if string.to_lower() in POLISH_I_NAMES: # If the stem ends with -i and it’s a native Polish name, we don’t add anything
		return string
	for final in I_OVER_Y:
		if string.to_lower().ends_with(final):
			return string + "i"
	return string + "y"

static func _has_hard_final(string: String, excludeKGCh := false) -> bool:
	for final in HARD_TO_SOFT:
		if ((not excludeKGCh) or (not final in HARD_EXCEPTIONS)) and string.to_lower().ends_with(final):
			return true
	return false

static func _soften_final(string: String) -> String:
	for final in HARD_TO_SOFT:
		if string.to_lower().ends_with(final):
			return string.trim_suffix(final) + HARD_TO_SOFT[final]
	return string
