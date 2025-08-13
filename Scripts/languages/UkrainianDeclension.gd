class_name UkrainianDeclension
extends CustomNameDeclension

enum Cases {NOMINATIVE, GENITIVE, DATIVE, ACCUSATIVE, INSTRUMENTAL, LOCATIVE}

const FEMININE_MARKS := "ая"

const CONSONANTS := "бвгґджзклмнпрстфхцчшщйь"
const LATIN_CONSONANTS := "bcdfghjklmnpqrstvwxz"

# Whitelist of Ukrainian names ending with -е, -о or ь but still declinable
const UKRAINIAN_SOFT_ENDING_NAMES := ["Петро", "Михайло", "Левко", "Сильвестро", "Ілліко", "Опанасо", "Матвієво", "Трохимо", "марко", "степано", "дем'янко", "миколо", "мирославо", "Гаврило", "Андро", "Феофано", "Агапо", "Плато", "Антоло", "лове", "томе", "іване", "Лаврінь", "Любомирь", "Аскольдь", "Ігорь", "Юрь"]

# Gender: "M" or "F"
# Case: 1 (genitive), 2 (dative), 3 (accusative), 4 (instrumental), 5 (locative)
static func decline_name(name: String, gender: String, case: int) -> String:
	if case == Cases.NOMINATIVE or not case in Cases.values():
		return name
	
	var suffix := name[-1]
	var stem = name.trim_suffix(suffix)
	var suffix_low := suffix.to_lower()

	if stem == "":
		return name
	elif suffix_low in FEMININE_MARKS:
		return _get_feminine_declension(stem, suffix, case)
	else:
		if gender == "F":
			return name
		elif suffix_low in CONSONANTS or name.to_lower() in UKRAINIAN_SOFT_ENDING_NAMES:
			return _get_masculine_declension(stem, suffix, case)
		else:
			return name

static func _get_masculine_declension(stem: String, suffix: String, case: int):
	var suffix_low := suffix.to_lower()

	if case == Cases.GENITIVE and suffix_low in "ео":
		return stem + "я"
	if suffix_low == "ь":
		return stem + ["я", "ю", "я", "ем", "і"][case - 1]
	elif suffix_low == "й":
		return stem + ["я", "єві", "я", "єм", "єві"][case - 1]
	else: # General case
		stem += suffix
		if suffix_low in LATIN_CONSONANTS:
			stem += "'"
		return stem + ["а", "ові", "а", "ом", "і"][case - 1]

static func _get_feminine_declension(stem: String, suffix: String, case: int):
	var suffix_low := suffix.to_lower()

	if suffix_low == "а":
		return stem + ["и", "і", "у", "ою", "і"][case - 1]
	elif suffix_low == "я":
		if stem.ends_with("і") or stem.ends_with("ї"):
			return stem + ["ї", "ї", "ю", "єю", "ї"][case - 1]
		else:
			return stem + ["і", "і", "ю", "ею", "і"][case - 1]
	else:
		push_error("Unexpected name for Ukrainian feminine declension: %s" % (stem + suffix))
		return stem + suffix
