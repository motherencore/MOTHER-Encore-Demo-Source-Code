extends Node

onready var intervalTimer = $IntervalTimer #the  interval between input repeats for when you hold down a direction 
onready var intervalSwitchTimer = $IntervalSwitchTimer #how much time it takes for it to switch between slow and quick interval

const SLOWTIME = 0.3
const FASTTIME = 0.1

func get_just_pressed_up() -> bool:
	if Input.is_action_just_pressed("ui_up") \
	or Input.is_action_just_pressed("ui_lstick_up") \
	or Input.is_action_just_pressed("ui_rstick_up"):
		return true
	else:
		return false

func get_just_pressed_down() -> bool:
	if Input.is_action_just_pressed("ui_down") \
	or Input.is_action_just_pressed("ui_lstick_down") \
	or Input.is_action_just_pressed("ui_rstick_down"):
		return true
	else:
		return false

func get_just_pressed_left() -> bool:
	if Input.is_action_just_pressed("ui_left") \
	or Input.is_action_just_pressed("ui_lstick_left") \
	or Input.is_action_just_pressed("ui_rstick_left"):
		return true
	else:
		return false

func get_just_pressed_right() -> bool:
	if Input.is_action_just_pressed("ui_right") \
	or Input.is_action_just_pressed("ui_lstick_right") \
	or Input.is_action_just_pressed("ui_rstick_right"):
		return true
	else:
		return false

func get_just_released_up() -> bool:
	if Input.is_action_just_released("ui_up") \
	or Input.is_action_just_released("ui_lstick_up") \
	or Input.is_action_just_released("ui_rstick_up"):
		return true
	else:
		return false

func get_just_released_down() -> bool:
	if Input.is_action_just_released("ui_down") \
	or Input.is_action_just_released("ui_lstick_down") \
	or Input.is_action_just_released("ui_rstick_down"):
		return true
	else:
		return false

func get_just_released_left() -> bool:
	if Input.is_action_just_released("ui_left") \
	or Input.is_action_just_released("ui_lstick_left") \
	or Input.is_action_just_released("ui_rstick_left"):
		return true
	else:
		return false

func get_just_released_right() -> bool:
	if Input.is_action_just_released("ui_right") \
	or Input.is_action_just_released("ui_lstick_right") \
	or Input.is_action_just_released("ui_rstick_right"):
		return true
	else:
		return false

#returns the directional input vector that has just been pressed
func get_just_pressed_input_vector() -> Vector2:
	var inputVector = Vector2.ZERO
	if get_just_pressed_up():
		inputVector.y -= 1
	if get_just_pressed_down():
		inputVector.y += 1
	if get_just_pressed_left():
		inputVector.x -= 1
	if get_just_pressed_right():
		inputVector.x += 1
	
	return inputVector

#returns the directional input vector that has just been released
func get_just_released_input_vector() -> Vector2:
	var inputVector = Vector2.ZERO
	if get_just_released_up():
		inputVector.y -= 1
	if get_just_released_down():
		inputVector.y += 1
	if get_just_released_left():
		inputVector.x -= 1
	if get_just_released_right():
		inputVector.x += 1
	
	return inputVector

func get_just_pressed_direction() -> bool:
	return (get_just_pressed_up() or get_just_pressed_down() or get_just_pressed_left() or get_just_pressed_right())

func get_just_released_direction() -> bool:
	return (get_just_released_up() or get_just_released_down() or get_just_released_left() or get_just_released_right())

func get_controls_vector(discontinued = false) -> Vector2: #use discontinued for menus
	var inputVector = Vector2.ZERO
	var justPressedVector = get_just_pressed_input_vector()
	var justReleased = get_just_released_direction()
	#return nothing or the input that has just been pressed if the interval has not been finished
	if intervalTimer.time_left != 0 and discontinued and justPressedVector == Vector2.ZERO and !justReleased:
		return inputVector
	
	#get the direction from all direction input types
	inputVector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	inputVector += Input.get_vector("ui_lstick_left", "ui_lstick_right", "ui_lstick_up", "ui_lstick_down")
	inputVector += Input.get_vector("ui_rstick_left", "ui_rstick_right", "ui_rstick_up", "ui_rstick_down")
	#reduce to unit vectors
	inputVector = get_vector_sign(inputVector)
	
	if discontinued:
		if justPressedVector != Vector2.ZERO or justReleased:
			inputVector = justPressedVector
			intervalTimer.wait_time = SLOWTIME
			intervalSwitchTimer.start()
			intervalTimer.start()
		if inputVector != Vector2.ZERO and intervalTimer.time_left == 0:
			intervalTimer.start()
	
	return inputVector

func get_vector_sign(vector2, threshold = 0) -> Vector2:
	var vector = Vector2.ZERO
	if abs(vector2.x) > threshold:
		vector.x = sign(round(vector2.x))
	if abs(vector2.y) > threshold:
		vector.y = sign(round(vector2.y))
	return vector

func consume_all_directions():
	for a in ["ui_up", "ui_down", "ui_left", "ui_right",\
	"ui key_up", "ui_key_down", "ui_key_left", "ui_key_right",\
	"ui_dpad_up", "ui_dpad_down", "ui_dpad_left", "ui_dpad_right",\
	"ui_lstick_up", "ui_lstick_down", "ui_lstick_left", "ui_lstick_right",\
	"ui_lstick_up", "ui_lstick_down", "ui_lstick_left", "ui_lstick_right"]:
		Input.action_release(a)
	get_tree().set_input_as_handled()

func _on_IntervalSwitchTimer_timeout():
	if get_controls_vector() != Vector2.ZERO:
		print("gotta go fast!")
		intervalTimer.wait_time = FASTTIME
