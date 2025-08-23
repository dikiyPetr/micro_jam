extends CharacterBody2D
class_name Enemy

@export_group("Chase")
@export var max_speed: float = 160.0
@export var acceleration: float = 1400.0
@export var target: Node2D  # можно оставить пустым и искать по группе "player"

@export_group("Stability")
@export var max_dv_per_frame: float = 600.0   # максимум изменения скорости за кадр
@export var overlap_damp: float = 0.6         # на сколько гасим скорость при сильной коррекции
@export var overlap_remainder_px: float = 1.5 # считаем «заметной» коррекцию > N пикселей

@export_group("damage")
@export var health: Health

var _player: Node2D
var _dir_to_player := Vector2.ZERO

func _ready() -> void:
	if target != null:
		_player = target
	if _player == null:
		_player = get_tree().get_first_node_in_group(Groups.Player) as Node2D

func _physics_process(delta: float) -> void:
	# 1) Курс на игрока
	if is_instance_valid(_player):
		_dir_to_player = (_player.global_position - global_position).normalized()
	else:
		_dir_to_player = Vector2.ZERO

	# 2) Steering к цели с ограничением Δv/кадр
	var v := velocity
	var desired := _dir_to_player * max_speed
	var dv := desired - v
	var max_dv := max_dv_per_frame * delta
	if dv.length() > max_dv:
		dv = dv.normalized() * max_dv
	v += dv

	# запомним скорость до перемещения (для анализа столкновения)
	var pre_move_vel := v

	velocity = v
	move_and_slide()

	# 3) Если была «глубокая» коррекция проникновения — демпфим скорость
	_apply_overlap_damping(pre_move_vel)

func _apply_overlap_damping(pre_move_vel: Vector2) -> void:
	var count := get_slide_collision_count()
	if count == 0:
		return
	for i in range(count):
		var c := get_slide_collision(i)
		var normal := c.get_normal()
		var remainder_len := c.get_remainder().length()
		# Условие: до столкновения летели В нормаль (внутрь),
		# и движок сделал заметную коррекцию (большой remainder)
		if pre_move_vel.dot(normal) < 0.0 and remainder_len > overlap_remainder_px:
			velocity *= overlap_damp
			break

func _on_damaged(dmg: DamageInfo, hp: float, hp_prev: float) -> void:
	if dmg.knockback != Vector2.ZERO:
		velocity += dmg.knockback  # или накопите в отдельный канал knockback
	#if anim and anim.has_animation("hurt"):
	#	anim.play("hurt")

func _on_died(dmg: DamageInfo) -> void:
	set_physics_process(false)
	#if anim and anim.has_animation("death"):
	#	anim.play("death")
	#	await anim.animation_finished
	queue_free()
	
func _flashOn() -> void:
	pass
func _flashOff() -> void:
	pass
