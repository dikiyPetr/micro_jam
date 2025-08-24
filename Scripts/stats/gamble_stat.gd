class_name GambleStat
extends Resource

signal coins_changed(new_amount: int, old_amount: int)
var coins_required := 20
var totalCoins = 0
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

# Время начала игры для правильного подсчета
var gameStartTime = 0.0

# Инициализация времени при создании ресурса
func _init():
	lastDepTime = 0
	totalWaveTime = 0
	gameStartTime = 0.0
func levelX(x: float):
	coins_required=10+10*x
# Получить текущее время игры в секундах
func get_current_game_time() -> float:
	if gameStartTime == 0.0:
		return 0.0
	return Time.get_unix_time_from_system() - gameStartTime

# Установить время начала игры
func set_game_start_time():
	gameStartTime = Time.get_unix_time_from_system()
