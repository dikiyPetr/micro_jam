extends Area2D
class_name EnemySpawnArea

@export_group("Follow")
@export var target: Node

@export_group("Spawn")
@export var enemy: PackedScene           # задержка появления (макс)
@export var pool: Node   

@export_group("Radius ring")
@export var radius_min: float = 80.0               # спавним в кольце [min; max] вокруг области
@export var radius_max: float = 180.0 # потолок живых от этого спавнера

@export_group("Debug")
@export var debug_draw: bool = true

var _target: Node2D
var _tick_timer: Timer
var _rng := RandomNumberGenerator.new()
var _alive: Array[Node2D] = []                     # только спавнённые этим спавнером
var _active: bool = false
@onready var _shape: CollisionShape2D = $CollisionShape2D
var _stat: SpawnStat

func _ready() -> void:
	_rng.randomize()
	_stat=Global.spawnStat
	if radius_min > radius_max:
		var t := radius_min; radius_min = radius_max; radius_max = t

	# цель для слежения
	if target != null:
		_target = target
	if _target == null:
		_target = get_tree().get_first_node_in_group(Groups.Player) as Node2D

	# таймер тиков
	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.wait_time = max(0.05, _stat.spawn_every)
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_on_tick)
	set_is_active(_active)
	# реагируем на выход тел из области
	body_exited.connect(_on_body_exited)
	
	if _shape and _shape.shape is CircleShape2D:
		(_shape.shape as CircleShape2D).radius=radius_max+100
		
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
	if _alive.size() >= _stat.max_alive_from_this_spawner:
		return

	for i in _stat.per_tick:
		if _alive.size() >= _stat.max_alive_from_this_spawner:
			break
		var pos := _random_point_in_ring()
		_schedule_spawn_at(pos)

func _random_point_in_ring() -> Vector2:
	# равномерно по площади: r = sqrt(lerp(rmin^2, rmax^2, u))
	var r2_min := radius_min * radius_min
	var r2_max := radius_max * radius_max
	var r := sqrt(lerp(r2_min, r2_max, _rng.randf()))
	var ang := _rng.randf() * TAU
	return global_position + Vector2.RIGHT.rotated(ang) * r

func _schedule_spawn_at(world_pos: Vector2) -> void:
	var delay := _rng.randf_range(_stat.delay_min, _stat.delay_max)
	var t := get_tree().create_timer(delay, false)
	t.timeout.connect(func():
		_do_spawn(world_pos)
	)

func _do_spawn(world_pos: Vector2) -> void:
	_cleanup_dead()
	if enemy == null:
		return
	if _alive.size() >= _stat.max_alive_from_this_spawner:
		return

	var e := enemy.instantiate()
	if not (e is Node2D):
		return
	var en := e as Node2D
	pool.add_child(en)
	en.global_position = world_pos

	_alive.append(en)
	# когда узел исчезнет (смерть/деспавн/смена сцены) — чистим список
	en.tree_exited.connect(_cleanup_dead)

# Удаляем врагов, вышедших за границу области
func _on_body_exited(body: Node) -> void:
	if body is Enemy:
		body.queue_free()

func _cleanup_dead() -> void:
	_alive = _alive.filter(func(n): return is_instance_valid(n))

func _draw() -> void:
	if not debug_draw:
		return
	# кольцо спавна
	draw_arc(Vector2.ZERO, radius_min, 0.0, TAU, 64, Color(0,1,0,0.6), 2.0, true)
	draw_arc(Vector2.ZERO, radius_max, 0.0, TAU, 64, Color(0,1,0,0.35), 2.0, true)

func set_is_active(is_active: bool) -> void:
	_active = is_active
	if _tick_timer != null:
		if is_active: _tick_timer.start()
		else: _tick_timer.stop()
