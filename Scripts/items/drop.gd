extends Node
class_name Drop
@export var coin: PackedScene 
var _rng := RandomNumberGenerator.new()
var _drop_stat: DropStat

func _ready() -> void:
	_drop_stat=Global.dropStat
	
func _spawn_coins() -> void:
	var n := _rng.randi_range(_drop_stat.coin_min, max(_drop_stat.coin_min, _drop_stat.coin_max))
	if n <= 0: return

	var parent := _get_coin_pool()
	for i in n:
		var c := coin.instantiate()
		if not (c is Node2D): continue
		parent.add_child(c)
		var pos := (get_parent() as Node2D).global_position
		if _drop_stat.scatter_radius > 0.0:
			var ang := _rng.randf() * TAU
			var r := sqrt(_rng.randf()) * _drop_stat.scatter_radius
			pos += Vector2.RIGHT.rotated(ang) * r
		(c as Node2D).global_position = pos
		
func _get_coin_pool() -> Node:
	return get_tree().current_scene.get_tree().get_first_node_in_group(Groups.Pool)


func _on_health_died(damage: Variant) -> void:
	_spawn_coins();
