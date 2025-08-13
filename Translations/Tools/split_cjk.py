import csv, glob, json, os, re, sys

FOLDER_FONT_WIDTHS = "../../Fonts/fontsource/widths"
FOLDER_CSV = "../TranslatedText"
TAG_BRACKETS = {"[":"]", "{":"}"}
ZERO_WIDTH_CHAR = "​"
SPACE_CHARACTERS = [" ","　",ZERO_WIDTH_CHAR]
SPLIT_AFTER_CHARACTERS = ["、", "。"]
DONT_SPLIT_BEFORE_CHARACTERS = [")", "）"]

DIALOG_BOX_WIDTH = 240
BATTLE_BOX_WIDTH = 255

langContext = {
	"ja": {
		"fontWidthFiles": ["EBMainjaM3_widths.json", "EBMainfw9_widths.json"],
		"maxLenPartyMember": 6,
		"maxLenFood": 10,
		"maxLenBattler": 9,
		"maxLenItem": 10,
		"maxLenStat": 6,
		"maxLenValue": 5,
		"maxLenInput": 7,
		"maxLenArticle": 1000,
		"defaultSpaceCharacter": "　",
		"biggestCharText": 'あ',
		"biggestCharNumbers": '8',
		"imageTags": {"[Asthma]":20, "[Blinded]":20, "[Burned]":10, "[Cold]":10, "[Confused]":20, "[Forgetful]":20, "[Mushroomized]":10, "[Nausea]":20, "[Numb]": 20, "[Poisoned]":20, "[Sleeping]":20, "[Sunstroked]":20}
	},
	"ko": {
		"fontWidthFiles": ["EBMainko_widths.json", "EBMain_widths.json"],
		"maxLenPartyMember": 6,
		"maxLenFood": 10,
		"maxLenBattler": 9,
		"maxLenItem": 10,
		"maxLenStat": 4,
		"maxLenValue": 5,
		"maxLenInput": 6,
		"maxLenArticle": 1,
		"defaultSpaceCharacter": " ",
		"biggestCharText": '낡',
		"biggestCharNumbers": '8',
		"imageTags": {"[Asthma]":14, "[Blinded]":17, "[Burned]":10, "[Cold]":10, "[Confused]":14, "[Forgetful]":11, "[Mushroomized]":10, "[Nausea]":17, "[Numb]": 12, "[Poisoned]":15, "[Sleeping]":15, "[Sunstroked]":14}
	}
}

maxLenCash = 6

# Array where each element is an object related to a font that specifies the width of each character in the font
allFontsWidths = []

absentChars = {}
variableWidthChars = {}

def removeEOF(fileName):
	# Now removing new line at the end of file
	with open(fileName, 'r+', newline="") as f:
		f.seek(0, 2)
		f.seek(f.tell() - 2)
		last_char = f.read() 
		if last_char == '\r\n':
			f.truncate(f.tell() - 2)

def importFontWidths():
	# Init with zero-width space
	zeroWidthFont = {}
	zeroWidthFont[ZERO_WIDTH_CHAR] = 0
	allFontsWidths.append(zeroWidthFont)

	# Insert all other fonts
	for fName in fontWidthFiles:
		with open(f"{FOLDER_FONT_WIDTHS}/{fName}", "r") as f:
			allFontsWidths.append(json.load(f))

def getTagWidth(tagStr):
	match tagStr:
		case "[Ninten]" | "[Ana]" | "[Lloyd]" | "[Teddy]" | "[Pippi]" | "[PartyLead]" | "[User]" | "[ItemReceiver]":
			return getStringWidth(biggestCharText * maxLenPartyMember)
		case "[FavFood]":
			return getStringWidth(biggestCharText * maxLenFood)
		case "{name}" | "{target}":
			return getStringWidth(biggestCharText * maxLenBattler)
		case "[ItemName]" | "{item}" | "{courageBadge}" | "{franklinBadge}":
			return getStringWidth(biggestCharText * maxLenItem)
		case "{stat}":
			return getStringWidth(biggestCharText * maxLenStat)
		case "{value}":
			return getStringWidth(biggestCharNumbers * maxLenValue)
		case "[N]":
			return getStringWidth(biggestCharText)
		case "[EarnedCash]" | "[CurrentCash]" | "[BankCash]":
			return getStringWidth(biggestCharNumbers * maxLenCash)
		case _:
			if tagStr in imageTags:
				return imageTags[tagStr]
			if re.fullmatch(r"\[if [\w:]+\]", tagStr):
				return None # Don’t close the tag
			if re.fullmatch(r"\[if [\w:]+\](.*?)\[else\]", tagStr):
				return None # Don’t close the tag
			if re.fullmatch(r"\[else\]", tagStr):
				return None # Don’t close the tag
			if m := re.fullmatch(r"\[if [\w:]+\](.*?)\[else\](.*?)\[/if\]", tagStr):
				return getStringWidth(m.group(1))
			if m := re.fullmatch(r"\[if [\w:]+\](.*?)\[/if\]", tagStr):
				return getStringWidth(m.group(1))
			if re.fullmatch(r"\[color=#?\w*\]", tagStr):
				return 0
			if re.fullmatch(r"\[DELAY(:[\d:]*)?\]", tagStr):
				return 0
			if re.fullmatch(r"\[/?color\]", tagStr):
				return 0
			if re.fullmatch(r"\[ui_\w+\]", tagStr):
				return getStringWidth(biggestCharNumbers * maxLenInput)
			if re.fullmatch(r"\[\w+Art\d+\]", tagStr):
				return getStringWidth(biggestCharText * maxLenArticle)
			if re.fullmatch(r"\[ko_part:[^\]]+\]", tagStr):
				return getStringWidth(biggestCharText * maxLenArticle)
			if re.fullmatch(r"\{member\d?\}", tagStr):
				return getStringWidth(biggestCharText * maxLenPartyMember)
			print(f"  Couldn’t find tag: {tagStr}")
			return 0

def getStringWidth(string):
	currentTag = ""
	width = 0
	for c in string:
		if len(currentTag) > 0:
			# If a bracket was open previously
			currentTag += c
			if c in TAG_BRACKETS.values():
				# If the closing bracket and the opening one make a good match...
				if TAG_BRACKETS[currentTag[0]] == c:
					tagWidth = getTagWidth(currentTag)
					if tagWidth != None:
						width += getTagWidth(currentTag)
						currentTag = ""
		else:
			# General case
			if c in TAG_BRACKETS:
				currentTag += c
			else:
				charWidth = None
				# Searching the current character width in fonts, including alt fonts
				for fontWidths in allFontsWidths:
					if c in fontWidths:
						charWidth = fontWidths[c]
						break
				
				if charWidth is not None:
					width += charWidth
					if c != biggestCharText and charWidth != getStringWidth(biggestCharText) and c != ZERO_WIDTH_CHAR:
						variableWidthChars[c] = 1 if c not in variableWidthChars else variableWidthChars[c] + 1
				else:
					absentChars[c] = 1 if c not in absentChars else absentChars[c] + 1
					width += getStringWidth(biggestCharText)
	
	if len(currentTag) == 0:
		return width

# Adds \n breaks to a line of dialogue
def splitLine(fullLine, boxWidth):
	fullLineArray = fullLine.split('\n')
	# If there are already line breaks in the string...
	if len(fullLineArray) > 1:
		# Then call this function recursively for the different pieces of it
		return splitLine(fullLineArray[0], boxWidth) + '\n' \
			+ splitLine('\n'.join(fullLineArray[1:]), boxWidth)

	latestSpacePosition = None
	for pos in range(len(fullLine)):
		if fullLine[pos] in SPACE_CHARACTERS:
			latestSpacePosition = pos
		width = getStringWidth(fullLine[0:pos+1])
		if width is not None and width > boxWidth and latestSpacePosition is not None:
			# Replacing space with line break
			fullLine = fullLine[:latestSpacePosition] + "\n" + fullLine[latestSpacePosition + 1:]
			# Then recursively call this function now that a linebreak has been added
			return splitLine(fullLine, boxWidth)

	return fullLine

def preHandleString(fullLine):
	#fullLine = fullLine.replace("\\n", "\n")
	fullLine = removePreviousBreaks(fullLine)
	for c in SPLIT_AFTER_CHARACTERS:
		fullLine = fullLine.replace(c, c + ZERO_WIDTH_CHAR)
		for cc in DONT_SPLIT_BEFORE_CHARACTERS:
			fullLine = fullLine.replace(c + ZERO_WIDTH_CHAR + cc, c + cc)
	return fullLine

# Reverts the process by removing those line breaks
def removePreviousBreaks(fullLine):
	for c in SPLIT_AFTER_CHARACTERS:
		fullLine = fullLine.replace(c + "\\n", c)
	fullLine = fullLine.replace("\\n", defaultSpaceCharacter)
	return fullLine

def postHandleString(fullLine):
	fullLine = fullLine.replace("\n", "\\n")
	fullLine = fullLine.replace(ZERO_WIDTH_CHAR, "")
	return fullLine

# A line can also contain hard breaks, so we have to take care of that first
def splitLineWithHardBreaks(fullLine, separators, boxWidth):
	pattern = f"({'|'.join(map(re.escape, separators))})"
	parts = re.split(pattern, fullLine)
	#for i, part in enumerate(parts):
	#	parts[i] = splitLine(parts[i], boxWidth)

	processedParts = [
		splitLine(parts[i], boxWidth) if i % 2 == 0 else part  # Apply operation only to non-separators
		for i, part in enumerate(parts)
    ]
	
	return "".join(processedParts)

def processLine(fullLine, boxWidth, readOnlyMode):
	if not readOnlyMode:
		# Preparing the string (replacing \n with \\n, adding empty spacers after comma, etc.) + the actual splitting!
		fullLine = preHandleString(fullLine)
		fullLine = splitLineWithHardBreaks(fullLine, ["[BR]", "[WAIT@]", "[WAITBR]", "[@]", "[BR@]"], boxWidth)
		fullLine = postHandleString(fullLine)
		return fullLine
	else:
		fullLineArray = re.split(r"\[BR@?\]|\[WAIT@\]|\[@\]|\[WAITBR\]|\n|\\n", fullLine)
		for subLine in fullLineArray:
			stringWidth = getStringWidth(subLine)
			if stringWidth is None:
				print(f"  Couldn’t measure string: “{subLine}”")
			elif getStringWidth(subLine) > boxWidth:
				print(f"  Too long line: “{subLine}”")

def parseCsv(fileName, boxWidth, readOnlyMode):
	print(f"Parsing file “{os.path.basename(fileName)}”")
	global absentChars, variableWidthChars
	absentChars = {}
	variableWidthChars = {}
	with open(fileName, 'r', encoding="utf-8") as f:
		reader = csv.reader(f, delimiter=",")
		rows = list(reader)
	langIndex = rows[0].index(langCode)
	if langIndex == -1:
		print(f"  Language “{langCode}” not found in csv")

	for row in rows[1:]:
		row[langIndex] = processLine(row[langIndex], boxWidth, readOnlyMode)

	# We also keep track of characters absent from the font or with variable width...
	for c in absentChars:
		print(f"  Couldn’t find character: “{c}” ({ord(c)} / {hex(ord(c))}) {absentChars[c]} times, adding size of {biggestCharText} instead")
	if variableWidthChars:
		print(f"  Variable width chars used: “{''.join(variableWidthChars.keys())}”")

	if not readOnlyMode:
		with open(fileName, 'w', encoding="utf-8") as f:
			writer = csv.writer(f, delimiter=",")
			writer.writerows(rows)
		removeEOF(fileName)


if len(sys.argv) <= 1:
	print("Syntax: split_cjk [lang_code]")
	print("Add any extra argument for check mode")
	exit()

langCode = sys.argv[1]
readOnlyMode = (len(sys.argv) > 2)

fontWidthFiles = langContext[langCode]["fontWidthFiles"]
maxLenPartyMember = langContext[langCode]["maxLenPartyMember"]
maxLenFood = langContext[langCode]["maxLenFood"]
maxLenBattler = langContext[langCode]["maxLenBattler"]
maxLenItem = langContext[langCode]["maxLenItem"]
maxLenStat = langContext[langCode]["maxLenStat"]
maxLenValue = langContext[langCode]["maxLenValue"]
maxLenInput = langContext[langCode]["maxLenInput"]
maxLenArticle = langContext[langCode]["maxLenArticle"]
defaultSpaceCharacter = langContext[langCode]["defaultSpaceCharacter"]
biggestCharText = langContext[langCode]["biggestCharText"]
biggestCharNumbers = langContext[langCode]["biggestCharNumbers"]
imageTags = langContext[langCode]["imageTags"]

importFontWidths()

files = glob.glob(f"{FOLDER_CSV}/dialogue*.csv")
for f in files:
	parseCsv(f, DIALOG_BOX_WIDTH, readOnlyMode)
	print()