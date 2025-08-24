extends Node
class_name GameManager
enum State { Playing, Pause, Gambling, GameOver}
var state:State = State.Playing

func set_gambling() -> void:
	get_tree().paused = true
	state=State.Gambling

func set_playing() -> void:
	get_tree().paused = false
	state=State.Playing

func set_pause() -> void:
	get_tree().paused = true
	state=State.Playing

func set_game_over() -> void:
	get_tree().paused = true
	state=State.GameOver
