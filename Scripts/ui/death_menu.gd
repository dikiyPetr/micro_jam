extends CanvasLayer
class_name DeathMenu

@export var RestartButton: Button

var _gameManager: GameManager

func _ready() -> void:
	# UI должен жить в паузе
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gameManager = $"../GameManager"
	
	if RestartButton:
		RestartButton.pressed.connect(_on_restart_pressed)

func showMenu() -> void:
	visible = true
	
func _on_restart_pressed() -> void:
	if _gameManager.set_playing():
		Global.reset()
		get_tree().reload_current_scene()
