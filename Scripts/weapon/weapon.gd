extends Node2D
class_name Weapon

@export_group("Refs")
@export var projectile: PackedScene
@export var pool: Node                 # куда добавлять пули (контейнер)
@export var enemy: Teams.Values

@export_group("Fire params")
@export var auto_fire: bool = true

@export_range(0.0, 1.0, 0.01) var aim_smooth: float = 0.18
@export var flip_vertically_when_left: bool = false
@export var sprite_forward: Vector2 = Vector2.UP  

signal onShot(dir: Vector2)

@onready var sprite: Sprite2D = $Sprite2D
var stat: WeaponStat

var _cd: float = 0.0
var _rng := RandomNumberGenerator.new()
var _aim_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	stat = Global.weaponStat;
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
		_cd = 1.0 / max(0.01, stat.fire_rate)

# --- Стрельба ---
func _fire_at_with_base_dir(base_dir: Vector2) -> void:
	if projectile == null:
		return
	_update_sprite_aim(base_dir, true)

	var count: int = max(1, stat.bullets_per_shot)
	for i in count:
		var dir := _apply_spread(base_dir, stat.spread_deg)
		onShot.emit(dir)
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
		spawn_pos += dir.normalized()

		p.global_position = spawn_pos
		p.setup(dir,stat)

		
func _get_projectile_pool() -> Node:
	if pool != null:
		return pool
	return get_tree().current_scene.get_tree().get_first_node_in_group(Groups.Pool)
	
func _find_nearest_enemy() -> Node2D:
	var origin := global_position
	var best: Node2D
	var best_d2 := stat.range * stat.range
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

	var desired_local_pos := _dir_to_orbit_offset(dir)

	if instant or aim_smooth <= 0.0:
		sprite.position = desired_local_pos
	else:
		sprite.position = sprite.position.lerp(desired_local_pos, aim_smooth)

	var target_angle := sprite_forward.angle_to(dir)

	if instant or aim_smooth <= 0.0:
		sprite.rotation = target_angle
	else:
		sprite.rotation = lerp_angle(sprite.rotation, target_angle, aim_smooth)

	if flip_vertically_when_left:
		sprite.flip_v = dir.x < 0.0

func _dir_to_orbit_offset(dir: Vector2) -> Vector2:
	return dir.normalized()
