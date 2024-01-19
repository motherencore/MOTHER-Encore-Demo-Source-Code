extends TextureRect

var money : int = 0
var limit : int = 999_999

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_limit(value: int):
	limit = value
	if limit < 0: limit = 0
	if limit > 999_999: limit = 999_999
	
	update_numbers()

func set_money(value: int):
	money = value
	if money < 0: money = 0
	if money > limit: money = limit
	
	update_numbers()

func add_digit(value: int, digit: int):
	var digitMoney = int(money / float(pow(10, digit))) % 10
	
	digitMoney += value
	if digitMoney > 9:
		value = -9
	elif digitMoney < 0:
		value = 9
	add_money(value * int(pow(10, digit)), false)
	
	

func add_money(value: int, wrap := false):
	money += value
	if wrap:
		if money < 0: money = limit
		if money > limit: money = 0
	else:
		if money < 0: money = 0
		if money > limit: money = limit
	
	update_numbers()


func update_numbers():
	if limit > 99_999: $UINumber6.show()
	else: $UINumber6.hide()
	if limit > 9_999: $UINumber5.show()
	else: $UINumber5.hide()
	if limit > 999: $UINumber4.show()
	else: $UINumber4.hide()
	if limit > 99: $UINumber3.show()
	else: $UINumber3.hide()
	if limit > 9: $UINumber2.show()
	else: $UINumber2.hide()
	
	var money_string := str(money).pad_zeros(6)
	
	for i in range(money_string.length()):
		var UInum = get_child(i) as Sprite
		UInum.frame = int(money_string[i])
	
