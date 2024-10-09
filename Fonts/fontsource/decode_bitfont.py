import json, os, re, sys

if len(sys.argv) < 2:
	print("Syntax: decode_bitfont file_to_decode.txt")
	exit()

SUFFIX_DECODED = '-d'
SUFFIX_ENCODED = '-e'

fileNameIn = sys.argv[1]
fileSplit = os.path.splitext(fileNameIn)

if fileSplit[0].endswith(SUFFIX_ENCODED):
	fileNameOut = fileSplit[0][:-len(SUFFIX_ENCODED)] + fileSplit[1]
elif fileSplit[0].endswith(SUFFIX_DECODED):
	print("This file already includes line breaks")
	exit()
else:
	fileNameOut = fileSplit[0] + SUFFIX_DECODED + fileSplit[1]

with open(fileNameIn, 'r', encoding="utf-8") as fileIn:
	jsonIn = json.load(fileIn)

jsonOut = {}

for keyCode in jsonIn:
	if keyCode.isnumeric():
		jsonOut[chr(int(keyCode))] = jsonIn[keyCode]
	else:
		jsonOut[keyCode] = jsonIn[keyCode]

strContent = json.dumps(jsonOut, ensure_ascii=False, separators=[",", ":"])

strContent = re.sub(r'([^,][\]"e]), *"', r'\g<1>,\n"', strContent)

with open(fileNameOut, 'w', encoding="utf-8") as fileOut:
	fileOut.write(strContent)