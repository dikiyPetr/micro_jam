extends Area2D
class_name Coin       # авто-деспавн (0 = беск.)

var sprite_frames: SpriteFrames
var _life: float
var _target: Node2D
var _stat: DropStat

func _ready() -> void:
	$Sprite2D.sprite_frames = sprite_frames
	$Sprite2D.play()
	_stat = Global.dropStat
	area_entered.connect(_on_area_entered)
	_life = _stat.lifetime
	_target = get_tree().get_first_node_in_group(Groups.Player) as Node2D

func _physics_process(delta: float) -> void:
	# Магнит (если в радиусе)
	if _stat.magnet_radius > 0.0 and is_instance_valid(_target):
		var to_p := _target.global_position - global_position
		if to_p.length_squared() <= _stat.magnet_radius * _stat.magnet_radius:
			global_position += to_p.normalized() * _stat.magnet_speed * delta

	# Таймер жизни
	if _stat.lifetime > 0.0:
		_life -= delta
		if _life <= 0.0:
			queue_free()

func _on_area_entered(a: Area2D) -> void:
	if not a.is_in_group(Groups.Collector):
		return
	Global.gambleStat.totalCoins = Global.gambleStat.totalCoins + _stat.coin_value
	Global.gambleStat.coins = Global.gambleStat.coins + _stat.coin_value
	queue_free()
