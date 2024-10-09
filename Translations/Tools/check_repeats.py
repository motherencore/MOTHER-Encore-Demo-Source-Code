import re, sys

def parseDialogue(languages):
	repeatsDict = {}
	translatedLines = {}

	for lang in languages[1:]:
		translatedLines[lang] = {}

	scriptFile = open(f"text-{'-'.join(languages)}/dialogue.txt", "r", encoding="utf-8")
	lines = scriptFile.readlines()

	for line in lines:
		if reLine := re.match(r'^= (.*)$', line):
			segment = reLine.group(1)
		elif reLine := re.match(r'^([\w\.]+)-(O|T\d{0,2}): (.*)$', line):
			lineId = reLine.group(1)
			lineId = f"{segment} > {lineId}"
			langSymbol = reLine.group(2)
			lineContent = reLine.group(3)
			if langSymbol == "O":
				repeatsDict.setdefault(lineContent, []).append(lineId)
			else:
				langIdx = int(langSymbol[1:]) if langSymbol[1:] else 1
				translatedLines[languages[langIdx]][lineId] = lineContent

	for line in repeatsDict:
		if len(repeatsDict[line]) > 1:
			for repeatedLineId in repeatsDict[line][1:]:
				firstRepeatedLineId = repeatsDict[line][0]
				for lang in languages[1:]:
					if translatedLines[lang][repeatedLineId] != translatedLines[lang][firstRepeatedLineId]:
						print(f"WRONG REPEATED LINE IN LANGUAGE “{lang}”!")
						print(f"“{line}”")
						print(f"{repeatedLineId}: {translatedLines[lang][repeatedLineId]}")
						print(f"{firstRepeatedLineId}: {translatedLines[lang][firstRepeatedLineId]}")
						print()

if len(sys.argv) < 3:
    print("Syntax: check_repeats source_language target_language_1 [target_language 2] [...]")
    exit()

parseDialogue(sys.argv[1:])
