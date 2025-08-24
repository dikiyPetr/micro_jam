extends CharacterBody2D
class_name Player

@export_group("Movement")
@export_range(0.0, 1.0, 0.01) var deadzone: float = 0.10

@export_group("damage")
@export var team: Teams.Values
@export var health: Health

@onready var anim: AnimationPlayer = $AnimationPlayer
var input_dir: Vector2 = Vector2.ZERO
var _stat: PlayerStat

func _ready() -> void:
	health.max_hp=Global.playerStat.maxHp
	health.hp=Global.playerStat.currentHp
	_stat=Global.playerStat
	pass
	
func update() -> void:
	health.max_hp = Global.playerStat.maxHp
	health.hp = Global.playerStat.currentHp

func _physics_process(delta: float) -> void:
	_read_input()

	var v := velocity
	if input_dir.length_squared() > 0.0001:
		var target : Vector2 = input_dir * _stat.maxSpeed
		v = v.move_toward(target, _stat.acceleration * delta)
	else:
		v = v.move_toward(Vector2.ZERO, _stat.friction * delta)

	velocity = v
	move_and_slide()

func _process(delta: float) -> void:
	if velocity.x > 0.1:
		$Sprite2D.flip_h = true
	elif velocity.x < -0.1:
		$Sprite2D.flip_h = false

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
	Global.playerStat.currentHp = hp

func _on_health_died(damage: Variant) -> void:
	Global.playerStat.currentHp=health.hp
	if Global.playerStat.currentHp == 0:
		$"../GameManager".set_game_over();
		$"../DeathMenu".showMenu()
	
func _on_health_healed(amount: float, hp: float) -> void:
	pass # Replace with function body.

func _on_health_invuln_ended() -> void:
	pass # Replace with function body.

func _on_health_invuln_started() -> void:
	pass # Replace with function body.

func _on_health_revived(hp: float) -> void:
	pass # Replace with function body.

func _on_weapon_on_shot(dir: Vector2) -> void:
	var isShotLeft=dir.x<0
	if isShotLeft:
		anim.play("shot_left")
	else:
		anim.play("shot_right")
	pass # Replace with function body.
