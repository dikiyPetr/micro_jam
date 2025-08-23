extends Node2D
class_name Weapon

@export_group("Refs")
@export var projectile: PackedScene
@export var pool: Node                 # куда добавлять пули (контейнер)
@export var enemy: Teams.Values

@export_group("Fire params")
@export var range: float = 560.0
@export var auto_fire: bool = true
@export var fire_rate: float = 3.0
@export var bullets_per_shot: int = 1
@export var spread_deg: float = 4.0

@export_group("Orbit visuals") # ⬅️ новое
@export var orbit_radius: float = 20.0          # радиус облёта вокруг игрока
@export var orbit_height_offset: float = 0.0 
@export var muzzle_offset: float = 10.0      # сдвиг по Y (если нужно поднять/опустить)
@export_range(0.0, 1.0, 0.01) var aim_smooth: float = 0.18
@export var flip_vertically_when_left: bool = true

@onready var sprite: Sprite2D = $Sprite2D

var _cd: float = 0.0
var _rng := RandomNumberGenerator.new()
var _aim_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	_rng.randomize()
	_update_sprite_aim(_aim_dir, true)

func _physics_process(delta: float) -> void:
	_cd = max(0.0, _cd - delta)
	if not auto_fire:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	var base_dir := (target.global_position - global_position).normalized()
	_aim_dir = base_dir
	_update_sprite_aim(_aim_dir, false)

	if _cd <= 0.0:
		_fire_at_with_base_dir(base_dir)
		_cd = 1.0 / max(0.01, fire_rate)

# --- Стрельба ---
func _fire_at_with_base_dir(base_dir: Vector2) -> void:
	if projectile == null:
		return
	_update_sprite_aim(base_dir, true)

	var count: int = max(1, bullets_per_shot)
	for i in count:
		var dir := _apply_spread(base_dir, spread_deg)
		_spawn_projectile(dir)

func _apply_spread(dir: Vector2, spread: float) -> Vector2:
	if spread <= 0.0:
		return dir
	var ang := deg_to_rad(_rng.randf_range(-spread, spread))
	return dir.rotated(ang)
	
func _spawn_projectile(dir: Vector2) -> void:
	var p := projectile.instantiate()
	_get_projectile_pool().add_child(p)
	if p is Projectile:
		# базовая орбита (оружие вокруг игрока)
		var spawn_pos := global_position + _dir_to_orbit_offset(dir)
		# смещаем чуть дальше вдоль направления (к дулу)
		spawn_pos += dir.normalized() * muzzle_offset

		p.global_position = spawn_pos
		p.setup(dir)

		
func _get_projectile_pool() -> Node:
	if pool != null:
		return pool
	return get_tree().current_scene.get_tree().get_first_node_in_group(Groups.Pool)
	
func _find_nearest_enemy() -> Node2D:
	var origin := global_position
	var best: Node2D
	var best_d2 := range * range
	for n in get_tree().get_nodes_in_group(Groups.Enemy):
		if not (n is Node2D): continue
		var d2 := ((n as Node2D).global_position - origin).length_squared()
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best

# --- ОРБИТА: позиция и поворот спрайта вокруг игрока ---
func _update_sprite_aim(dir: Vector2, instant: bool) -> void:
	if sprite == null or dir == Vector2.ZERO:
		return

	# Целевая позиция спрайта = точка на окружности вокруг игрока (+ опц. смещение по высоте)
	var desired_local_pos := _dir_to_orbit_offset(dir)  # локально относительно Weapon (который сидит на игроке)

	# Плавное приближение к целевой позиции
	if instant or aim_smooth <= 0.0:
		sprite.position = desired_local_pos
	else:
		sprite.position = sprite.position.lerp(desired_local_pos, aim_smooth)

	# Поворот носом по направлению стрельбы
	var target_angle := dir.angle()
	if instant or aim_smooth <= 0.0:
		sprite.rotation = target_angle
	else:
		sprite.rotation = lerp_angle(sprite.rotation, target_angle, aim_smooth)

	# Вертикальный флип для левой полусферы (чтобы не была «вверх ногами»)
	if flip_vertically_when_left:
		var ang := wrapf(target_angle, -PI, PI)
		sprite.flip_v = abs(ang) > PI * 0.5

# перевод направления в точку орбиты
func _dir_to_orbit_offset(dir: Vector2) -> Vector2:
	return dir.normalized() * orbit_radius + Vector2(0.0, orbit_height_offset)
