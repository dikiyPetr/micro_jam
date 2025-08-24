class_name GambleStat
extends Resource

signal coins_changed(new_amount: int, old_amount: int)

var _coins_value = 0
var coins: int:
	get:
		return _coins_value
	set(value):
		var old_amount = _coins_value
		_coins_value = value
		if old_amount != value:
			coins_changed.emit(value, old_amount)

var totalWaveTime = 0
var lastDepTime = 0
