extends CanvasLayer
class_name WelcomeScreen

@export var RestartButton: Button

var _gameManager: GameManager

func _ready() -> void:
	if Global.welcomeShown:
		return
	visible=true
	# UI должен жить в паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gameManager = $"../GameManager"
	_gameManager.state=GameManager.State.Welcome
	get_tree().paused = true
	Global.welcomeShown=true
	if RestartButton:
		RestartButton.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	if _gameManager.set_playing():
		visible = false
