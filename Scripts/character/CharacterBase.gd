extends CharacterBody2D
class_name CharacterBase

# ---- Tuning ----
func _get_Animator() -> CharacterAnimation:
	return null
func _get_Stat() -> CharacterStat:
	return null
# ---- Timers (окна) ----
var _coyote_timer: SceneTreeTimer
var _jump_buffer_timer: SceneTreeTimer

# ---- State ----
var moveX: float = 0.0
var jumpHeld: bool = false
var jumpPressed: bool = false
var facing: int = 1

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# 1) Намерения (у наследников)
	collect_intents()

	# 2) Окна прыжка
	if is_on_floor():
		_coyote_timer = get_tree().create_timer(_get_Stat().CoyoteTime, true)

	if jumpPressed:
		_jump_buffer_timer = get_tree().create_timer(_get_Stat().JumpBufferTime, true)

	# 3) Физика
	apply_gravity(delta)
	handle_jump()
	handle_move(delta)
	handle_facing()
	move_and_slide()

	update_anim()

	jumpPressed = false

# ---- INTENTS ----
# Дочерние классы должны проставить moveX / jumpHeld / jumpPressed
func collect_intents() -> void:
	push_error("collect_intents() not implemented")

# ---- Physics helpers ----
func apply_gravity(dt: float) -> void:
	var v := velocity
	v.y += _get_Stat().Gravity * dt

	# variable jump: отпустили прыжок — усиливаем падение
	if v.y < 0.0 and not jumpHeld:
		v.y += _get_Stat().Gravity * (_get_Stat().LowJumpMultiplier - 1.0) * dt

	velocity = v

func _has_timer_active(t: SceneTreeTimer) -> bool:
	return t != null and t.time_left > 0.0

func handle_jump() -> void:
	var has_coyote := _has_timer_active(_coyote_timer)
	var has_buffer := _has_timer_active(_jump_buffer_timer)

	if has_buffer and (has_coyote or is_on_floor()):
		var v := velocity
		v.y = _get_Stat().JumpVelocity
		velocity = v

		_coyote_timer = null
		_jump_buffer_timer = null

func handle_move(dt: float) -> void:
	var intent := moveX
	var v := velocity
	var a := _get_Stat().Accel * (1.0 if is_on_floor() else _get_Stat().AirControl)
	var d := _get_Stat().Decel * (1.0 if is_on_floor() else _get_Stat().AirControl)

	if absf(intent) > 0.01:
		v.x = move_toward(v.x, intent * _get_Stat().MaxSpeed, a * dt)
	else:
		v.x = move_toward(v.x, 0.0, d * dt)

	velocity = v

func handle_facing() -> void:
	if absf(velocity.x) > 2.0:
		facing = 1 if velocity.x >= 0.0 else -1
		if _get_Animator():
			_get_Animator().set_facing(facing)

func update_anim() -> void:
	# реализуется в наследниках
	pass
