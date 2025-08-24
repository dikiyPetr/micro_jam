extends Node2D

@onready var slot_machine: Node2D = $SlotMachine
@onready var spin_button: Button = $SpinButton
@onready var result_label: Label = $ResultLabel

func _ready():
	# Подключаем сигналы от слот-машины
	slot_machine.state_changed.connect(_on_slot_machine_state_changed)
	slot_machine.spin_started.connect(_on_slot_machine_spin_started)
	slot_machine.spin_finished.connect(_on_slot_machine_spin_finished)

func _on_spin_button_pressed():
	# Запускаем спин в слот-машине
	slot_machine.start_spin()

func _on_slot_machine_state_changed(new_state):
	# Обновляем текст в зависимости от состояния
	match new_state:
		slot_machine.MachineState.IDLE:
			result_label.text = "Нажмите кнопку для игры"
		slot_machine.MachineState.SPINNING:
			result_label.text = "Крутится..."
		slot_machine.MachineState.STOPPING:
			result_label.text = "Останавливается..."
		slot_machine.MachineState.WIN:
			result_label.text = "ПОБЕДА!"
		slot_machine.MachineState.LOSE:
			result_label.text = "Попробуйте еще раз"

func _on_slot_machine_spin_started():
	# Отключаем кнопку во время спина
	spin_button.disabled = true

func _on_slot_machine_spin_finished(result: bool):
	# Включаем кнопку обратно
	spin_button.disabled = false
	
	# Можно добавить дополнительную логику здесь
	if result:
		print("Выигрыш!")
	else:
		print("Проигрыш!")
