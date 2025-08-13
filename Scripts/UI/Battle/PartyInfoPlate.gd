extends TextureRect


class Digit:
	func _init(_sprite):
		sprite = _sprite
	
	var sprite: Sprite
	var num = 0
	
	func set(row, fr = 0):
		sprite.frame_coords.x = wrapi(fr, 0, TRANSITION_FRAMES)
		num = wrapi(row, 0, 10)
		sprite.frame_coords.y = num



const PP_LESS_BG = preload("res://Graphics/UI/Battle/PartyInfoPlate_NoPP.png")
const TRANSITION_FRAMES = 8 #  The transition frame between digits

var pName: String = "" setget _set_name
var maxHP := 999
var maxPP := 999

var HP := 999
var _dhp := 999
var _dhp_frame := 0 # always between 0 and TRANSITION_FRAMES - 1

onready var _huns_digit_hp = Digit.new($HP_H)
onready var _tens_digit_hp = Digit.new($HP_T)
onready var _ones_digit_hp = Digit.new($HP_O)

var PP := 999
var _dpp := 999
var _dpp_frame := 0 # same deal as _dhp

onready var _huns_digit_pp = Digit.new($PP_H)
onready var _tens_digit_pp = Digit.new($PP_T)
onready var _ones_digit_pp = Digit.new($PP_O)

var _process_hp := false
var _process_pp := false
var _hp_timer: float = 0
var _pp_timer: float = 0
var _hp_increasing := false
var _pp_increasing := false

var _frame_time = 1.0/30.0 #LOL Division by zero oops. #Engine.target_fps
var scroll_speed = 1.0

var user_fast_mode := false
var hp_color := Color.white setget _update_style

signal hp_scroll_done
signal pp_scroll_done


# Called when the node enters the scene tree for the first time.
func _ready():
	$Name.text = pName
	hide_max_num()
	connect("hp_scroll_done", self, "_hide_exclamation")

func _set_name(value):
	pName = value
	$Name.text = value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if _process_hp:
		_process_HP(delta)
	if _process_pp:
		_process_PP(delta)

func setHP(value: int, setNumbers := false):
	HP = int(clamp(value, 0, maxHP))
	if setNumbers:
		_dhp = value
		var ones = _dhp % 10
		var tens = int(_dhp / 10.0) % 10
		var huns = int(_dhp / 100.0) % 10 # to defeat, the _
		_ones_digit_hp.set(ones)
		_tens_digit_hp.set(tens)
		_huns_digit_hp.set(huns)
		
		if _huns_digit_hp.sprite.frame == 0:
			_huns_digit_hp.sprite.hide()
			if _tens_digit_hp.sprite.frame == 0:
				_tens_digit_hp.sprite.hide()
			else:
				_tens_digit_hp.sprite.show()
		else:
			_huns_digit_hp.sprite.show()
	else:
		# hp is increasing IF current HP is BIGGER than display!
		if HP == 0:
			$HPExclamation.show()
			$HPExclamation/AnimationPlayer.play("Shake")
		else:
			_hide_exclamation()
		_hp_increasing = HP > _dhp
		_process_hp = true
	#print(pName, "'s HP has been set to ", value, ". (setNumbers = ", setNumbers, ")")

func setPP(value: int, setNumbers := false):
	if maxPP == 0:
		$PP_O.hide()
		$PP_T.hide()
		$PP_H.hide()
		texture = PP_LESS_BG
	PP = int(clamp(value, 0, maxPP))
	if setNumbers:
		_dpp = value
		var ones = _dpp % 10
		var tens = int(_dpp / 10.0) % 10
		var huns = int(_dpp / 100.0) % 10 # to defeat, the _
		_ones_digit_pp.set(ones)
		_tens_digit_pp.set(tens)
		_huns_digit_pp.set(huns)
		
		if _huns_digit_pp.sprite.frame == 0:
			_huns_digit_pp.sprite.hide()
			if _tens_digit_pp.sprite.frame == 0:
				_tens_digit_pp.sprite.hide()
			else:
				_tens_digit_pp.sprite.show()
		else:
			_huns_digit_pp.sprite.show()
	else:
		_pp_increasing = PP > _dpp
		_process_pp = true
	#print(pName, "'s PP has been set to ", value, ". (setNumbers = ", setNumbers, ")")

func _process_HP(delta):
	_hp_timer += delta
	var modded_scroll_speed := _get_scroll_speed(_hp_increasing, false)
	
	# enough time has passed for at least a frame of scrolling
	if _hp_timer >= (_frame_time / modded_scroll_speed):
		var framesPassed = floor(_hp_timer / (_frame_time/modded_scroll_speed))
		_hp_timer -= framesPassed * (_frame_time/modded_scroll_speed)
		
		for i in framesPassed:
			# check to see if we are done!
			if _dhp_frame == 0 and HP == _dhp:
				_hp_timer = 0.0
				_process_hp = false
				$HPExclamation.hide()
				$HPExclamation/AnimationPlayer.stop()
				setHP(HP, true)
				emit_signal("hp_scroll_done")
				break
			
			# Update HP either up or down
			var increment = 0
			if _hp_increasing:
				increment = 1
			else:
				increment = -1
			
			# - first, increment/decrement the _dhp_frame. We keep in within 8 frames
			#   since it takes 8 frames to transition from like, 1 to 2
			_dhp_frame += increment
			_dhp_frame = wrapi(_dhp_frame, 0, TRANSITION_FRAMES)
			
			# if we hit first frame , we change the what the display HP represents
			# its kinda like the progress of your hp, from one digit to another
			if (_hp_increasing and _dhp_frame == 0) or \
			   (!_hp_increasing and _dhp_frame == 7):
				_dhp += increment
			
			# process frames for each digit slot!
			# - basically, if any digit is showing a "9", it means the next digit
			#   to the left should ALSO transition
			# - e.g. If we are going from _dhp 9 -> 10, 
			#   The ONES place will be on frame_coords.y == 9
			#   So the TENS place will also update!
			var ones = _dhp % 10
			var tens = int(_dhp / 10.0) % 10
			var huns = int(_dhp / 100.0) % 10 # to defeat, the _
			
			_ones_digit_hp.set(ones, _dhp_frame)
			if ones == 9 or (ones == 0 and _dhp_frame == 0):
				_tens_digit_hp.set(tens, _dhp_frame)
				if tens == 9 or (ones == 0 and _dhp_frame == 0):
					_huns_digit_hp.set(huns, _dhp_frame)
			
			if _huns_digit_hp.sprite.frame == 0:
				_huns_digit_hp.sprite.hide()
				if _tens_digit_hp.sprite.frame == 0:
					_tens_digit_hp.sprite.hide()
				else:
					_tens_digit_hp.sprite.show()
			else:
				_huns_digit_hp.sprite.show()


func _process_PP(delta):
	_pp_timer += delta
	var modded_scroll_speed := _get_scroll_speed(_pp_increasing, true)
	
	if _pp_timer >= (_frame_time / modded_scroll_speed):
		var framesPassed = floor(_pp_timer / (_frame_time/modded_scroll_speed))
		_pp_timer -= framesPassed * (_frame_time/modded_scroll_speed)
		
		for i in framesPassed:
			# check to see if we are done!
			if _dpp_frame == 0 and PP == _dpp:
				_pp_timer = 0.0
				_process_pp = false
				setPP(PP, true)
				emit_signal("pp_scroll_done")
				break
			
			#  *uncreatively copies HP code*
			var increment = 0
			if _pp_increasing:
				increment = 1
			else:
				increment = -1
			
			_dpp_frame += increment
			_dpp_frame = wrapi(_dpp_frame, 0, TRANSITION_FRAMES)
			
			if (_pp_increasing and _dpp_frame == 0) or \
			   (!_pp_increasing and _dpp_frame == 7):
				_dpp += increment
			
			var ones = _dpp % 10
			var tens = int(_dpp / 10.0) % 10
			var huns = int(_dpp / 100.0) % 10 # to defeat, the _
			
			_ones_digit_pp.set(ones, _dpp_frame)
			if ones == 9 or (ones == 0 and _dpp_frame == 0):
				_tens_digit_pp.set(tens, _dpp_frame)
				if tens == 9 or (ones == 0 and _dpp_frame == 0):
					_huns_digit_pp.set(huns, _dpp_frame)
			
			if _huns_digit_pp.sprite.frame == 0:
				_huns_digit_pp.sprite.hide()
				if _tens_digit_pp.sprite.frame == 0:
					_tens_digit_pp.sprite.hide()
				else:
					_tens_digit_pp.sprite.show()
			else:
				_huns_digit_pp.sprite.show()

func _update_style(color):
	$HP_H.modulate = color
	$HP_T.modulate = color
	$HP_O.modulate = color

func _get_scroll_speed(is_increasing: bool, is_pp: bool) -> float:
	var ret = scroll_speed
	if is_pp or is_increasing:
		ret = 1
	if user_fast_mode:
		ret *= 4
	return ret

func show_max_num():
	$BasicPlate/MaxHP.text = str(HP) + "/" + str(maxHP)
	$BasicPlate/MaxHP.show()
	if maxPP > 0:
		$BasicPlate/MaxPP.text = str(PP) + "/" + str(maxPP)
		$BasicPlate/MaxPP.show()
	$BasicPlate.show()
	$Highlight.rect_position = $BasicPlate.rect_position
	$Highlight.rect_size = $BasicPlate.rect_size

func hide_max_num():
	$BasicPlate.hide()
	$BasicPlate/MaxHP.hide()
	$BasicPlate/MaxPP.hide()
	$Highlight.rect_position = self.rect_position
	$Highlight.rect_size = self.rect_size

func stop_scrolling():
	#set to 1 if it stops at 0
	_dhp = get_current_HP()
	if _dhp == 0:
		_dhp = 1
	_process_hp = false
	$HPExclamation.hide()
	$HPExclamation/AnimationPlayer.stop()
	setHP(_dhp, true)
	emit_signal("hp_scroll_done")
	emit_signal("pp_scroll_done")
#	setPP(PP, true)

func _hide_exclamation():
	$HPExclamation.hide()
	$HPExclamation/AnimationPlayer.stop()

func quake(delay = 0, intensity = 1):
	var offset = 8 * intensity
	$Tween.reset_all()
#	# 6 shakes version
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y, rect_position.y + 8, 0.05, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y + 8, rect_position.y - 8, 0.1, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.05)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y - 8, rect_position.y + 4, 0.1, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.15)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y + 4, rect_position.y - 4, 0.1, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.25)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y - 4, rect_position.y + 1, 0.1, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.35)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y + 1, rect_position.y - 1, 0.1, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.45)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y - 1, rect_position.y, 0.2, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0.55)

#	# 4 shakes version
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y, rect_position.y + offset, 0.05, \
		Tween.TRANS_LINEAR, Tween.EASE_OUT, delay)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y + offset, rect_position.y - offset, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT, delay + 0.05)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y - offset/2, rect_position.y + offset/2, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT, delay + 0.15)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y + offset/2, rect_position.y - offset/2, 0.1, \
		Tween.TRANS_QUAD, Tween.EASE_OUT, delay + 0.25)
	$Tween.interpolate_property(self, "rect_position:y", \
		rect_position.y - offset/2, rect_position.y, 0.15, \
		Tween.TRANS_QUAD, Tween.EASE_OUT, delay + 0.35)
	$Tween.start()

#func bounce():
#	$Tween.reset_all()
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y, rect_position.y + 4, 0.05, \
#		Tween.TRANS_LINEAR, Tween.EASE_OUT, 0)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y + 4, rect_position.y - offset, 0.1, \
#		Tween.TRANS_QUAD, Tween.EASE_OUT, 0.05)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y - offset/2, rect_position.y + offset/2, 0.1, \
#		Tween.TRANS_QUAD, Tween.EASE_OUT, 0.15)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y + offset/2, rect_position.y - offset/2, 0.1, \
#		Tween.TRANS_QUAD, Tween.EASE_OUT, 0.25)
#	$Tween.interpolate_property(self, "rect_position:y", \
#		rect_position.y - offset/2, rect_position.y, 0.15, \
#		Tween.TRANS_QUAD, Tween.EASE_OUT, 0.35)
#	$Tween.start()

func select():
	$Highlight.show()

func deselect():
	$Highlight.hide()
	$Name.add_color_override("font_color", Color.black)

func get_current_HP():
	return _dhp + min(_dhp_frame, 1)

