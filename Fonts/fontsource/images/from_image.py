# Convert image to bytes
import PIL.Image as Image
import numpy as np
import json, os, sys

CHAR_WIDTH = 16
CHAR_HEIGHT = 10
CHAR_HEIGHT_FULL = 16

OFFSET_VERTICAL = 2
OFFSET_HORIZONTAL = 1

JSON_PARAMS = {"name":"EBMain","copy":"Anonymous","letterspace":"64","basefont_size":"512","basefont_left":"62","basefont_top":"0","basefont":"Georgia","basefont2":"","wordspacing":"3"}

CHARS_LIST = {
	# LATIN FULL-WIDTHS
	"＋": 59, "－": 60, "＊": 62, "／": 63, "＝": 64, "％": 82, "（": 41, "）": 42, 
	"［": 45, "］": 46, "，":  3, "．":  4, "：": 6,  "；":  7, "？":  8, "！":  9, 
	"｜":179, "＄": 79, "＆": 84, "～": 32, "｀":188, "￢":189, "＠":190, "⋯": 35, 
	# JAPANESE
	"「": 53, "」": 54, "、":  1, "。":  2, "・":280, "ー":281
	
}

CHARS_SEQUENCES = {
	# LATIN FULL-WIDTHS
	"０": {"start": 203, "count": 10},
	"⓪": {"start": 203, "count": 1},
	"①": {"start": 204, "count": 9},
	"Ａ": {"start": 220, "count": 26},
	"Ⓐ": {"start": 220, "count": 26},
	"ａ": {"start": 252, "count": 26},
	# JAPANESE
	"ぁ": {"start": 282, "count": 79},
	"を": {"start": 363, "count": 2},
	"ァ": {"start": 376, "count": 79},
	"ヲ": {"start": 457, "count": 3}
}


PX_WHITE = np.array([255, 255, 254])
PX_BLACK = np.array([2,0,0])

# From 2D array of RGB value to 2D array of bits
def _simplifyArray(arrayImg):
	result = []
	for i in range(len(arrayImg)):
		result.append([])
		for j in range(len(arrayImg[i])):
			if (arrayImg[i][j] == PX_WHITE).all():
				result[i].append(0)
			else:
				result[i].append(1)
	return result
	
# From image file to array (calls _simplifyArray)
def imgToArray(imgFile):
	img = Image.open(imgFile)
	return _simplifyArray(np.array(img, dtype=np.uint8))

# From the big array image to the array of one single character
def getCharacterArray(arr, index):
	result = []

	nbCols = len(arr[0]) // CHAR_WIDTH
	row = index // nbCols
	col = index % nbCols

	startY = row * CHAR_HEIGHT
	startX = col * CHAR_WIDTH
	
	for i in range(startY, startY + CHAR_HEIGHT):
		result.append([])
		for j in range(startX, startX + CHAR_WIDTH):
			result[i - startY].append(arr[i][j])

	for i in range(startY + CHAR_HEIGHT, startY + CHAR_HEIGHT_FULL):
		result.append([0] * CHAR_WIDTH)

	return result

# From a list of bits to a number, BitFontMaker format
def _listToByte(list):
	res = 0
	for i in range(len(list)):
		res += list[i] * pow(2,i)
	return res

# From the array of a character to the list of numbers, BitFontMaker format (calls listToByte)
def charArrayToByteList(arr):
	res = []
	for list in arr:
		res.append(_listToByte(list))
	return res

# Shifts 
def offsetArray(arr, rows, cols):
	if rows > 0:
		for i in range(rows):
			arr.pop()
			arr.insert(0, [0] * CHAR_WIDTH)
	elif rows < 0:
		for i in range(-rows):
			arr.pop(0)
			arr.append([0] * CHAR_WIDTH)

	if cols != 0:
		for r in arr:
			if cols > 0:
				for i in range(cols):
					r.pop()
					r.insert(0, 0)
			elif cols < 0:
				for i in range(-cols):
					r.pop(0)
					r.append(0)

fullImgArray = imgToArray(sys.argv[1])

finalJson = {}

for i in CHARS_LIST:
	charArray = getCharacterArray(fullImgArray, CHARS_LIST[i])
	offsetArray(charArray, OFFSET_VERTICAL, OFFSET_HORIZONTAL)
	finalJson[i] = charArrayToByteList(charArray)

for i in CHARS_SEQUENCES:
	startJsonKey = ord(i)
	imgIndex = CHARS_SEQUENCES[i]["start"]
	step = CHARS_SEQUENCES[i]["step"] if "step" in CHARS_SEQUENCES[i] else 1
	for j in range(0, CHARS_SEQUENCES[i]["count"]):
		charArray = getCharacterArray(fullImgArray, imgIndex)
		offsetArray(charArray, OFFSET_VERTICAL, OFFSET_HORIZONTAL)
		finalJson[chr(startJsonKey + j)] = charArrayToByteList(charArray)
		imgIndex += step

# Adding the params
for i in JSON_PARAMS:
	finalJson[i] = JSON_PARAMS[i]

# Sorting in the original key order: by unicode value, with the metadata at the end
finalJson = dict(sorted(finalJson.items(), key=lambda s: ord(s[0]) if len(s[0]) == 1 else sys.maxsize))

finalJsonStr = json.dumps(finalJson, ensure_ascii=False, separators=(',', ':'))
finalJsonStr = finalJsonStr.replace(',"', ',\n"')

file = open(sys.argv[2], "w", encoding="utf-8")
file.write(finalJsonStr)
