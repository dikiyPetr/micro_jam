extends Node2D
class_name Weapon

@export_group("Refs")
@export var projectile: PackedScene
@export var pool: Node                 # куда добавлять пули (обычно ProjectilePool)
@export var enemy: Teams.Values

@export_group("Fire params")
@export var range: float = 560.0                # поиск цели
@export var auto_fire: bool = true              # стрелять автоматически, когда есть цель
@export var fire_rate: float = 3.0              # выстрелов в секунду
@export var bullets_per_shot: int = 1           # сколько снарядов за выстрел
@export var spread_deg: float = 4.0             # разброс (± градусов)

var _cd: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func _physics_process(delta: float) -> void:
	_cd = max(0.0, _cd - delta)
	if not auto_fire:
		return

	var target := _find_nearest_enemy()
	if target == null :
		return
	print(target)
	if _cd <= 0.0:
		_fire_at(target)
		_cd = 1.0 / max(0.01, fire_rate)

# --- Основная стрельба ---
func _fire_at(target: Node2D) -> void:
	if projectile == null:
		return

	var base_dir := (target.global_position - global_position).normalized()
	var count : int = max(1, bullets_per_shot)
	for i in count:
		var dir := _apply_spread(base_dir, spread_deg)
		_spawn_projectile(dir)

# равномерный случайный поворот в диапазоне [-spread; +spread] (в градусах)
func _apply_spread(dir: Vector2, spread: float) -> Vector2:
	if spread <= 0.0:
		return dir
	var ang := deg_to_rad(_rng.randf_range(-spread, spread))
	return dir.rotated(ang)

func _spawn_projectile(dir: Vector2) -> void:
	var p := projectile.instantiate()
	pool.add_child(p)
	if p is Projectile:
		p.global_position = global_position
		p.setup(dir)

func _find_nearest_enemy() -> Node2D:
	var origin := global_position
	var best: Node2D
	var best_d2 := range * range
	for n in get_tree().get_nodes_in_group(Groups.Enemy):
		if not (n is Node2D):
			continue
		var d2 := ((n as Node2D).global_position - origin).length_squared()
		if d2 < best_d2:
			best_d2 = d2
			best = n
	return best
