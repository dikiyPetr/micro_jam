extends Node
class_name Drop
@export var coin: PackedScene 
var _rng := RandomNumberGenerator.new()
var _drop_stat: DropStat

func _ready() -> void:
	_drop_stat=Global.dropStat
	
func _spawn_coins() -> void:
	var parent := _get_coin_pool()
	var c := coin.instantiate()
	parent.add_child(c)
	var pos := (get_parent() as Node2D).global_position
	(c as Node2D).global_position = pos
		
func _get_coin_pool() -> Node:
	return get_tree().current_scene.get_tree().get_first_node_in_group(Groups.Pool)


func _on_health_died(damage: Variant) -> void:
	_spawn_coins();
