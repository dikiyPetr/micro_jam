# TerrariumTarget.gd
class_name CreatureTarget
extends Area2D

@export var tags: Array[String] = ["food"]
@export var attraction: float = 1.0
@export var cooldown: float = 0.0

var _cooldown_left: float = 0.0

func can_be_targeted() -> bool:
	return _cooldown_left <= 0.0 and is_inside_tree()

func on_interacted(by: Node) -> void:
	_cooldown_left = cooldown
	# тут эффекты/анимации/звук/удаление и т.п.

func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left -= delta
