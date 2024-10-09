import json, re, sys

if len(sys.argv) < 3:
	print("Syntax: merge_fonts [destination] [source] [force]")
	print("where [destination] and [source] are two bitmap fonts in json format from BitFontMaker2")
	exit()

sourceFileName = sys.argv[2]
destFileName = sys.argv[1]
forceInsert = (len(sys.argv) > 3)

with open(destFileName, "r") as f:
	destJson = json.load(f)

with open(sourceFileName, "r") as f:
	sourceJson = json.load(f)

for char in sourceJson:
	if char.isnumeric() and (forceInsert or (char not in destJson)):
		destJson[char] = sourceJson[char]

# Sorting in the original key order: by unicode value, with the metadata at the end
destJson = dict(sorted(destJson.items(), key=lambda s: ord(s[0]) if len(s[0]) == 1 else sys.maxsize))

destJsonStr = json.dumps(destJson, separators=(',', ':'))
destJsonStr = destJsonStr.replace(',"', ',\n"')

with open(destFileName, "w") as f:
	f.write(destJsonStr)
