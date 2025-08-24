extends Area2D
class_name Projectile

@onready var damagable: Damagable = $Damagable
var _stat: WeaponStat
var _dir: Vector2 = Vector2.RIGHT
var _life: float
var _penetrateCount = 0
func _ready() -> void:
	_life = 1

func setup(direction: Vector2, stat: WeaponStat) -> void:
	_dir = direction.normalized()
	_stat = stat
	_life = stat.bulletLifetime
	damagable.damage_amount = stat.damage
	
	rotation = _dir.angle() + PI/2

func _physics_process(delta: float) -> void:
	global_position += _dir * _stat.bulletSpeed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func onHit(damage: float) -> void:
	if damage > 0:
		_penetrateCount = _penetrateCount + 1
		if _penetrateCount >= _stat.penetration:
			queue_free()
	pass
