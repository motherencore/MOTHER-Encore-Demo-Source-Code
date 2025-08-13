import csv, os, re, sys

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

def parseCsv(csvName, languages, classes = {}):
    ret = ""

    with open(FOLDER_CSV + csvName, 'r', encoding="utf-8") as csvFile:

        csvReader = csv.reader(csvFile, delimiter = ',')
        langRow = None

        curSegment = None

        for row in csvReader:
            if langRow == None: # if this is the first row (firstRow not yet defined)
                langRow = row
            else:
                key = row[0]

                if reMatch := re.match(r'^(.+)_SPEAKER_(.+)$', key): # Speaker
                    segment = reMatch.group(1)
                    id = "spk_" + reMatch.group(2)
                elif reMatch := re.match(r'^(.+)_(\d+)-OPT_(\d)$', key): # Option
                    segment = reMatch.group(1)
                    id = reMatch.group(2) + f".opt_{reMatch.group(3)}"
                elif reMatch := re.match(r'^(.+)_(\d+)$', key): # Dialogue
                    segment = reMatch.group(1)
                    id = reMatch.group(2)
                elif reMatch := re.match(fr'^([A-Z0-9\.]+)_({METADATA_REGEX})$', key): # Item/battler/skill metadata
                    segment = reMatch.group(1)
                    id = reMatch.group(2).lower()
                else:
                    print(f"Warning: Unidentified key “{key}” in {csvName}")
                    continue

                if curSegment != segment:
                    if curSegment != None:
                        ret += "\n"
                    curSegment = segment
                    ret += f"= {segment}\n"

                for lang in languages:
                    if lang not in langRow:
                        print(f"Fatal error: Language “{lang}” not in {csvName}!")
                        exit()
                    langColIdx = langRow.index(lang)
                    textContent = row[langColIdx]
                    for classId in classes: # Classes
                        if classes[classId] == textContent:
                            textContent = f"[class {classId}]"
                    textContent = substitute(textContent, lang, True)
                    ret += f"{id}-{languages[lang]}: {textContent}\n"

    return ret


def extract(textType, languages, classes = {}):
    ret = ""
    for fileName in sorted(os.listdir(FOLDER_CSV), key=str.casefold):
        if reFile := re.match(rf"^({textType}.*){SUFFIX_CSV}$", fileName):
            if ret != "":
                ret += "\n"
            csvFileId = reFile.group(1)
            ret += f"== {csvFileId}\n"
            ret += parseCsv(fileName, languages, classes)
    
    folderText = FOLDER_TEXT.format('-'.join(languages.keys()))
    if not os.path.exists(folderText):
        os.makedirs(folderText)
    with open(f"{folderText}{textType}.txt", 'w', encoding="utf-8") as textFile:
        textFile.write(ret)

if len(sys.argv) < 2:
    print("Syntax: extract_from_csv source_language target_language_1 [target_language 2] [...]")
    exit()

languages = defineLanguages(sys.argv[1:])
classes = readClasses()
extract("dialogue", languages)
extract("battleskills", languages)
extract("items", languages, classes)
extract("battlers", languages, classes)
