extends Area2D
class_name Coin

@export var value: int = 1
@export var magnet_radius: float = 96.0     # притяжение к игроку (0, чтобы отключить)
@export var speed: float = 420.0            # скорость «магнита»
@export var lifetime: float = 15.0          # авто-деспавн (0 = беск.)

var _life: float
var _target: Node2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_life = lifetime
	_target = get_tree().get_first_node_in_group(Groups.Player) as Node2D

func _physics_process(delta: float) -> void:
	# Магнит (если в радиусе)
	if magnet_radius > 0.0 and is_instance_valid(_target):
		var to_p := _target.global_position - global_position
		if to_p.length_squared() <= magnet_radius * magnet_radius:
			global_position += to_p.normalized() * speed * delta

	# Таймер жизни
	if lifetime > 0.0:
		_life -= delta
		if _life <= 0.0:
			queue_free()

func _on_area_entered(a: Area2D) -> void:
	if not a.is_in_group(Groups.Collector):
		return
	#Wallet.add(value)
	queue_free()
