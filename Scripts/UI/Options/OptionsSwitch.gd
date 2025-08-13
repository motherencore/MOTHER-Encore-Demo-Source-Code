extends Control

export var highlighted = false setget _set_highlighted
export var text = "" setget _set_text

func _ready():
	global.connect("locale_changed", self, "_refresh")

func _on_visibility_changed():
	self.highlighted = false

func _set_highlighted(val):
	highlighted = val
	_refresh()

func _set_text(val):
	$Label.text = val
	text = val

func _refresh():
	if highlighted:
		if not $ArrowLMargin/ArrowL.playing:
			$ArrowLMargin/ArrowL.playing = true
			$ArrowLMargin/ArrowL.frame = 1
		if not $ArrowRMargin/ArrowR.playing:
			$ArrowRMargin/ArrowR.playing = true
			$ArrowRMargin/ArrowR.frame = 1
	else:
		$ArrowLMargin/ArrowL.playing = false
		$ArrowRMargin/ArrowR.playing = false
		$ArrowLMargin/ArrowL.frame = 0
		$ArrowRMargin/ArrowR.frame = 0

	if TranslationServer.get_locale() in ["ko", "ja"]:
		$ArrowLMargin/ArrowL.offset.y = 1
		$ArrowRMargin/ArrowR.offset.y = 1
	else:
		$ArrowLMargin/ArrowL.offset.y = 0
		$ArrowRMargin/ArrowR.offset.y = 0
