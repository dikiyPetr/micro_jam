class_name PlayerStat
extends Resource

# на эти параметры работают крутки
var _max_hp_value = 20
var maxHp: int:
	get:
		return _max_hp_value
	set(value):
		var old_max_hp = _max_hp_value
		_max_hp_value = value
		
		# Если max hp увеличился - полностью восстанавливаем здоровье
		if value > old_max_hp:
			_current_hp_value = value
		# Если max hp уменьшился - не восстанавливаем, но ограничиваем текущее hp новым максимумом
		elif value < old_max_hp:
			_current_hp_value = min(_current_hp_value, value)

var _current_hp_value = 20
var currentHp: int:
	get:
		return _current_hp_value
	set(value):
		_current_hp_value = value

# эти параметры можно добавиь в крутки
var maxSpeed: float = 220.0

var acceleration: float = 1800.0
var friction: float = 2000.0
