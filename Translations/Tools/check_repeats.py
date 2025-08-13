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
			lineId = f"{segment}_{lineId}"
			langSymbol = reLine.group(2)
			lineContent = reLine.group(3)
			if langSymbol == "O":
				repeatsDict.setdefault(lineContent, []).append(lineId)
			else:
				langIdx = int(langSymbol[1:]) if langSymbol[1:] else 1
				translatedLines[languages[langIdx]][lineId] = lineContent

	counter = 0
	for line in repeatsDict:
		if len(repeatsDict[line]) > 1: # This is a repeat
			if len(languages[1:]) > 0:
				for lang in languages[1:]:
					wrongRepeats = []
					for repeatedLineId in repeatsDict[line][1:]:
						firstRepeatedLineId = repeatsDict[line][0]
						if translatedLines[lang][repeatedLineId] != translatedLines[lang][firstRepeatedLineId]\
						and translatedLines[lang][repeatedLineId] != ""\
						and translatedLines[lang][firstRepeatedLineId] != "":
							if not wrongRepeats:
								wrongRepeats.append(firstRepeatedLineId)
							wrongRepeats.append(repeatedLineId)
					if wrongRepeats:
						counter += 1
						print(f"POTENTIAL WRONG REPEAT IN LANGUAGE “{lang}”!")
						print(f"“{line}”")
						for lineId in wrongRepeats:
							print(f"{lineId}: {translatedLines[lang][lineId]}")
						print()
			else: # Single-language mode
				print(f"Repeated in {", ".join(repeatsDict[line])}:")
				print(line)
				print()
				counter += 1

	print(f"{counter} groups in total")

if len(sys.argv) < 2:
    print("Syntax: check_repeats source_language target_language_1 [target_language_2] [...]")
    exit()

parseDialogue(sys.argv[1:])
