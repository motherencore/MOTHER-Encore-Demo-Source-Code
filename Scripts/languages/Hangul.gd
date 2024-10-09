# LOCALIZATION Code added: For Korean typing on the Naming Screen
# Based on https://github.com/jonghwanhyeon/hangul-jamo, now rewritten in GDScript and adapted to fit our needs
# Reference: http://www.unicode.org/versions/Unicode8.0.0/ch03.pdf#G24646 (page 142)

const BASE_OF_SYLLABLES = 0xAC00
 
const BASE_OF_LEADING_CONSONANTS = 0x1100
const BASE_OF_VOWELS = 0x1161
const BASE_OF_TRAILING_CONSONANTS = 0x11A7 #  one less than the beginning of the range of trailing consonants (0x11A8)
 
const NUMBER_OF_LEADING_CONSONANTS = 19
const NUMBER_OF_VOWELS = 21
const NUMBER_OF_TRAILING_CONSONANTS = 28 # one more than the number of trailing consonants
 
const NUMBER_OF_SYLLABLES_FOR_EACH_LEADING_CONSONANT = NUMBER_OF_VOWELS * NUMBER_OF_TRAILING_CONSONANTS # 가-깋 + 1
const NUMBER_OF_SYLLABLES = NUMBER_OF_LEADING_CONSONANTS * NUMBER_OF_SYLLABLES_FOR_EACH_LEADING_CONSONANT
 
const LEADING_CONSONANTS = ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']
const VOWELS = ['ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ', 'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ', 'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ', 'ㅡ', 'ㅢ', 'ㅣ']
const TRAILING_CONSONANTS = [null, 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ', 'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ', 'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ']

const VOWEL_DIGRAPHS = {'ㅗㅏ':'ㅘ','ㅗㅐ':'ㅙ','ㅗㅣ':'ㅚ','ㅜㅓ':'ㅝ','ㅜㅔ':'ㅞ','ㅜㅣ':'ㅟ','ㅡㅣ':'ㅢ'}
const CONSONANT_DIGRAPHS = {'ㄱㅅ':'ㄳ','ㄴㅈ':'ㄵ','ㄴㅎ':'ㄶ','ㄹㄱ':'ㄺ','ㄹㅁ':'ㄻ','ㄹㅂ':'ㄼ','ㄹㅅ':'ㄽ','ㄹㅌ':'ㄾ','ㄹㅍ':'ㄿ','ㄹㅎ':'ㅀ','ㅂㅅ':'ㅄ'}

func _is_hangul_syllable(syllable: String):
	if len(syllable) != 1:
		return false
	var index_of_syllable = ord(syllable) - BASE_OF_SYLLABLES
	return (0 <= index_of_syllable) and (index_of_syllable < NUMBER_OF_SYLLABLES)

func _is_jamo_character(character: String):
	if len(character) != 1:
		return false
	return (character in LEADING_CONSONANTS) or (character in VOWELS) or (character in TRAILING_CONSONANTS)

func _compose_jamo_characters(leading_consonant: String, vowel: String, trailing_consonant: String = ""):
	var index_of_leading = LEADING_CONSONANTS.find(leading_consonant)
	var index_of_vowel = VOWELS.find(vowel)

	if index_of_leading == -1 or index_of_vowel == -1:
		#print("Given jamo character contains invalid Hangul jamo character")
		return null

	# Vérifier que les index existent
	var index_of_leading_consonant_and_vowel = (index_of_leading * NUMBER_OF_SYLLABLES_FOR_EACH_LEADING_CONSONANT) \
		+ (index_of_vowel * NUMBER_OF_TRAILING_CONSONANTS)
	
	var index_of_syllable = index_of_leading_consonant_and_vowel
	if trailing_consonant != "":
		var index_of_trailing = TRAILING_CONSONANTS.find(trailing_consonant)
		if index_of_trailing == -1:
			#print("Given jamo character contains invalid Hangul jamo character")
			return null
		
		index_of_syllable += index_of_trailing
		
	return char(BASE_OF_SYLLABLES + index_of_syllable)

func _decompose_syllable(syllable: String):
	if !_is_hangul_syllable(syllable):
		#print('%s is not a Hangul syllable' % syllable)
		return

	var index_of_syllable = ord(syllable) - BASE_OF_SYLLABLES

	var index_of_leading_consonant = index_of_syllable / NUMBER_OF_SYLLABLES_FOR_EACH_LEADING_CONSONANT
	var index_of_vowel = fposmod(index_of_syllable, NUMBER_OF_SYLLABLES_FOR_EACH_LEADING_CONSONANT) / NUMBER_OF_TRAILING_CONSONANTS
	var index_of_trailing_consonant = fposmod(index_of_syllable, NUMBER_OF_TRAILING_CONSONANTS)

	return [
		LEADING_CONSONANTS[index_of_leading_consonant],
		VOWELS[index_of_vowel],
		TRAILING_CONSONANTS[index_of_trailing_consonant]
	]

func compose_addition(prevStr: String, newChar: String):
	print("compose_with_previous %s %s" % [prevStr, newChar])
	if prevStr == "":
		return # Back to default handling
	var prevChar = prevStr[-1]
	var prevPrevStr = prevStr.trim_suffix(prevChar)
	if !(_is_jamo_character(prevChar) or _is_hangul_syllable(prevChar)):
		# Nothing Korean in all that
		return # Back to default handling
	elif _is_jamo_character(prevChar):
		# After a jamo
		if VOWEL_DIGRAPHS.has(prevChar + newChar):
			# It's a digraph => V[V]
			return prevPrevStr + VOWEL_DIGRAPHS[prevChar + newChar]
		else:
			# Not a digraph? Then maybe a composition is possible! => C+[V]
			var composition = _compose_jamo_characters(prevChar, newChar)
			if composition:
				return prevPrevStr + composition
			else:
				return # Back to default handling
	elif _is_hangul_syllable(prevChar):
		var decomposition = _decompose_syllable(prevChar)
		if !decomposition:
			# Decomposition fails
			return # Back to default handling
		else:
			if !decomposition[2]:
				# If third jamo is null: there is only C+V now
				if VOWEL_DIGRAPHS.has(decomposition[1] + newChar):
					# Maybe the vowel can form a digraph with the new one? => C+V[V]
					var newComposition = _compose_jamo_characters(decomposition[0], VOWEL_DIGRAPHS[decomposition[1] + newChar])
					if newComposition:
						return prevPrevStr + newComposition
					else:
						return # Back to default handling
				else:
					# Otherwise, we can try to use the new character in a composition with the existing C+V?
					var recomposition = _compose_jamo_characters(decomposition[0], decomposition[1], newChar)
					if recomposition:
						return prevPrevStr + recomposition
					else:
						return # Back to default handling
			else:
				# If third jamo isn't null: we already have a full C+V+[C] composition
				if CONSONANT_DIGRAPHS.has(decomposition[2] + newChar):
					# Maybe the trailing consonant can form a digraph with the new one? => C+V+C[C]
					var recomposition = _compose_jamo_characters(decomposition[0], decomposition[1], CONSONANT_DIGRAPHS[decomposition[2] + newChar])
					if recomposition:
						return prevPrevStr + recomposition
					else:
						return # Back to default handling
				else:
					# Maybe we can try to divide the composition into two? C+V / C+[V]
					var recompo1
					var recompo2
					if CONSONANT_DIGRAPHS.values().has(decomposition[2]):
						var digraphConsonants = CONSONANT_DIGRAPHS.keys()[CONSONANT_DIGRAPHS.values().find(decomposition[2])]
						# Subcase if the second C is actually CC
						recompo1 = _compose_jamo_characters(decomposition[0], decomposition[1], digraphConsonants[0])
						recompo2 = _compose_jamo_characters(digraphConsonants[1], newChar)
					else:
						# Normal subcase
						recompo1 = _compose_jamo_characters(decomposition[0], decomposition[1])
						recompo2 = _compose_jamo_characters(decomposition[2], newChar)
					if recompo1 and recompo2:
						return prevPrevStr + recompo1 + recompo2
					else:
						return # Back to default handling


func compose_removal(s: String):
	if s == "":
		return # Back to default handling
	var lastChar = s[-1]
	var slicedString = s.trim_suffix(lastChar)

	if !_is_hangul_syllable(lastChar):
		if VOWEL_DIGRAPHS.values().has(lastChar):
			var digraphVowels = VOWEL_DIGRAPHS.keys()[VOWEL_DIGRAPHS.values().find(lastChar)]
			return slicedString + digraphVowels[0]
		else:
			return # Back to default handling
	else:
		var decomposition = _decompose_syllable(lastChar)
		if !decomposition:
			return # Back to default handling
		else:
			if !decomposition[2]:
				# If third jamo is null: there is only C+V now
				if VOWEL_DIGRAPHS.values().has(decomposition[1]):
					# Maybe the V is actually VV?
					# Obtening the key from the value (a bit dirty, yeah...)
					var digraphVowels = VOWEL_DIGRAPHS.keys()[VOWEL_DIGRAPHS.values().find(decomposition[1])]
					var recomposition = _compose_jamo_characters(decomposition[0], digraphVowels[0])
					if recomposition:
						return slicedString + recomposition
					else:
						# Couldn't recompose: let's ignore the Vs and just use the first C
						return slicedString + decomposition[0]
				else:
					return slicedString + decomposition[0]
			else:
				# Otherwise: full C+V+C syllable
				if CONSONANT_DIGRAPHS.values().has(decomposition[2]):
					# Maybe the last C is actually CC?
					var digraphConsonants = CONSONANT_DIGRAPHS.keys()[CONSONANT_DIGRAPHS.values().find(decomposition[2])]
					var recomposition = _compose_jamo_characters(decomposition[0], decomposition[1], digraphConsonants[0])
					if recomposition:
						return slicedString + recomposition
					else:
						# Couldn't recompose: then let's just recompose without the digraph...
						recomposition = _compose_jamo_characters(decomposition[0], decomposition[1])
						if recomposition:
							return slicedString + recomposition
						else:
							return
				else:
					var recomposition = _compose_jamo_characters(decomposition[0], decomposition[1])
					if recomposition:
						return slicedString + recomposition
					else:
						return

func ends_with_vowel(s: String, include_rieul: bool = false):
	if s == "":
		return false

	s = s.split(" ")[-1]

	var last_char = s[-1].to_lower()
	var word_length = s.length()

	if _is_jamo_character(last_char):
		return last_char in VOWELS or (include_rieul and last_char == 'ㄹ')
	elif _is_hangul_syllable(last_char):
		var final_consonant = _decompose_syllable(last_char)[2]
		return final_consonant == null or (include_rieul and final_consonant == 'ㄹ')
	elif last_char.is_valid_integer():
		return last_char in "2459" or (include_rieul and last_char in "178")
	elif last_char in "abcdefghijklmnopqrstuvwxyz": #and word_length == 1:
		return not last_char in "lmnr" or (include_rieul and last_char in "lr")
	elif last_char in "aeiouyáàâäãāǎăȧąạæéèêëẽēěĕėęẹíìîïĩīǐĭıįịóòôöõōǒŏȯǫọœúùûüũūǔŭųụýỳŷÿỹȳẏỵａｅｉｏｕｙ":
		return true
	elif last_char in "αβγως":
		return true
	elif last_char in "あかさたなはいきしちにひうくすつぬふえけせてねへおこそとのほまやらわぁゃみりぃむゆるをぅゅめれぇもよろぉょがざだばぱぎじぢびぴぐずづぶぷげぜでべぺごぞどぼぽアカサタナハイキシチニヒウクスツヌフエケセテネヘオコソトノホマヤラワァャミリィムユルヲゥュメレェモヨロォョガザダバパギジヂビピグズヅブプゲゼデベペゴゾドボポ":
		return true
	else:
		return false
