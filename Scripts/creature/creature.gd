# CreaturePlatformer.gd
extends CharacterBody2D

## ---------- Параметры ----------
@export_category("Perception")
@export var view_radius: float = 160.0         # радиус круговой зоны VisionArea
@export var fov_angle_deg: float = 100.0       # конус зрения (по направлению взгляда)
@export var los_mask: int = 1                  # слои, которые БЛОКИРУЮТ видимость (стены)

@export_category("Movement")
@export var speed: float = 80.0
@export var acceleration: float = 600.0
@export var jump_impulse: float = 360.0        # скорость вверх (по модулю)
@export var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))
@export var stop_distance: float = 18.0        # горизонтальная дистанция для «взаимодействия»
@export var interact_vert_tol: float = 24.0    # вертикальная вилка для «на одном уровне»
@export var jump_cooldown: float = 0.30

@export_category("Probes")
@export var wall_probe_dist: float = 40.0      # дальность проверки стены
@export var ledge_lookahead_x: float = 40.0    # вперёд по X для проверки пропасти
@export var ledge_probe_down: float = 40.0     # вниз при проверке пропасти

@export_category("Interests (tags -> weight)")
var interest_weights := { "food": 1.0, "toy": 0.5 }

@export_category("Debug")
@export var debug_draw: bool = true

## ---------- Узлы ----------
@onready var rotated: Node2D = $RotatedContent
@onready var vision: Area2D = $RotatedContent/VisionArea
@onready var vision_shape: CollisionShape2D = $RotatedContent/VisionArea/CollisionShape2D
@onready var ground_rc: RayCast2D = $GroundCheck
@onready var wall_rc: RayCast2D = $WallCheck
@onready var ledge_rc: RayCast2D = $LedgeCheck

## ---------- Состояние ----------
var rng := RandomNumberGenerator.new()
var _nearby := {}                                # {Area2D: true}
var _target: CreatureTarget                     # текущая цель
var _facing_sign: int = 1                        # +1 вправо, -1 влево
var _wander_dir: float = 0.0                     # -1..+1
var _wander_timer: float = 0.0
var _jump_cd_left: float = 0.0

func _ready() -> void:
	rng.randomize()
	# радиус VisionArea
	var c := vision_shape.shape
	if c is CircleShape2D:
		(c as CircleShape2D).radius = view_radius
	# сигналы
	vision.area_entered.connect(_on_area_entered)
	vision.area_exited.connect(_on_area_exited)
func set_facing_from_dx(dx: float) -> void:
	if absf(dx) <= 2.0:
		return
	var s: int = 1 if dx > 0.0 else -1
	set_facing(s)

func set_facing(sign: int) -> void:
	var s: int = 1 if sign >= 0 else -1
	if s == _facing_sign:
		return
	_facing_sign = s
	_apply_orientation()
	
func _apply_orientation() -> void:
	# визуал (только RotatedContent)
	if is_instance_valid(rotated):
		var sx: float = 1.0 if _facing_sign >= 0 else -1.0
		if !is_equal_approx(rotated.scale.x, sx):
			rotated.scale.x = sx

	# направление лучей
	wall_rc.position  = Vector2(0.0, -4.0)   # грудь
	ledge_rc.position = Vector2(0.0, 8.0)    # у ступней
	ground_rc.position = Vector2(0.0, 8.0)

	wall_rc.target_position  = Vector2(wall_probe_dist * float(_facing_sign), 0.0)
	ledge_rc.target_position = Vector2(ledge_lookahead_x * float(_facing_sign), ledge_probe_down)
	ground_rc.target_position = Vector2(0.0, 16.0)

	# сразу обновим кэш лучей
	wall_rc.force_raycast_update()
	ledge_rc.force_raycast_update()
	ground_rc.force_raycast_update()

func _on_area_entered(a: Area2D) -> void:
	if a is CreatureTarget:
		_nearby[a] = true

func _on_area_exited(a: Area2D) -> void:
	if _nearby.has(a):
		_nearby.erase(a)
		if a == _target:
			_target = null

func _physics_process(delta: float) -> void:
	_jump_cd_left = maxf(0.0, _jump_cd_left - delta)

	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta

	# Выбор цели
	if _target == null or not _is_target_valid(_target):
		_target = _pick_best_target()

	# Определяем желаемое направление по X
	if _target:
		var dx: float = _target.global_position.x - global_position.x
		set_facing_from_dx(dx)


	# Движение к цели / блуждание
	if _target:
		_seek_target_x(_target, delta)
		_jump_logic(_target)
		_try_interact(_target)
	else:
		_wander(delta)

	move_and_slide()
	if debug_draw:
		queue_redraw()

## ---------- Выбор цели ----------
func _is_target_valid(t: CreatureTarget) -> bool:
	return is_instance_valid(t) \
		and t.can_be_targeted() \
		and _within_radius(t.global_position) \
		and _in_fov(t.global_position) \
		and _has_los(t.global_position)

func _within_radius(p: Vector2) -> bool:
	return global_position.distance_to(p) <= view_radius

func _in_fov(p: Vector2) -> bool:
	var to: Vector2 = p - global_position
	if to.is_zero_approx():
		return true
	var half: float = deg_to_rad(fov_angle_deg) * 0.5
	var forward: Vector2 = Vector2(_facing_sign, 0.0)
	var ang: float = forward.angle_to(to.normalized())
	var abs_ang: float = absf(ang)
	return abs_ang <= half

func _has_los(p: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var qp := PhysicsRayQueryParameters2D.create(global_position, p)
	qp.exclude = [self]
	qp.collision_mask = los_mask
	var hit := space.intersect_ray(qp)
	return hit.is_empty()

func _interest_for(t: CreatureTarget) -> float:
	var best: float = 0.0
	for tag in t.tags:
		if interest_weights.has(tag):
			best = maxf(best, float(interest_weights[tag]))
	return best * t.attraction

func _score_target(t: CreatureTarget) -> float:
	var to: Vector2 = t.global_position - global_position
	var dist: float = maxf(8.0, to.length())
	var facing_dot: float = Vector2(_facing_sign, 0.0).dot(to.normalized())
	var facing_bonus: float = clampf((facing_dot + 1.0) * 0.5, 0.0, 1.0) # 0..1
	return _interest_for(t) * (1.0 + facing_bonus) / dist

func _pick_best_target() -> CreatureTarget:
	var best: CreatureTarget = null
	var best_score: float = -INF
	for a in _nearby.keys():
		if not (a is CreatureTarget): continue
		var t := a as CreatureTarget
		if not _is_target_valid(t): continue
		var s: float = _score_target(t)
		if s > best_score:
			best_score = s
			best = t
	return best

## ---------- Движение и прыжки ----------
func _seek_target_x(t: CreatureTarget, delta: float) -> void:
	var dx: float = t.global_position.x - global_position.x
	var dir: float = 1.0 if (dx > 0.0) else -1.0
	var desired_vx: float = dir * speed
	velocity.x = lerpf(velocity.x, desired_vx, clampf(acceleration * delta / maxf(1.0, speed), 0.0, 1.0))

func _jump_logic(t: CreatureTarget) -> void:
	if not is_on_floor():
		return
	if _jump_cd_left > 0.0:
		return

	# 1) Стена перед носом — перепрыгнуть
	var wall_ahead: bool = wall_rc.is_colliding()

	# 2) Пропасть впереди — перепрыгнуть
	var gap_ahead: bool = not ledge_rc.is_colliding()

	# 3) Цель заметно выше — подпрыгнуть, чтобы «взять» высокий тайл/ступень
	var target_higher: bool = (t.global_position.y + interact_vert_tol) < global_position.y

	if wall_ahead or gap_ahead or target_higher:
		velocity.y = -jump_impulse
		_jump_cd_left = jump_cooldown

func _try_interact(t: CreatureTarget) -> void:
	var dx: float = absf(t.global_position.x - global_position.x)
	var dy: float = absf(t.global_position.y - global_position.y)
	if dx <= stop_distance and dy <= interact_vert_tol and _has_los(t.global_position):
		t.on_interacted(self)
		_target = null

func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = rng.randf_range(0.6, 1.2)
		_wander_dir = rng.randf_range(-1.0, 1.0)
		if absf(_wander_dir) < 0.25:
			_wander_dir = 1.0 if rng.randf() >= 0.5 else -1.0
		set_facing(1 if _wander_dir >= 0.0 else -1)
	
	var desired_vx: float = _wander_dir * (speed * 0.4)
	velocity.x = lerpf(velocity.x, desired_vx, clampf(acceleration * delta / maxf(1.0, speed), 0.0, 1.0))
	
	# защита от обрыва
	ledge_rc.force_raycast_update()
	if is_on_floor() and not ledge_rc.is_colliding():
		velocity.x = 0.0

func _draw() -> void:
	if not debug_draw:
		return
	# FOV
	var half: float = deg_to_rad(fov_angle_deg) * 0.5
	var forward: Vector2 = Vector2(_facing_sign, 0.0)
	var steps: int = 20
	var pts: PackedVector2Array = []
	pts.push_back(Vector2.ZERO)
	for i in range(steps + 1):
		var t: float = lerpf(-half, half, float(i) / float(steps))
		pts.push_back(forward.rotated(t) * view_radius)
	draw_colored_polygon(pts, Color(0.2, 0.9, 0.6, 0.10))
	# Пробники
	draw_line(Vector2.ZERO, wall_rc.target_position, Color(1,0,0,0.6), 2.0)
	draw_line(Vector2.ZERO, ledge_rc.target_position, Color(1,1,0,0.6), 2.0)
	draw_circle(Vector2.ZERO, 2.0, Color(1,1,1,0.8))
