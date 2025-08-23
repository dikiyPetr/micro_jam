extends Resource
class_name DamageInfo

@export var amount: float = 1.0
@export var team: Teams.Values
@export var knockback: Vector2 = Vector2.ZERO
@export var hitstun: float = 0.0
@export var ignore_iframes: bool = false
