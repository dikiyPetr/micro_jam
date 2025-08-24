extends Node
class_name GameManager
enum State { Playing, Pause, Gambling, GameOver}
var state:State = State.Playing

func _ready():
	# Инициализируем время начала игры
	Global.gambleStat.set_game_start_time()
	print("Время начала игры установлено")

func set_gambling() -> bool:
	get_tree().paused = true
	state=State.Gambling
	return true

func set_playing() -> bool:
	get_tree().paused = false
	state=State.Playing
	return true

func set_pause() -> bool:
	get_tree().paused = true
	state=State.Playing
	return true
	
func set_game_over() -> bool:
	get_tree().paused = true
	state=State.GameOver
	return true
