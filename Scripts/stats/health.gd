extends Node
class_name Health

signal damaged(damage, hp: float, hp_prev: float) # damage: DamageInfo
signal healed(amount: float, hp: float)
signal died(damage)                                # damage: DamageInfo
signal revived(hp: float)
signal invuln_started()
signal invuln_ended()

@export_group("HP")
@export var max_hp: float = 10.0:
	set(v):
		max_hp = max(1.0, v)
		hp = clamp(hp, 0.0, max_hp)
@export var hp: float = 10.0

@export_group("Team/FF")
@export var team: Teams.Values    # &"player", &"enemy", &"neutral" и т.д.

@export_group("Invulnerability")
@export var iframes_time: float = 0.0          # сек. неуязвимости после попадания
var _iframes_left: float = 0.0

@export_group("Death")
@export var auto_queue_free_on_death: bool = false  # если true — удалим владельца сами
@export var clamp_below_zero_to_zero: bool = true   # не уходить в отрицательные HP

# Доп: для нокбэка/станна — просто пробрасываем из DamageInfo сигналом (сам компонент не двигает тело)
# Никакой логики анимаций здесь нет — только подсчёт и события.

func _process(delta: float) -> void:
	if _iframes_left > 0.0:
		_iframes_left -= delta
		if _iframes_left <= 0.0:
			_iframes_left = 0.0
			invuln_ended.emit()

func is_alive() -> bool:
	return hp > 0.0

func revive(full: bool = true, new_hp: float = 0.0) -> void:
	if full:
		hp = max_hp
	else:
		hp = clamp(new_hp, 1.0, max_hp)
	revived.emit(hp)

func heal(amount: float) -> float:
	if amount <= 0.0 or not is_alive():
		return 0.0
	var prev := hp
	hp = clamp(hp + amount, 0.0, max_hp)
	var gained := hp - prev
	if gained > 0.0:
		healed.emit(gained, hp)
	return gained

func kill(damage: DamageInfo = null) -> void:
	if not is_alive():
		return
	var prev := hp
	hp = 0.0
	died.emit(damage)
	if auto_queue_free_on_death and owner:
		owner.queue_free()

func apply_damage(damage: DamageInfo) -> float:
	# 0) жив ли, есть ли неуязвимость
	if not is_alive():
		return 0.0
	if _iframes_left > 0.0 and not damage.ignore_iframes:
		return 0.0

	var final_dmg := damage.amount
	
	var prev := hp
	hp -= final_dmg
	if clamp_below_zero_to_zero and hp < 0.0:
		hp = 0.0

	# 4) события/iframes
	damaged.emit(damage, hp, prev)
	if iframes_time > 0.0 and not damage.ignore_iframes:
		_iframes_left = iframes_time
		invuln_started.emit()

	# 5) смерть?
	if hp <= 0.0:
		died.emit(damage)
		if auto_queue_free_on_death and owner:
			owner.queue_free()
	return final_dmg
