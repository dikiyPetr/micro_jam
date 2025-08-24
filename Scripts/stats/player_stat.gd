class_name PlayerStat
extends Resource

signal health_changed(current_hp: int, max_hp: int)
signal max_health_changed(new_max_hp: int, old_max_hp: int)

# на эти параметры работают крутки
var _max_hp_value = 20
var maxHp: int:
	get:
		return _max_hp_value
	set(value):
		var old_max_hp = _max_hp_value
		_max_hp_value = value
		if old_max_hp != value:
			max_health_changed.emit(value, old_max_hp)
			health_changed.emit(_current_hp_value, _max_hp_value)

var _current_hp_value = 20
var currentHp: int:
	get:
		return _current_hp_value
	set(value):
		_current_hp_value = value
		health_changed.emit(_current_hp_value, _max_hp_value)

# эти параметры можно добавиь в крутки
var maxSpeed: float = 220.0

var acceleration: float = 1800.0
var friction: float = 2000.0
