import json, os, re, sys

if len(sys.argv) < 2:
	print("Syntax: encode_bitfont file_to_encode.txt")
	exit()

SUFFIX_DECODED = '-d'
SUFFIX_ENCODED = '-e'

fileNameIn = sys.argv[1]
fileSplit = os.path.splitext(fileNameIn)

if fileSplit[0].endswith(SUFFIX_DECODED):
	fileNameOut = fileSplit[0][:-len(SUFFIX_DECODED)] + fileSplit[1]
elif fileSplit[0].endswith(SUFFIX_ENCODED):
	print("This file already has no line breaks")
	exit()
else:
	fileNameOut = fileSplit[0] + SUFFIX_ENCODED + fileSplit[1]

with open(fileNameIn, 'r', encoding="utf-8") as fileIn:
	jsonIn = json.load(fileIn)

jsonOut = {}

for key in jsonIn:
	if len(key) == 1:
		jsonOut[str(ord(key))] = jsonIn[key]
	else:
		jsonOut[key] = jsonIn[key]

strContent = json.dumps(jsonOut, ensure_ascii=False, separators=[",", ":"])

strContent = re.sub("\r?\n", "", strContent)

with open(fileNameOut, 'w') as fileOut:
	fileOut.write(strContent)
