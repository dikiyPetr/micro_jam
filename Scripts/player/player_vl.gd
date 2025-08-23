extends CharacterBody2D
class_name Player

@export_group("Movement")
@export var max_speed: float = 220.0
@export var acceleration: float = 1800.0
@export var friction: float = 2000.0
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.10

@export_group("damage")
@export var damage_amount: float = 1.0
@export var knockback_force: float = 120.0
@export var team: Teams.Values
@export var health: Health

var input_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	health.max_hp=Global.MaxPlayerHP
	health.hp=Global.PlayerHP
	pass

func _physics_process(delta: float) -> void:
	_read_input()

	var v := velocity
	if input_dir.length_squared() > 0.0001:
		var target := input_dir * max_speed
		v = v.move_toward(target, acceleration * delta)
	else:
		v = v.move_toward(Vector2.ZERO, friction * delta)

	velocity = v
	move_and_slide()

func _process(delta: float) -> void:
	if velocity.x > 0.1:
		$Sprite2D.flip_h = false
	elif velocity.x < -0.1:
		$Sprite2D.flip_h = true

func _read_input() -> void:
	# используем имена действий из твоего PlayerInput
	var move := Input.get_vector(
		PlayerInput.Left,
		PlayerInput.Right,
		PlayerInput.Up,
		PlayerInput.Down
	)
	if move.length() < deadzone:
		input_dir = Vector2.ZERO
	else:
		input_dir = move.normalized()
		
func _on_health_damaged(damage: Variant, hp: float, hp_prev: float) -> void:
	Global.PlayerHP=health.hp

func _on_health_died(damage: Variant) -> void:
	Global.PlayerHP=health.hp
	
func _on_health_healed(amount: float, hp: float) -> void:
	pass # Replace with function body.

func _on_health_invuln_ended() -> void:
	pass # Replace with function body.

func _on_health_invuln_started() -> void:
	pass # Replace with function body.

func _on_health_revived(hp: float) -> void:
	pass # Replace with function body.
