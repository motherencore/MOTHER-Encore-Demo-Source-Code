# Fixes bitfontmaker2's tendency to decide for itself what the width of a glyph should be.

import glob, json, os, sys, re
from fontTools import ttLib
from fontTools.ttLib.tables._g_l_y_f import Glyph

PIXEL_WIDTH = 64

# Reduce advance of full width characters to a minimal (width + 1 pixel)
FULL_WIDTH_MINIMAL = False

class FontWrapper:
	@staticmethod
	def new(path):
		font = ttLib.TTFont(path)
		return FontWrapper(font)

	def __init__(self, ft):
		self.ftFont = ft
		self.cmap = ft.getBestCmap()

	@property
	def fontname(self):
		return self.ftFont['name'].getBestFamilyName()

	def __contains__(self, code):
		return code in self.cmap

	def __getitem__(self, code):
		return GlyphWrapper(self.ftFont, code)

	def createChar(self, code, width = 0):
		glyphName = "uni" + '{0:04X}'.format(code)
		self.ftFont["glyf"][glyphName] = Glyph()
		self.ftFont["hmtx"][glyphName] = (width, 0)
		self.cmap[code] = glyphName
		return GlyphWrapper(self.ftFont, code)
		
	def removeGlyph(self, code):
		glyphName = self.cmap[code]
		del self.ftFont["glyf"][glyphName]
		del self.ftFont["hmtx"][glyphName]
		del self.cmap[code]

	def generate(self, dest):
		self.ftFont.save(dest)


class GlyphWrapper:
	def __init__(self, ft, code):
		self.ftFont = ft
		cmap = ft.getBestCmap()
		self.glyphName = cmap[code]

	@property
	def width(self):
		return self.ftFont["hmtx"][self.glyphName][0]

	@width.setter
	def width(self, value):
		lsb = self.ftFont["hmtx"][self.glyphName][1]
		self.ftFont["hmtx"][self.glyphName] = (value, lsb)

	@property
	def right_side_bearing(self):
		return self.width - self.ftFont['glyf'][self.glyphName].xMax
	
	@right_side_bearing.setter
	def right_side_bearing(self, value):
		self.width = self.ftFont['glyf'][self.glyphName].xMax + value
	

def _charInfo(code):
	codeHex = hex(code)
	char = chr(code)
	return f"\"{char}\" ({code} / {codeHex})"

def _setGlyphWidth(font, code, width, createIfMissing = False, warnIfMissing = True):
	# Snap to pixel
	widthInPixels = round(width / PIXEL_WIDTH)
	width = PIXEL_WIDTH * widthInPixels

	if not font.__contains__(code):
		if createIfMissing:
			glyph = font.createChar(code, width)
			print(f"    Glyph created: {_charInfo(code)} of width {widthInPixels}")
			return 1
		else:
			if warnIfMissing:
				print(f"    Glyph {_charInfo(code)} is missing!")
			return 0
	else:
		glyph = font.__getitem__(code)
	
		if glyph.width != width:
			print(f"    Width of glyph {_charInfo(code)} changed: from {glyph.width // PIXEL_WIDTH} to {widthInPixels}")
			glyph.width = width
			return 1
		else:
			return 0

def _fixSameFixedWidth(font, ranges, rangeWhiteSpace = None):
	maxWidth = 0
	maxGlyph = 0
	for r in ranges:
		for i in range(r[0], r[1] + 1):
			if font.__contains__(i):
				glyph = font.__getitem__(i)
				curWidth = glyph.width
				if FULL_WIDTH_MINIMAL:
					curWidth += -glyph.right_side_bearing + PIXEL_WIDTH
				if curWidth > maxWidth:
					maxWidth = curWidth
					maxGlyph = i
	nbFixes = 0
	if maxGlyph != 0:
		for r in ranges:
			for i in range(r[0], r[1] + 1):
				nbFixes += _setGlyphWidth(font, i, maxWidth, False, False)
		nbFixes += _setGlyphWidth(font, rangeWhiteSpace, maxWidth, False, False)
	else:
		# If there’s no character in this range, let’s remove 
		if rangeWhiteSpace is not None and font.__contains__(rangeWhiteSpace):
			print(f"    Useless glyph {_charInfo(rangeWhiteSpace)} deleted")
			font.removeGlyph(rangeWhiteSpace)
			nbFixes += 1
	if nbFixes > 0:
		print(f"  {nbFixes} were fixed based on character {_charInfo(maxGlyph)}")
	return nbFixes

def fixAllWhiteSpaces(font):
	print("  Checking white space characters...")
	nbFixes = 0
	spaceGlyph = font.__getitem__(0x20)
	spaceGlyphWidth = spaceGlyph.width
	nbFixes += _setGlyphWidth(font, 0x00A0, spaceGlyphWidth, createIfMissing = True)
	nbFixes += _setGlyphWidth(font, 0x202F, spaceGlyphWidth * 2 / 3, createIfMissing = True)
	return nbFixes

#def fixAllJapanese(font):
#	print("  Checking Japanese full width characters...")
#	nbFixes = 0
#	rangesToLook = [(0x22EF, 0x22EF), (0x3001, 0x303F), (0x3040, 0x30ff), (0xff01, 0xff60), (0xffe0, 0xffe6)]
#	rangesToFix = rangesToLook + [(0x3000, 0x3000)]
#	nbFixes += _fixSameFixedWidth(font, rangesToLook, rangesToFix)
#	print("  Checking Japanese half width characters...")
#	rangesToFix = [(0xff61, 0xff9f)]
#	nbFixes += _fixSameFixedWidth(font, rangesToFix)
#	return nbFixes
#
#def fixAllKorean(font):
#	print("  Checking Korean full width characters...")
#	ranges = [(0xAC00, 0xD7A3), (0x3130, 0x318F)]
#	nbFixes = _fixSameFixedWidth(font, ranges)
#	return nbFixes

def fixAllCJK(font):
	print("  Checking CJK full width characters...")
	nbFixes = 0
	ranges = [(0x22EF, 0x22EF), (0x3001, 0x303F), (0x3040, 0x30ff), (0x3130, 0x318f), (0xac00, 0xd7a3), (0xff01, 0xff60), (0xffe0, 0xffe6)]
	nbFixes += _fixSameFixedWidth(font, ranges, 0x3000)
	print("  Checking Japanese half width characters...")
	ranges = [(0xff61, 0xff9f)]
	nbFixes += _fixSameFixedWidth(font, ranges)
	return nbFixes

def fixOneCharBearings(font, char, size):
	code = ord(char)
	if font.__contains__(code):
		glyph = font.__getitem__(code)
		if glyph.right_side_bearing != size * PIXEL_WIDTH:
			oldWidth = glyph.width
			glyph.right_side_bearing = size * PIXEL_WIDTH
			print(f"    Width of glyph {_charInfo(code)} changed: from {oldWidth // PIXEL_WIDTH} to {glyph.width // PIXEL_WIDTH}")
			return 1
	return 0

def fixBearings(font):
	print("  Checking a few letters that shouldn’t have extra bearing...")
	#allA = "aáàâäãåāǎăąíîïÍÎÏ"
	allA = "aáàâäãåāǎăąíîïĩǐĭīÍ"
	nbFixes = 0
	for a in allA:
		nbFixes += fixOneCharBearings(font, a, 0)
	return nbFixes
				
def fixVariousPunctuation(font):
	print("  Checking a few punctuation signs...")
	bearings = {"@": 2, "`": 2}
	nbFixes = 0
	for p in bearings:
		nbFixes += fixOneCharBearings(font, p, bearings[p])
	return nbFixes

def fixSaturnBearings(font):
	print("  Checking bearing for Saturn font...")
	bearing0 = "EÉÈÊËĒĔĚĖĘÆŒHĤĦJĴĲRŔŖŘXZŹŻŽЕЁНХ'’´`\"“”>「"
	bearing2 = "37<LĹĻĽĿȽŁ@ぁぃぅぇぉっゃゅょ゛ゝ"

	nbFixes = 0
	for c in bearing0:
		nbFixes += fixOneCharBearings(font, c, 0)
		nbFixes += fixOneCharBearings(font, c.lower(), 0)
	for c in bearing2:
		nbFixes += fixOneCharBearings(font, c, 2)
		nbFixes += fixOneCharBearings(font, c.lower(), 2)
	nbFixes += fixOneCharBearings(font, "？", 5)
	nbFixes += fixOneCharBearings(font, "！", 6)
	return nbFixes

def exportGlyphWidths(font):
	widthsObj = {}
	for i in range(10000000):
		if font.__contains__(i):
			glyph = font.__getitem__(i)
			widthsObj[chr(i)] = int(glyph.width / PIXEL_WIDTH)
	widthsFile = f"widths/{font.fontname}_widths.json"
	print(f"  Exported font widths to {widthsFile}")
	with open(widthsFile, "w") as widthsFile:
		json.dump(widthsObj, widthsFile, ensure_ascii=False, separators=[",", ":"], indent=4)


def fixFile(fontFile):
	try:
		font = FontWrapper.new(fontFile)
	except:
		print()
		return

	print(f"Analyzing font {font.fontname}...")

	nbFixes = 0
	nbFixes += fixAllWhiteSpaces(font)
	#nbFixes += fixAllJapanese(font)
	#nbFixes += fixAllKorean(font)
	if font.fontname != "SaturnBoing":
		nbFixes += fixAllCJK(font)
	
	if font.fontname == "EBMain":
		nbFixes += fixBearings(font)
		nbFixes += fixVariousPunctuation(font)
	
	if font.fontname == "SaturnBoing":
		nbFixes += fixSaturnBearings(font)

	exportGlyphWidths(font)

	if nbFixes > 0:
		tempFontFile = re.sub(r"\.ttf$", "", fontFile)
		while os.path.exists(tempFontFile + ".ttf"):
			tempFontFile += "-temp"
		
		tempFontFile += ".ttf"

		font.generate(tempFontFile)

		os.remove(fontFile)
		os.rename(tempFontFile, fontFile)

		print(f"In total, {nbFixes} glyphs fixed in {font.fontname}")
	else:
		print(f"{font.fontname} was perfect, nothing changed")
	print()

if len(sys.argv) < 2:
	print("Syntax: fix_font [font_files_to_fix]")
	exit()

for pattern in sys.argv[1:]:
	files = glob.glob(pattern)
	for i in glob.glob(pattern):
		fixFile(i)
