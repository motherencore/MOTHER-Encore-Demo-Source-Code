class_name RussianDeclension
extends CustomNameDeclension

enum Cases {NOMINATIVE, GENITIVE, DATIVE, ACCUSATIVE, PREPOSITIONAL}

const FEMININE_MARKS := "ая"

const CONSONANTS := "бвгджзклмнпрстфхцчшщъ"
const ALMOST_CONSONANTS := "ьй"
const SIBILANTS_AND_VELARS := "жчшщгкх"
const LATIN_CONSONANTS := "bcdfghjklmnpqrstvwxz"

const EXCEPTIONS_YO_TO_YE := ["пётр"]
const EXCEPTIONS_YO_TO_SOFT := ["васёк", "витёк"]

static func _handle_yo_exceptions(name: String) -> String:
	if name.to_lower() in EXCEPTIONS_YO_TO_YE:
		return name.replace("ё", "е").replace("Ё", "Е")
	elif name.to_lower() in EXCEPTIONS_YO_TO_SOFT:
		return name.replace("ё", "ь").replace("Ё", "Ь")
	else:
		return name

# Gender: "M" or "F"
# Case: 1 (genitive), 2 (dative), 3 (accusative) or 4 (prepositional)
static func decline_name(name: String, gender: String, case: int) -> String:
	if case == Cases.NOMINATIVE or not case in Cases.values():
		return name

	name = _handle_yo_exceptions(name)
	
	var suffix := name[-1]
	var stem := name.trim_suffix(suffix)

	var suffix_low := suffix.to_lower()

	if stem == "":
		return name
	elif suffix_low in FEMININE_MARKS:
		return _get_second_declension(stem, suffix, case)
	else:
		if gender == "F":
			if suffix_low == "ь":
				return _get_third_declension(stem, case)
			else:
				return name
		else:
			if suffix_low in LATIN_CONSONANTS + CONSONANTS + ALMOST_CONSONANTS:
				return _get_first_declension(stem, suffix, case)
			else:
				return name

static func _get_first_declension(stem: String, suffix: String, case: int) -> String:
	var suffix_low = suffix.to_lower()

	if suffix_low in ALMOST_CONSONANTS:
		if suffix_low == "й" and stem.to_lower().ends_with("и"):
			return stem + "яюяи"[case - 1]
		else:
			return stem + "яюяе"[case - 1]
	else:
		stem += suffix
		if suffix_low in LATIN_CONSONANTS:
			stem += "'"
		return stem + "ауае"[case - 1]

static func _get_second_declension(stem: String, suffix: String, case: int) -> String:
	var suffix_low := suffix.to_lower()
	var stem_low := stem.to_lower()


	if suffix_low == "а":
		if stem_low[-1] in SIBILANTS_AND_VELARS:
			return stem + "иеуе"[case - 1]
		else:
			return stem + "ыеуе"[case - 1]
	elif suffix_low == "я":
		if stem_low[-1] == "и":
			return stem + "ииюи"[case - 1]
		else:
			return stem + "иеюе"[case - 1]
	else:
		push_error("Unexpected name for Russian second declension: %s" % (stem + suffix))
		return stem + suffix

static func _get_third_declension(stem: String, case: int) -> String:
	return stem + "ииьи"[case - 1]
