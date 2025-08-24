extends Area2D
class_name EnemySpawnArea

@export_group("Follow")
@export var target: Node

@export_group("Spawn")
@export var enemy: PackedScene
@export var pool: Node

@export_group("Radius ring")
@export var radius_min: float = 80.0
@export var radius_max: float = 180.0

@export_group("Debug")
@export var debug_draw: bool = true

var _target: Node2D
var _tick_timer: Timer
var _rng := RandomNumberGenerator.new()
var _alive: Array[Node2D] = []
var _active: bool = false
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _floorShape: CollisionShape2D = $"../../Floor/CollisionShape2D"
var _stat: SpawnStat
# тек. рабочие параметры (не мутируем Global.spawnStat)
var _per_tick_current: int
var _max_alive_current: int
var _delay_min_current: float
var _delay_max_current: float
var _spawn_every_current: float

var _horde_timer: Timer

func _ready() -> void:
	_rng.randomize()
	_stat = Global.spawnStat
	var size: Vector2i = get_viewport().get_visible_rect().size
	radius_max=size.x/2
	# текущие
	_per_tick_current   = _stat.per_tick
	_max_alive_current  = _stat.max_alive_from_this_spawner
	_delay_min_current  = _stat.delay_min
	_delay_max_current  = _stat.delay_max
	_spawn_every_current = _stat.spawn_every

	if radius_min > radius_max:
		var t := radius_min; radius_min = radius_max; radius_max = t

	if target != null:
		_target = target
	if _target == null:
		_target = get_tree().get_first_node_in_group(Groups.Player) as Node2D

	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = max(0.05, _spawn_every_current)
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_on_tick)

	_horde_timer = Timer.new()
	_horde_timer.one_shot = true
	add_child(_horde_timer)
	_horde_timer.timeout.connect(stop_horde)

	set_is_active(_active)

	body_exited.connect(_on_body_exited)

	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius = radius_max + 100.0

	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(_target):
		global_position = _target.global_position
	if debug_draw:
		queue_redraw()

func _on_tick() -> void:
	_cleanup_dead()
	if enemy == null:
		return
	if _alive.size() >= _max_alive_current:
		return

	for i in _per_tick_current:
		if _alive.size() >= _max_alive_current:
			break
		var pos := _random_point_in_ring()
		_schedule_spawn_at(pos)
@export var tries_per_spawn: int = 8
func _random_point_in_ring() -> Vector2:
	var r2_min := radius_min * radius_min
	var r2_max := radius_max * radius_max

	for i in tries_per_spawn:
		var r := sqrt(lerp(r2_min, r2_max, _rng.randf()))
		var ang := _rng.randf() * TAU
		var pos := global_position + Vector2.RIGHT.rotated(ang) * r
		if rect_contains_point(_floorShape , pos):
			return pos

	# если не нашли за N попыток — вернём ближайшую допустимую точку к арене
	return _clamp_to_bounds(global_position)
	
func _clamp_to_bounds(p: Vector2) -> Vector2:
	var shape: RectangleShape2D = _floorShape.shape
	return Vector2(
		clamp(p.x, shape.position.x, shape.position.x + shape.size.x),
		clamp(p.y, shape.position.y, shape.position.y + shape.size.y)
	)
		

func rect_contains_point(collision_shape: CollisionShape2D, point: Vector2) -> bool:
	if collision_shape.shape == null:
		return false
	if not (collision_shape.shape is RectangleShape2D):
		return false
	var rect: RectangleShape2D = collision_shape.shape
	var local_point: Vector2 = collision_shape.to_local(point)
	return abs(local_point.x) <= rect.extents.x and abs(local_point.y) <= rect.extents.y
	
func _schedule_spawn_at(world_pos: Vector2) -> void:
	var delay := _rng.randf_range(_delay_min_current, _delay_max_current)
	var t := get_tree().create_timer(delay, false)
	t.timeout.connect(func(): _do_spawn(world_pos))

func _do_spawn(world_pos: Vector2, ignoreSize:bool = false) -> void:
	_cleanup_dead()
	if enemy == null:
		return
	if not ignoreSize:
		if _alive.size() >= _max_alive_current:
			return
	var e := enemy.instantiate()
	if not (e is Node2D):
		return
	var en := e as Node2D
	pool.add_child(en)
	en.global_position = world_pos
	_alive.append(en)
	en.tree_exited.connect(_cleanup_dead)

func _on_body_exited(body: Node) -> void:
	if body is Enemy:
		body.queue_free()

func _cleanup_dead() -> void:
	_alive = _alive.filter(func(n): return is_instance_valid(n))

func _draw() -> void:
	if not debug_draw:
		return
	draw_arc(Vector2.ZERO, radius_min, 0.0, TAU, 64, Color(0,1,0,0.6), 2.0, true)
	draw_arc(Vector2.ZERO, radius_max, 0.0, TAU, 64, Color(0,1,0,0.35), 2.0, true)

func set_is_active(is_active: bool) -> void:
	_active = is_active
	if _tick_timer != null:
		if is_active: 
			_tick_timer.wait_time = max(0.05, _spawn_every_current)
			_tick_timer.start()
		else:
			_tick_timer.stop()

# ---------------------------
# ПУБЛИЧНЫЕ «СПАЙКИ» СЛОЖНОСТИ
# ---------------------------

## Разовая «волна» сразу/за короткое время
func spawn_burst(count: int, spread_time: float = 0, rmin: float = -1.0, rmax: float = -1.0, ignore_cap: bool = true) -> void:
	if enemy == null or count <= 0:
		return
	var inner :=  rmin if rmin > 0.0 else radius_min
	var outer := rmax if rmax > 0.0 else radius_max
	for i in count:
		if not ignore_cap and _alive.size() >= _max_alive_current:
			break
		var pos := _random_point_in_custom_ring(inner, outer)
		if spread_time <= 0.0:
			_do_spawn(pos,true)
		else:
			var d := _rng.randf_range(0.0, spread_time)
			var t := get_tree().create_timer(d, false)
			t.timeout.connect(func(): _do_spawn(pos,true))

func _random_point_in_custom_ring(rmin: float, rmax: float) -> Vector2:
	var r2_min := rmin * rmin
	var r2_max := rmax * rmax
	var r := sqrt(lerp(r2_min, r2_max, _rng.randf()))
	var ang := _rng.randf() * TAU
	return global_position + Vector2.RIGHT.rotated(ang) * r

## Временная «орда» — ускоряем штатный спавн и поднимаем лимиты
func start_horde(duration: float = 8.0, rate_mul: float = 2.0, per_tick_bonus: int = 2, max_alive_bonus: int = 15) -> void:
	# применяем бусты
	_per_tick_current  = max(1, _stat.per_tick + per_tick_bonus)
	_max_alive_current = max(1, _stat.max_alive_from_this_spawner + max_alive_bonus)

	_spawn_every_current = max(0.05, _stat.spawn_every / max(0.1, rate_mul))
	_tick_timer.wait_time = _spawn_every_current

	# можно чуть ускорить первые спавны
	_delay_min_current = max(0.0, _stat.delay_min * 0.5)
	_delay_max_current = max(_delay_min_current, _stat.delay_max * 0.8)

	# запуск таймера возврата
	_horde_timer.stop()
	_horde_timer.wait_time = max(0.1, duration)
	_horde_timer.start()

func stop_horde() -> void:
	_per_tick_current   = _stat.per_tick
	_max_alive_current  = _stat.max_alive_from_this_spawner
	_delay_min_current  = _stat.delay_min
	_delay_max_current  = _stat.delay_max
	_spawn_every_current = _stat.spawn_every

	_tick_timer.wait_time = _spawn_every_current
