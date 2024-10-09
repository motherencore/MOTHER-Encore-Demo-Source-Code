const GENITIVE		= 1
const DATIVE		= 2
const ACCUSATIVE 	= 3
const PREPOSITIONAL	= 4

const FEMININE_MARKS = "ая"

const CONSONANTS = "бвгджзклмнпрстфхцчшщъ"
const ALMOST_CONSONANTS = "ьй"
const LATIN_CONSONANTS = "bcdfghjklmnpqrstvwxz"

func get_russian_declension(name, gender, case):
	var is_all_caps = (name == name.to_upper())
	var declined_name = get_russian_declension_proceed(name, gender, case)
	if is_all_caps:
		return declined_name.to_upper()
	else:
		return declined_name


func get_russian_declension_proceed(name, gender, case):
	var suffix = name[-1]
	var stem = name.trim_suffix(suffix)

	var suffix_low = suffix.to_lower()

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


func _get_first_declension(stem, suffix, case):
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

func _get_second_declension(stem, suffix, case):
	var suffix_low = suffix.to_lower()
	var stem_low = stem.to_lower()

	if suffix_low == "а":
		if stem_low.ends_with("ш") or stem_low.ends_with("ж"):
			return stem + "иеуе"[case - 1]
		else:
			return stem + "ыеуе"[case - 1]
	elif suffix_low == "я":
		if stem_low.ends_with("и"):
			return stem + "ииюи"[case - 1]
		else:
			return stem + "иеюе"[case - 1]
	else:
		return stem + suffix

func _get_third_declension(stem, case):
	return stem + "ииьи"[case - 1]
