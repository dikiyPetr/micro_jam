extends CanvasLayer
class_name PauseMenu

@export var ContinueButton: Button
@export var RestartButton: Button

func _ready() -> void:
	# UI должен жить в паузе
	process_mode = Node.PROCESS_MODE_ALWAYS

	hide_menu()

	if ContinueButton:
		ContinueButton.pressed.connect(_on_continue_pressed)
	if RestartButton:
		RestartButton.pressed.connect(_on_restart_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# Тоггл по действию "pause" (добавь его в Input Map)
	if event.is_action_pressed("pause"):
		toggle_pause()

func _on_continue_pressed() -> void:
	_resume_game()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func toggle_pause() -> void:
	if get_tree().paused:
		_resume_game()
	else:
		_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	show_menu()

func _resume_game() -> void:
	get_tree().paused = false
	hide_menu()

func show_menu() -> void:
	visible = true
	if ContinueButton:
		ContinueButton.grab_focus()
	# по желанию: показать курсор
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_menu() -> void:
	visible = false
	# по желанию: спрятать курсор для игры без мыши
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
