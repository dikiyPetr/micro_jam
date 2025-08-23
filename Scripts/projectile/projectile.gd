extends Area2D
class_name Projectile

@export var speed: float = 520.0
@export var lifetime: float = 2.0

var _dir: Vector2 = Vector2.RIGHT
var _life: float

func _ready() -> void:
	_life = lifetime

func setup(direction: Vector2) -> void:
	_dir = direction.normalized()

func _physics_process(delta: float) -> void:
	global_position += _dir * speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
