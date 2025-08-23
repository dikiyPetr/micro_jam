extends Node
class_name Damagable
@export_group("damage")
@export var damage_amount: float = 1.0
@export var knockback_force: float = 10.0
@export var team: Teams.Values
@export var knockbackFrom: Node2D

var _damage_targets: Dictionary = {} 

func _process(delta: float) -> void:
	_do_hit()
	
func _do_hit() -> void:
	for health in _damage_targets.values():
		if health != null :
			var dmg := DamageInfo.new()
			dmg.amount = damage_amount
			dmg.team = team
			var target := (health as Health).get_parent()
			if target is Node2D:
				var dir := ((target as Node2D).global_position - knockbackFrom.global_position).normalized()
				dmg.knockback = dir * knockback_force
			(health as Health).apply_damage(dmg)

func _addDamageTarget(target: Node) -> void:
	var health := target.get_parent().get_node_or_null("Health")
	if health is Health:
		_damage_targets[target] = health

func _removeDamageTarget(target: Node) -> void:
	var health := target.get_parent().get_node_or_null("Health")
	if health is Health:
		_damage_targets.erase(target)

func _on_hitbox_area_entered(a: Area2D) -> void:
	_addDamageTarget(a)

func _on_hitbox_area_exited(a: Area2D) -> void:
	_removeDamageTarget(a)

func _on_hitbox_body_entered(a: Node2D) -> void:
	_addDamageTarget(a)

func _on_hitbox_body_exited(a: Node2D) -> void:
	_removeDamageTarget(a)
