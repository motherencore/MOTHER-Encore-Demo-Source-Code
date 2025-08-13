import csv, os, re, sys

EXCLUDE_FROM_COUNTER = ["dialogue_Magicant", "dialogue_Magicant_descriptions", "dialogue_shitpost dialogue", "dialogue_Snowman", "dialogue_Testing"]

# Shared constants
FOLDER_TEXT = "text-{}/"
FOLDER_CSV = "../TranslatedText/"
SUFFIX_CSV = " - sheet.csv"
METADATA_REGEX = "NAME|SHORT|DESC|ART|DIALOG|ACT1_NAME|ACT1_TEXT|ACT1_FAIL|ACT2_NAME|ACT2_TEXT|ACT2_FAIL"
SUBSTITUTIONS = {
    'fr': {'·': " ", "•": " ", "’": "'", "!": "¦"}
}

# Shared method
def substitute(text, lang, reverse = False):
    substitDict = SUBSTITUTIONS[lang] if lang in SUBSTITUTIONS else {}
    text = text.replace("\n", "\\n")
    for s in substitDict:
        if not reverse:
            text = text.replace(s, substitDict[s])
        else:
            text = text.replace(substitDict[s], s)
    return text

# Shared method
def defineLanguages(langList):
    languages = {}
    for idx, lang in enumerate(langList):
        if idx == 0:
            languages[lang] = "O"
        else:
            languages[lang] = f"T{idx if len(langList) > 2 else ''}"
    return languages

# Shared method
def readClasses():
    classes = {}
    if os.path.isfile("articles.txt"):
        classFile = open(f"articles.txt", "r", encoding="utf-8")
        lines = classFile.readlines()
        for line in lines:
            if (reClass := re.match(r'^\s*(\w+)\s*=\s*(.+)$', line)):
                value = reClass.group(2).replace("\t", "")
                classes[reClass.group(1)] = eval(value)
    return classes

def registerCsv(csvName, csvDict):
    csvFullName = f"{FOLDER_CSV}{csvName}{SUFFIX_CSV}"

    # First, let’s read the current csv file and store its content into a structure
    with open(csvFullName, 'r', encoding="utf-8") as csvFile:
        csvReader = csv.reader(csvFile, delimiter = ',')

        existingCsvArray = {}
        for row in csvReader:
            existingCsvArray[row[0]] = row

    # Then, let’s insert everything from the txt into that same structure
    langRow = existingCsvArray["key"]
    for key in csvDict:
        for lang in csvDict[key]:
            langIdx = langRow.index(lang)
            existingCsvArray.setdefault(key, [key] + [""] * (len(langRow) - 1))[langIdx] = csvDict[key][lang]

    # After that, let’s save the edited structure into the csv file
    with open(csvFullName, 'w', encoding="utf-8") as csvFile:
        csvWriter = csv.writer(csvFile, delimiter = ',')
        csvWriter.writerows(existingCsvArray.values())

    # Finally, let’s remove the new line at the end of the file
    with open(csvFullName, 'r+', newline="") as csvFile:
        csvFile.seek(0, 2)
        csvFile.seek(csvFile.tell() - 2)
        last_char = csvFile.read() 
        if last_char == '\r\n':
            csvFile.truncate(csvFile.tell() - 2)


def parseTxt(txtName, languages, classes = {}):
    print(f"= Parsing {txtName}")

    folderText = FOLDER_TEXT.format('-'.join(languages.keys()))
    with open(f"{folderText}{txtName}.txt", 'r', encoding="utf-8") as scriptFile:
        lines = scriptFile.readlines()

    sourceLang = list(languages.keys())[0]

    # Variables to keep between iterations
    csvDict = {} # by csv key and language
    csvName = None
    segment = None
    textCounters = {} # by language, arrays of lineIds

    for line in lines:
        line = line.rstrip('\n')

        # File
        if reFile := re.match(r'^== (.+)$', line):
            if csvName != None:
                registerCsv(csvName, csvDict)
            csvName = reFile.group(1)
            print(f"Target CSV file: {csvName}{SUFFIX_CSV}")
            csvDict = {}

        # Segment
        elif reSegment := re.match(r'^= (.+)$', line):
            segment = reSegment.group(1)

        elif csvName != None and segment != None:
            # Handling different types of lines in the txt file
            if reMatch := re.match(r'spk_(.+)-([A-Z]\d{0,2}): (.*)', line): # Speaker
                lineId = "SPEAKER_" + reMatch.group(1)
                lineLang = reMatch.group(2)
                lineText = reMatch.group(3)
            elif reMatch := re.match(r'^(\d+)\.opt_(\d)-([A-Z]\d{0,2}): (.*)$', line): # Option
                lineId = reMatch.group(1) + f"-OPT_{reMatch.group(2)}"
                lineLang = reMatch.group(3)
                lineText = reMatch.group(4)
            elif reMatch := re.match(r'^(\d+)-([A-Z]\d{0,2}): (.*)$', line): # Dialogue
                lineId = reMatch.group(1)
                lineLang = reMatch.group(2)
                lineText = reMatch.group(3)
            elif reMatch := re.match(fr'^({METADATA_REGEX.lower()})-([A-Z]\d?): (.*)$', line): # Item/battler/skill metadata
                lineId = reMatch.group(1).upper()
                lineLang = reMatch.group(2)
                lineText = reMatch.group(3)
            else:
                if line != "" and not line.startswith("//"):
                    print(f"Error in “{txtName}”: Unknown syntax “{line}”")
                continue

            # Finding the language key
            for lang in languages:
                if languages[lang] == lineLang:
                    lineLang = lang

            # Building the CSV key
            csvKey = segment + (f"_{lineId}" if lineId != "" else "") 

            # Handling substitutions
            lineText = substitute(lineText, lineLang)

            # Handling classes
            if reMatch := re.match(r'\[class (\w+)\]', lineText):
                classId = reMatch.group(1)
                if classId in classes:
                    lineText = classes[classId]
                else:
                    print(f"Class not found: {classId}")

            # Counting translated lines
            if (lineText != "" # not empty
                and (lineLang == sourceLang or lineId in textCounters[sourceLang]) # English line not empty either
                and csvName not in EXCLUDE_FROM_COUNTER):
                if lineLang in textCounters:
                    textCounters[lineLang].append(lineId)
                else:
                    textCounters[lineLang] = [lineId]

            # Finally, adding the line to the dict
            csvDict.setdefault(csvKey, {})[lineLang] = lineText

        else:
            print(f"Error in “{txtName}”: No file or segment has been defined for “{line}”")

    registerCsv(csvName, csvDict)

    for idx, lang in enumerate(languages.keys()):
        if idx == 0:
            counterSource = len(textCounters[lang])
        else:
            counterLang = len(textCounters[lang])
            print(f"→ Translated fields for {txtName} in {lang}: {counterLang} / {counterSource} ({counterLang * 100 / counterSource:.2f} %)")
    print()

if len(sys.argv) < 3:
    print("Syntax: insert_to_csv source_language target_language_1 [target_language 2] [...]")
    exit()

languages = defineLanguages(sys.argv[1:])
classes = readClasses()
parseTxt("dialogue", languages)
parseTxt("battleskills", languages)
parseTxt("items", languages, classes)
parseTxt("battlers", languages, classes)