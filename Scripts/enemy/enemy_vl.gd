extends CharacterBody2D
class_name Enemy

@export var target: Node2D                    # если пусто — возьмём из группы "player"

@export_group("Stability")
@export var max_dv_per_frame: float = 600.0
@export var overlap_damp: float = 0.6
@export var overlap_remainder_px: float = 1.5

@export_group("Spawn")
@export var play_spawn_anim: bool = true    
@export var spawn_anim_name: StringName = &"spawn"
@export var lock_movement_during_spawn: bool = true

@onready var damagable: Damagable = $Damagable
@onready var health: Health = $Health
@onready var _anim: AnimationPlayer = $AnimationPlayer
@onready var _hitbox: Area2D = $Hitbox
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _sprite: AnimatedSprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _drop: Drop = $Drop
var _player: Node2D
var _dir_to_player := Vector2.ZERO
var _stat: EnemyStat
var _spawning: bool = false

func _ready() -> void:
	if target != null:
		_player = target
	if _player == null:
		_player = get_tree().get_first_node_in_group(Groups.Player) as Node2D
	_sprite.play()
	_stat = Global.enemyStat
	health.max_hp = _stat.hp
	health.hp = _stat.hp
	damagable.damage_amount = _stat.damage
	# Активация/деактивация боевых зон через функцию:
	_set_combat_enabled(false)  # по умолчанию выключим — на случай мгновенного спавна

	# Стартовая анимация появления
	if play_spawn_anim and _anim and _anim.has_animation(spawn_anim_name):
		_spawning = true
		if lock_movement_during_spawn:
			set_physics_process(false)  # временно стопаем тики движения
		_anim.play(spawn_anim_name)
		# по окончании включим столкновения/движение
		_anim.animation_finished.connect(_on_anim_finished)
	else:
		# нет анимации — просто включаем боевые зоны сразу
		_set_combat_enabled(true)

func _on_anim_finished(name: StringName) -> void:
	if name != spawn_anim_name:
		return
	_spawning = false
	_set_combat_enabled(true)
	if lock_movement_during_spawn:
		set_physics_process(true)

func _set_combat_enabled(enabled: bool) -> void:
	# Hitbox/Hurtbox могут быть отключены через monitoring,
	# чтобы они не генерировали событий во время спавна
	_collision.disabled = !enabled
	if _hitbox:
		_hitbox.monitoring =  enabled
		_hitbox.monitorable = enabled
	if _hurtbox:
		_hurtbox.monitoring= enabled
		_hurtbox.monitorable = enabled
	if enabled:
		add_to_group(Groups.Enemy)
		_anim.play("idle")
		
func _physics_process(delta: float) -> void:
	# При спавне (если не стопали _physics_process) просто не двигаемся
	if _spawning and lock_movement_during_spawn:
		return

	# 1) Курс на игрока
	if is_instance_valid(_player):
		_dir_to_player = (_player.global_position - global_position).normalized()
	else:
		_dir_to_player = Vector2.ZERO

	# 2) Steering к цели с ограничением Δv/кадр
	var v := velocity
	var desired := _dir_to_player * _stat.max_speed
	var dv := desired - v
	var max_dv := max_dv_per_frame * delta
	if dv.length() > max_dv:
		dv = dv.normalized() * max_dv
	v += dv

	# запомним скорость до перемещения (для анализа столкновения)
	var pre_move_vel := v

	velocity = v
	move_and_slide()

	# 3) Демпф при глубокой коррекции
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
	queue_free()
	
func _flashOn() -> void:
	pass
func _flashOff() -> void:
	pass
