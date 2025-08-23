extends Area2D
class_name Projectile

@onready var damagable: Damagable = $Damagable
var _speed: float = 1
var _lifetime: float = 1
var _dir: Vector2 = Vector2.RIGHT
var _life: float

func _ready() -> void:
	_life = _lifetime

func setup(direction: Vector2, stat: WeaponStat) -> void:
	_dir = direction.normalized()
	_speed = stat.bulletSpeed
	_lifetime = stat.bulletLifetime
	damagable.damage_amount = stat.damage

func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()

func onHit(damage: float) -> void:
	pass
	#if damage > 0:
		#queue_free()
