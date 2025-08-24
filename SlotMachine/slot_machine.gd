extends Node2D

# Слот-машина с последовательной остановкой барабанов
# Параметры для контроля шанса выигрыша
@export var win_chance_percent: float = 30.0  # Шанс выигрыша в процентах (0-100)
@export var force_win: bool = false  # Принудительный выигрыш для тестирования
@export var force_lose: bool = false  # Принудительный проигрыш для тестирования

@onready var slot_machine: Node2D = $"."

# Состояния слот-машины
enum MachineState {
	IDLE,      # Ожидание
	SPINNING,  # Крутится
	STOPPING,  # Останавливается по очереди
	WIN,       # Выигрыш
	LOSE       # Проигрыш
}

var current_state: MachineState = MachineState.IDLE

# Массив ассетов
var symbols: Array[Texture2D] = []
var spin_symbols: Array[Texture2D] = []

@export var reel_sprites: Array[NodePath] = [
	"Slots/Slot1/Sprite2D",
	"Slots/Slot2/Sprite2D",
	"Slots/Slot3/Sprite2D"
]

@export var spin_time: float = 2.0
@export var change_interval: float = 0.1
@export var stop_delay: float = 0.5  # Задержка между остановкой каждого слота

var _spinning := false
var _elapsed := 0.0
var _timer := 0.0
var _results := []
var _last_spin_symbols := []  # Отслеживаем последние показанные иконки для каждого барабана
var _stopped_slots := 0  # Количество уже остановленных слотов
var _stop_timer := 0.0  # Таймер для задержки между остановкой слотов

# Сигналы для внешнего управления
signal state_changed(new_state: MachineState)
signal spin_started()
signal spin_finished(result: bool)

func _ready():
	# Иконки для результатов и idle состояния
	symbols = [
		load("res://SlotMachine/Assets/1.png"),
		load("res://SlotMachine/Assets/2.png"),
		load("res://SlotMachine/Assets/3.png"),
		load("res://SlotMachine/Assets/4.png"),
		load("res://SlotMachine/Assets/5.png"),
	]
	
	# Иконки для анимации кручения
	spin_symbols = [
		load("res://SlotMachine/Assets/spin/1.png"),
		load("res://SlotMachine/Assets/spin/2.png"),
		load("res://SlotMachine/Assets/spin/3.png"),
		load("res://SlotMachine/Assets/spin/4.png"),
		load("res://SlotMachine/Assets/spin/5.png"),
		load("res://SlotMachine/Assets/spin/6.png"),
		load("res://SlotMachine/Assets/spin/7.png"),
		load("res://SlotMachine/Assets/spin/8.png"),
	]
	
	# Проверяем, что все иконки загружены
	for i in range(symbols.size()):
		if symbols[i] == null:
			print("_ready: ОШИБКА: иконка результата ", i, " не загружена!")
	
	for i in range(spin_symbols.size()):
		if spin_symbols[i] == null:
			print("_ready: ОШИБКА: иконка кручения ", i, " не загружена!")
	
	# Показываем первые символы (используем обычные символы для idle)
	for sprite_path in reel_sprites:
		var sprite = get_node(sprite_path)
		if sprite:
			sprite.texture = symbols[0]
		else:
			print("_ready: ОШИБКА: Спрайт не найден по пути ", sprite_path)
	
	# Инициализируем массив для отслеживания последних иконок кручения
	_last_spin_symbols.resize(reel_sprites.size())
	for i in range(reel_sprites.size()):
		_last_spin_symbols[i] = -1  # -1 означает, что иконка еще не была показана
	
	# Устанавливаем начальное состояние
	_set_state(MachineState.IDLE)
	
func _set_state(new_state: MachineState):
	current_state = new_state
	state_changed.emit(new_state)

func _determine_win_result() -> bool:
	# Принудительные результаты для тестирования
	if force_win:
		return true
	if force_lose:
		return false
	
	# Определяем результат на основе шанса
	var random_value = randf() * 100.0  # Случайное число от 0 до 100
	return random_value <= win_chance_percent

func start_spin():
	if _spinning:
		return
	
	var spin_sound = get_node("SpinSound")
	if spin_sound:
		spin_sound.play()
	_spinning = true
	_elapsed = 0.0
	_timer = 0.0
	_stopped_slots = 0
	_stop_timer = 0.0
	_results.clear()
	
	# Переходим в состояние кручения
	_set_state(MachineState.SPINNING)
	spin_started.emit()
	
	# Определяем результат заранее на основе шанса выигрыша
	var will_win = _determine_win_result()
	
	if will_win:
		# Выигрыш - все символы одинаковые
		var winning_symbol = randi() % symbols.size()
		for i in range(reel_sprites.size()):
			_results.append(winning_symbol)
	else:
		# Проигрыш - генерируем случайную комбинацию, но гарантируем, что хотя бы один символ отличается
		var attempts = 0
		var max_attempts = 10  # Максимальное количество попыток
		
		while attempts < max_attempts:
			_results.clear()
			
			# Генерируем случайную комбинацию
			for i in range(reel_sprites.size()):
				_results.append(randi() % symbols.size())
			
			# Проверяем, что не все символы одинаковые
			var first = _results[0]
			var all_same = true
			for idx in _results:
				if idx != first:
					all_same = false
					break
			
			# Если есть хотя бы один отличающийся символ, выходим из цикла
			if not all_same:
				break
			
			attempts += 1
		
		# Если все попытки исчерпаны, принудительно делаем второй символ другим
		if attempts >= max_attempts:
			_results[1] = (_results[0] + 1) % symbols.size()

func _process(delta):
	if not _spinning:
		return

	_elapsed += delta
	_timer += delta

	# Обновляем символы кручения в состояниях SPINNING и STOPPING
	if (current_state == MachineState.SPINNING or current_state == MachineState.STOPPING) and _timer >= change_interval:
		_timer = 0.0
		_update_symbols()

	# Когда время кручения истекло, начинаем последовательную остановку
	if _elapsed >= spin_time and current_state == MachineState.SPINNING:
		_set_state(MachineState.STOPPING)
		# Останавливаем первый слот сразу
		_stop_next_slot()
		_stop_timer = 0.0
	
	# В состоянии STOPPING продолжаем останавливать слоты с задержкой
	if current_state == MachineState.STOPPING:
		_stop_timer += delta
		
		# Останавливаем слоты по очереди с задержкой
		if _stop_timer >= stop_delay:
			_stop_timer = 0.0
			_stop_next_slot()
	
	# Если все слоты остановлены, показываем результат
	if current_state == MachineState.STOPPING and _stopped_slots >= reel_sprites.size():
		_spinning = false
		_show_result()

func _update_symbols():
	# Меняем каждый спрайт на новую иконку для анимации кручения
	# Эта функция должна вызываться в состояниях SPINNING и STOPPING
	if current_state != MachineState.SPINNING and current_state != MachineState.STOPPING:
		return
		
	
	for i in range(reel_sprites.size()):
		# Пропускаем уже остановленные слоты
		if i < _stopped_slots:
			continue
			
		var sprite = get_node(reel_sprites[i])
		if not sprite:
			continue
		
		# Выбираем новую иконку, отличную от предыдущей
		var new_symbol_index: int
		while true:
			new_symbol_index = randi() % spin_symbols.size()
			if new_symbol_index != _last_spin_symbols[i]:
				break
		
		# Обновляем спрайт и запоминаем новую иконку
		sprite.texture = spin_symbols[new_symbol_index]
		_last_spin_symbols[i] = new_symbol_index

func _stop_next_slot():
	# Останавливаем следующий слот
	if _stopped_slots < reel_sprites.size():
		var sprite = get_node(reel_sprites[_stopped_slots])
		sprite.texture = symbols[_results[_stopped_slots]]
		_stopped_slots += 1
		
		
		# Добавляем небольшой эффект при остановке слота
		_stop_effect()


func _stop_effect():
	var click_sound = get_node("ClickSound")
	if click_sound:
		click_sound.play()
	# Проигрываем анимацию дрожи для всей слот-машины при остановке слота
	_shake_entire_machine()

func _show_result():
	# Символы уже установлены в _stop_next_slot(), поэтому здесь только проверяем результат
	$SpinSound.stop()
	# Проверка выигрыша (если все одинаковые)
	var first = _results[0]
	var win = true
	for idx in _results:
		if idx != first:
			win = false
			break
	
	# Устанавливаем состояние на основе результата
	if win:
		_set_state(MachineState.WIN)
		# Проигрываем звук победы
		var win_sound = get_node("WinSound")
		if win_sound:
			win_sound.play()
	else:
		# Проигрываем звук поражения
		var lose_sound = get_node("LoseSound")
		if lose_sound:
			lose_sound.play()
		_set_state(MachineState.LOSE)

	# Эмитим сигнал о завершении спина
	spin_finished.emit(win)
	
	# Эффект дрожи для всей слот-машины как единое целое
	_shake_entire_machine()

func _shake_entire_machine():
	# Создаем tween для узла Slots
	var tween_slots = create_tween()
	
	var base_offset_y: float
	if current_state == MachineState.WIN:
		base_offset_y = 15
	else:
		base_offset_y = 10
	
	# рандомизация: +-20% по Y и небольшой разброс по X
	var offset = Vector2(
		randi_range(-3, 3),                          # случайный сдвиг по X
		base_offset_y + randf_range(-3.0, 3.0)       # чуть больше/меньше вниз
	)
	# Более интенсивная анимация для выигрыша
	if current_state == MachineState.WIN:
		shake_children(slot_machine, tween_slots, offset, 0.1)
	else:
		shake_children(slot_machine, tween_slots, offset, 0.1)

func shake_children(root: Node, tween: Tween, offset: Vector2, duration: float) -> void:

	var base: Vector2 = root.position

	# Создаём параллельную анимацию
	var branch = tween.parallel()

	branch.tween_property(root, "position", base + offset, duration/2)
	branch.tween_property(root, "position", base - offset, duration)
	branch.tween_property(root, "position", base, duration/2)

# Функция для сброса состояния (можно вызвать извне)
func reset_to_idle():
	_set_state(MachineState.IDLE)

# Публичные методы для внешнего управления
func get_current_state() -> MachineState:
	return current_state

func is_spinning() -> bool:
	return _spinning
