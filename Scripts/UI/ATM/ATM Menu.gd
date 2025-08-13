extends Control

var withdraw := true
var digit_limit : int = 0
var selected_digit : int = 5
var actual_digit : int = 1

var mainTab_root_pos := Vector2.ZERO
var subTab_root_pos := Vector2.ZERO

var soundEffects = {
	"back": load("res://Audio/Sound effects/M3/menu_close.wav"),
	"cursor1": load("res://Audio/Sound effects/Cursor 1.mp3"),
	"switch_tab": load("res://Audio/Sound effects/M3/menu_open.wav"),
	"invalid": load("res://Audio/Sound effects/M3/bump.wav"),
	"cash": load("res://Audio/Sound effects/M3/register.wav"),
}

# Called when the node enters the scene tree for the first time.
func _ready():
	mainTab_root_pos = $TabMain.rect_position
	subTab_root_pos = $TabSub.rect_position
	$background/userAmount/ArrowL.playing = true
	$background/userAmount/ArrowR.playing = true
	$background/userAmount/ArrowU.playing = true
	$background/userAmount/ArrowD.playing = true
	setup()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var arrow_U = $background/userAmount/ArrowU
	var arrow_D = $background/userAmount/ArrowD
	var usrAmt = $background/userAmount
	
	if Input.is_action_just_pressed("ui_focus_prev"):
		Input.action_release("ui_focus_prev")
		_switch_tab()
	elif Input.is_action_just_pressed("ui_focus_next"):
		Input.action_release("ui_focus_next")
		_switch_tab()
	
	var direction = controlsManager.get_controls_vector(true)

	if direction.x < 0:
		move_digit(-1)
		play_sfx("cursor1")
	elif direction.x > 0:
		move_digit(1)
		play_sfx("cursor1")
	
	if direction.y < 0:
		usrAmt.add_digit(1, actual_digit)
		play_sfx("cursor1")
	elif direction.y > 0:
		usrAmt.add_digit(-1, actual_digit)
		play_sfx("cursor1")
	
	if Input.is_action_just_pressed("ui_accept"):
		Input.action_release("ui_accept")
		make_transfer()
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.action_release("ui_cancel")
		play_sfx("back")
		uiManager.close_current()

func _switch_tab():
	withdraw = !withdraw
	setup()
	play_sfx("switch_tab")

func make_transfer():
	if $background/userAmount.money <= 0:
		play_sfx("invalid")
		return
	if withdraw:
		globaldata.bank -= $background/userAmount.money
		globaldata.cash += $background/userAmount.money
	else:
		globaldata.bank += $background/userAmount.money
		globaldata.cash -= $background/userAmount.money
	play_sfx("cash") 
	setup()

func reset_digit():
	selected_digit = 5
	actual_digit = (selected_digit - 5) * -1
	visual_cursor_move()

func move_digit(dir: int):
	selected_digit += dir
	if selected_digit < digit_limit: selected_digit = 5
	if selected_digit > 5: selected_digit = digit_limit
	
	actual_digit = (selected_digit - 5) * -1
	visual_cursor_move()
	#print(actual_digit)

func visual_cursor_move():
	var arrow_U = $background/userAmount/ArrowU
	var arrow_D = $background/userAmount/ArrowD
	var tween := $CursorTween as Tween
	tween.stop_all()
	tween.interpolate_property(arrow_U, "position:x", arrow_U.position.x, 10 + (selected_digit * 8), 0.1, Tween.TRANS_EXPO)
	tween.interpolate_property(arrow_D, "position:x", arrow_D.position.x, 10 + (selected_digit * 8), 0.1, Tween.TRANS_EXPO)
	tween.start()

func switch_tab():
	var tween := $TabTween as Tween
	var arrow := $background/Arrow as TextureRect
	var main_tab := $TabMain as TextureRect
	var sub_tab := $TabSub as TextureRect
	tween.stop_all()
	if withdraw:
		tween.interpolate_property(arrow, "rect_rotation", 
		arrow.rect_rotation, 180.0, 0.1, Tween.TRANS_EXPO)
	else:
		tween.interpolate_property(arrow, "rect_rotation", 
		arrow.rect_rotation, 0.0, 0.1, Tween.TRANS_EXPO)
	tween.start()
	

func close():
	uiManager.dialogueBox.next_phrase()
	queue_free()

func setup():
	global.persistPlayer.pause()
	var limit_string : String
	$background/BankBalance.set_limit(globaldata.bank)
	$background/BankBalance.set_money(globaldata.bank)
	$background/WalletBalance.set_limit(globaldata.cash)
	$background/WalletBalance.set_money(globaldata.cash)
	if withdraw:
		$TabMain.rect_position = subTab_root_pos + Vector2(0,-2)
		$TabSub.rect_position = mainTab_root_pos + Vector2(0,+2)
		$TabMain.flip_h = true
		$TabSub.flip_h = false
		$Deposit/Sprite.modulate = Color("c8c8c8")
		$Withdraw/Sprite.modulate = Color.white
		#$background/Arrow.rect_rotation = 180
		
		# LOCALIZATION Use of csv key
		$background/Label2.text = "ATM_WITHDRAW"
		$background/userAmount.set_limit(globaldata.bank)
		limit_string = str(globaldata.bank)
	else:
		$TabMain.rect_position = mainTab_root_pos
		$TabSub.rect_position = subTab_root_pos
		$TabMain.flip_h = false
		$TabSub.flip_h = true
		$Withdraw/Sprite.modulate = Color("c8c8c8")
		$Deposit/Sprite.modulate = Color.white
		
		# LOCALIZATION Use of csv key
		$background/Label2.text = "ATM_DEPOSIT"
		#$background/Arrow.rect_rotation = 0
		$background/userAmount.set_limit(globaldata.cash)
		limit_string = str(globaldata.cash)
	$background/userAmount.set_money(0)
	digit_limit = (limit_string.length() - 6) * -1
	reset_digit()
	switch_tab()


func play_sfx(sfx):
	var stream = soundEffects[sfx]
	audioManager.play_sfx(stream, "cursor")
