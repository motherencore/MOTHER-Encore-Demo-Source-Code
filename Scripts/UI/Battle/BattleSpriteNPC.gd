extends Control

signal apply_damage

enum JumpStep {STARTING, STARTED, TOP_APPROACHED, TOP_REACHED, TARGET_APPROACHED, TARGET_REACHED}
enum CurveType {LINEAR, SUBQUADRATIC, QUADRATIC, SUBCUBIC, CUBIC, QUARTIC}

# Generic constants for attacks
const ATTACK_SPEED := 300
const ATTACK_START_POS := Vector2(320, 100)
const ATTACK_ANIM = ["Jump", "JumpLoop"]
const ATTACK_BOUNCE_SPEED := 150
const ATTACK_BOUNCE_HORIZONTAL_DISTANCE := -80
const ATTACK_ANIM_AFTER_BOUNCE := ["Recoil", "RecoilLoop"]
const ATTACK_BOUNCE_HEIGHT := 35

# Constants for specific attacks [Attack1, Attack2] (Attack1 = dive, Attack2 = kick)
const ATTACKS_JUMP_HEIGHT := [30, 40]
const ATTACKS_JUMP_X_PEAK_RATIO := [0.25, 0.5]
const ATTACKS_TARGET_OFFSET := [Vector2(0, -10), Vector2(5, -20)]
const ATTACKS_TARGET_RELATIVE_OFFSET := [Vector2(0.5, 0), Vector2(1, 1)] # Relative to the size of the target
const ATTACKS_CALLBACKS := ["_on_attack_1_anim_step", "_on_attack_2_anim_step"]

# Special actions during attacks (used in callbacks)
const ATTACK_1_PEAK_DELAY := 0.15
const ATTACK_1_PEAK_DELAY_AFTER_ANIM := 0.143
const ATTACK_1_PEAK_ANIM := ["Attack1", "Attack1Loop"]
const ATTACK_1_PRE_DIVE_SLOW_DOWN_FACTOR = 0.90
const ATTACK_1_DIVE_SPEED_UP_FACTOR = 1.4
const ATTACK_1_DELAY_AFTER_HIT := 0.150
const ATTACK_2_HIT_ANIM := ["Attack2"]
const ATTACK_2_DELAY_BEFORE_MOVE_UP := 0.2
const ATTACK_2_KICK_MOVE_UP := Vector2(0, -8)
const ATTACK_2_DELAY_BEFORE_HIT := 0.3
const ATTACK_2_DELAY_BETWEEN_TWEENS := 0.643

# Generic constants for the protect action
const PROTECT_SPEED := 300
const PROTECT_START_OFFSET := Vector2(150, 70)
const PROTECT_ANIM := ["Jump", "JumpLoop"]
const PROTECT_JUMP_HEIGHT := 10
const PROTECT_BOUNCE_SPEED := 200
const PROTECT_BOUNCE_HORIZONTAL_DISTANCE := 60
const PROTECT_ANIM_AFTER_BOUNCE := ["Damaged", "DamagedLoop"]
const PROTECT_BOUNCE_HEIGHT := 15
const PROTECT_TARGET_OFFSET := Vector2(0, 20)
const PROTECT_TARGET_RELATIVE_OFFSET := Vector2(0, -1) # Relative to the size of the target
const PROTECT_CALLBACK := "_on_protect_anim_step"

# Special actions during protect (used in callbacks)
const PROTECT_HIT_ANIM := ["Hit"]
const PROTECT_DELAY_AFTER_HIT := 0.2

# The enemy attack is slightly delayed to give the time for the NPC to come in
# Should be shorter than the time it takes for the NPC to jump to his ally
const ENEMY_ATTACK_DELAY := 0.3

# Generic constants for all actions
const HIT_SHAKE_AMPLITUDE := 5
const HIT_SHAKE_PERIOD := 0.04
const MAX_TWEEN_DURATION := 100
const TWEEN_STEP_TOP_APPROACHED := 0.4
const TWEEN_STEP_TARGET_APPROACHED := 0.9

const JUMP_META := "JUMP_META"

const CURVE_TYPE_EXPONENTS := {
	CurveType.LINEAR: 1,
	CurveType.QUADRATIC: 2,
	CurveType.SUBCUBIC: 2.4,
	CurveType.CUBIC: 3,
	CurveType.QUARTIC: 4,
	CurveType.SUBQUADRATIC: 1.8,
}


# Generic parameters for a full sequence (jump + bounce)
class SeqParams:
	var jump_params: JumpParams
	var bounce_params: JumpParams
	var bounce_distance: int
	var callback: FuncRef

	func _init(jump_params: JumpParams, bounce_params: JumpParams, bounce_distance: int, callback: FuncRef = null):
		self.jump_params = jump_params
		self.bounce_params = bounce_params
		self.bounce_distance = bounce_distance
		self.callback = callback

# Parameters for one jump or bounce segment
class JumpParams:
	var speed: int
	var height: int
	var anim: Array
	var curve_type: int
	var x_peak_ratio: float

	func _init(speed: int, height: int, anim: Array, curve_type: int = CurveType.QUADRATIC, x_peak_ratio: float = 0.5):
		self.speed = speed
		self.height = height
		self.anim = anim
		self.curve_type = curve_type
		self.x_peak_ratio = x_peak_ratio

class TweenMetadata:
	var start_pos: Vector2
	var target_pos: Vector2
	var duration: float
	var height: int
	var curve_type: int
	var x_peak_ratio: float

	var speed_mod := 1.0
	var _latest_step := -1

	func _init(start_pos: Vector2, target_pos: Vector2, duration: float, height := 0, curve_type := CurveType.QUADRATIC, x_peak_ratio := 0.5):
		for step in JumpStep.keys():
			add_user_signal(step)
		self.start_pos = start_pos
		self.target_pos = target_pos
		self.duration = duration
		self.height = height
		self.curve_type = curve_type
		self.x_peak_ratio = x_peak_ratio
		
	func send_signal_once(sig: int):
		if _latest_step < sig:
			for i in range(_latest_step + 1, sig + 1):
				emit_signal(JumpStep.keys()[i])
			_latest_step = sig


export (NodePath) var _npc_sprite_path: NodePath
export (NodePath) onready var _anim_player = get_node(_anim_player) as AnimationPlayer if _anim_player else null
export (NodePath) onready var _jump_tween = get_node(_jump_tween) as Tween if _jump_tween else null
export (NodePath) onready var _fx_tween = get_node(_fx_tween) as Tween if _fx_tween else null

var _sprite: Sprite

func init_from_ov_sprite(sprite_node: Node):
	if _npc_sprite_path:
		_sprite = get_node(_npc_sprite_path)
		_sprite.position = sprite_node.position
	else:
		if _sprite != null:
			remove_child(_sprite)
			_sprite.queue_free()
		_sprite = sprite_node.duplicate()
		add_child(_sprite)

func _ready():
	if _npc_sprite_path:
		get_node(_npc_sprite_path).visible = false
	if _sprite:
		_sprite.show()

func get_position() -> Vector2:
	return rect_position + (rect_size / 2) + _sprite.position

func protect_ally(target: BattleParticipant):
	var start_pos := target.get_position() + PROTECT_START_OFFSET
	var target_pos := _get_target_pos(target, PROTECT_TARGET_OFFSET, PROTECT_TARGET_RELATIVE_OFFSET)
	var params := SeqParams.new(
		JumpParams.new(PROTECT_SPEED, PROTECT_JUMP_HEIGHT, PROTECT_ANIM),
		JumpParams.new(PROTECT_BOUNCE_SPEED, PROTECT_BOUNCE_HEIGHT, PROTECT_ANIM_AFTER_BOUNCE, CurveType.SUBCUBIC),
		PROTECT_BOUNCE_HORIZONTAL_DISTANCE,
		funcref(self, PROTECT_CALLBACK)
	)
	yield(_jump_and_bounce(start_pos, target_pos, params), "completed")

func attack_target(target: BattleParticipant):
	var choose_atk := randi() % 2
	var target_pos := _get_target_pos(target, ATTACKS_TARGET_OFFSET[choose_atk], ATTACKS_TARGET_RELATIVE_OFFSET[choose_atk])
	var callback := funcref(self, ATTACKS_CALLBACKS[choose_atk])
	var params := SeqParams.new(
		JumpParams.new(ATTACK_SPEED, ATTACKS_JUMP_HEIGHT[choose_atk], ATTACK_ANIM, CurveType.QUADRATIC, ATTACKS_JUMP_X_PEAK_RATIO[choose_atk]),
		JumpParams.new(ATTACK_BOUNCE_SPEED, ATTACK_BOUNCE_HEIGHT, ATTACK_ANIM_AFTER_BOUNCE, CurveType.SUBCUBIC),
		ATTACK_BOUNCE_HORIZONTAL_DISTANCE,
		callback
	)
	yield(_jump_and_bounce(ATTACK_START_POS, target_pos, params), "completed")

func _get_target_pos(target: BattleParticipant, offset: Vector2, relative_offset: Vector2) -> Vector2:
	return target.get_position() + offset + target.get_size() * relative_offset / 2

# Entire sequence of jump at an enemy/ally (target) and bounce back
func _jump_and_bounce(start_pos: Vector2, target_pos: Vector2, params: SeqParams):
	_sprite.z_index = 1
	_sprite.position = start_pos
	var in_progress = _do_jump_tween(start_pos, target_pos, params.jump_params, params.callback, false)
	yield(in_progress, "completed")
	var rebound_target_pos := _sprite.position + Vector2(params.bounce_distance * sign(_sprite.position.x - start_pos.x), 0)
	_do_jump_tween(_sprite.position, rebound_target_pos, params.bounce_params, params.callback, true)

# Just the jump or bounce segment
func _do_jump_tween(start_pos: Vector2, target_pos: Vector2, params: JumpParams, step_callback: FuncRef, is_bounce: bool):
	var duration := target_pos.distance_to(start_pos) / params.speed
	var tween_meta := TweenMetadata.new(start_pos, target_pos, duration, params.height, params.curve_type, params.x_peak_ratio)
	_jump_tween.remove_all()
	_jump_tween.set_meta(JUMP_META, tween_meta)
	_jump_tween.interpolate_method(self, "_tween_frame",
		0, MAX_TWEEN_DURATION, MAX_TWEEN_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT
	)
	tween_meta.call_deferred("send_signal_once", JumpStep.STARTING)
	for step in JumpStep.keys():
		yield(tween_meta, step)
		if step_callback and step_callback.is_valid():
			var in_progress = step_callback.call_func(JumpStep[step], tween_meta, !is_bounce)
			if in_progress:
				yield(in_progress, "completed")
		if JumpStep[step] == JumpStep.STARTING:
			_jump_tween.call_deferred("start")
		if JumpStep[step] == JumpStep.STARTED:
			_play_frame_anim(params.anim)
		if JumpStep[step] == JumpStep.TOP_REACHED:
			_sprite.z_index = 0
	
# This function is called by the tween to update the sprite position (only for a jump or bounce segment)
func _tween_frame(t: float):
	var tween_meta := _jump_tween.get_meta(JUMP_META) as TweenMetadata
	var start_pos := tween_meta.start_pos
	var target_pos := tween_meta.target_pos
	var progress := t * tween_meta.speed_mod / tween_meta.duration
	
	# Calculate the x position over time (linear or offset based on x_peak_ratio)
	var top_progress := tween_meta.x_peak_ratio
	var x: float
	if progress < 0.5:
		var local_t := progress * 2
		x = lerp(start_pos.x, lerp(start_pos.x, target_pos.x, top_progress), local_t)
	else:
		var local_t := (progress - 0.5) * 2
		x = lerp(lerp(start_pos.x, target_pos.x, top_progress), target_pos.x, local_t)

	# Calculate the y position over time (parabola or broken line)
	var y_linear: float = lerp(start_pos.y, target_pos.y, progress)
	var peak_y := min(start_pos.y, target_pos.y) - tween_meta.height - (start_pos.y + target_pos.y) / 2
	var arc_offset := 0.0
	var exponent: float = CURVE_TYPE_EXPONENTS.get(tween_meta.curve_type, 0)
	arc_offset = peak_y * (1.0 - pow(2 * abs(progress - 0.5), exponent))

	var y := y_linear + arc_offset

	var prev_pos := _sprite.position
	_sprite.position = Vector2(x, y)
	tween_meta.send_signal_once(JumpStep.STARTED)
	if progress >= TWEEN_STEP_TOP_APPROACHED:
		tween_meta.send_signal_once(JumpStep.TOP_APPROACHED)
	if progress >= 0.5:
		tween_meta.send_signal_once(JumpStep.TOP_REACHED)
	if progress >= TWEEN_STEP_TARGET_APPROACHED:
		tween_meta.send_signal_once(JumpStep.TARGET_APPROACHED)
	if progress >= 1:
		tween_meta.send_signal_once(JumpStep.TARGET_REACHED)

# Dive attack: When the NPC reaches the peak of the jump, he slows down, stops and start a diving animation
# The tween also changes to a linear trajectory
func _on_attack_1_anim_step(step: int, tween_meta: TweenMetadata, is_before_hit: bool):
	if is_before_hit:
		match step:
			JumpStep.TOP_APPROACHED:
				pass
				_jump_tween.connect("tween_step", self, "_on_tween_approaching_top")
			JumpStep.TOP_REACHED:
				_jump_tween.disconnect("tween_step", self, "_on_tween_approaching_top")
				_jump_tween.stop_all()
				yield(get_tree().create_timer(ATTACK_1_PEAK_DELAY - ATTACK_1_PEAK_DELAY_AFTER_ANIM), "timeout")
				_play_frame_anim(ATTACK_1_PEAK_ANIM)
				yield(get_tree().create_timer(ATTACK_1_PEAK_DELAY_AFTER_ANIM), "timeout")
				tween_meta.curve_type = CurveType.LINEAR
				_change_tween_speed(ATTACK_1_DIVE_SPEED_UP_FACTOR, true)
				_jump_tween.resume_all()
	else:
		match step:
			JumpStep.STARTING:
				yield(get_tree().create_timer(ATTACK_1_DELAY_AFTER_HIT), "timeout")

func _on_tween_approaching_top(object, key, elapsed, value):
	_change_tween_speed(ATTACK_1_PRE_DIVE_SLOW_DOWN_FACTOR)

# Kick attack: When the NPC reaches his target, he starts a kick animation and then slightly moves up
func _on_attack_2_anim_step(step: int, tween_meta: TweenMetadata, is_before_hit: bool):
	if is_before_hit:
		match step:
			JumpStep.TARGET_REACHED:
				_jump_tween.stop_all()
				_play_frame_anim(ATTACK_2_HIT_ANIM)
				yield(get_tree().create_timer(ATTACK_2_DELAY_BEFORE_MOVE_UP), "timeout")
				_fx_tween.interpolate_property(_sprite, "position", _sprite.position, _sprite.position + ATTACK_2_KICK_MOVE_UP, ATTACK_2_DELAY_BETWEEN_TWEENS - ATTACK_2_DELAY_BEFORE_MOVE_UP)
				_fx_tween.start()
				yield(get_tree().create_timer(ATTACK_2_DELAY_BEFORE_HIT - ATTACK_2_DELAY_BEFORE_MOVE_UP), "timeout")
	else:
		match step:
			JumpStep.STARTING:
				yield(get_tree().create_timer(ATTACK_2_DELAY_BETWEEN_TWEENS - ATTACK_2_DELAY_BEFORE_HIT), "timeout")

# Protect action: When the NPC reaches his target, he stops, plays his protect animation and then shakes before bouncing back
func _on_protect_anim_step(step: int, tween_meta: TweenMetadata, is_before_hit: bool):
	if is_before_hit:
		match step:
			JumpStep.TARGET_REACHED:
				_play_frame_anim(PROTECT_HIT_ANIM)
	else:
		match step:
			JumpStep.STARTING:
				yield(_shake(PROTECT_DELAY_AFTER_HIT), "completed")

func _change_tween_speed(speed_factor: float, reset: bool = false):
	var tween_meta := _jump_tween.get_meta(JUMP_META) as TweenMetadata
	if reset:
		_change_tween_speed(1 / tween_meta.speed_mod)
	tween_meta.speed_mod *= speed_factor
	_jump_tween.seek(_jump_tween.tell() / speed_factor)

func _shake(duration: float):
	var magnitude := HIT_SHAKE_AMPLITUDE
	var old_pos := _sprite.position
	var shake := max(magnitude, 1.0)
	duration = max(duration, 0.2)
	var shake_count := int(duration / HIT_SHAKE_PERIOD)
	for i in shake_count:
		if abs(shake) > 1:
			shake = shake * -1
			magnitude = magnitude * -1
		else:
			if shake < 0.5:
				shake = 1.0
			else:
				shake = 0.0
		var target_pos := old_pos + Vector2(shake, 0)
		_fx_tween.interpolate_property(_sprite, "position", _sprite.position, target_pos, HIT_SHAKE_PERIOD, Tween.TRANS_QUART, Tween.EASE_OUT)
		_fx_tween.start()
		yield(_fx_tween, "tween_all_completed")
		if abs(shake) > 1:
			shake -= magnitude / shake_count
	_sprite.position = old_pos

func _play_frame_anim(anim: Array):
	for i in anim.size():
		if i == 0:
			_anim_player.play(anim[i])
		else:
			_anim_player.queue(anim[i])
