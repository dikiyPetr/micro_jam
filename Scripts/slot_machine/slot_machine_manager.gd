extends Node2D
class_name SlotMachineManager

const SlotMachineTriggerConfig = preload("res://Scripts/slot_machine/slot_machine_trigger_config.gd")

# Константы для анимаций
const FALL_DISTANCE: float = 200.0
const FALL_DURATION: float = 0.8
const FADE_DURATION: float = 0.1
const BACKGROUND_FADE_DURATION: float = 0.1
const SPIN_DELAY: float = 1.0

# Цвета
const BACKGROUND_DARK_COLOR: Color = Color(0, 0, 0, 0.7)
const BACKGROUND_CLEAR_COLOR: Color = Color(0, 0, 0, 0)

# Система изменения статов
@export var stat_modifier: Resource
# Конфигурация триггера слот-машины
@export var trigger_config: Resource

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var background_overlay: ColorRect = $CanvasLayer/BackgroundOverlay
@onready var slot_machine: Node2D = $CanvasLayer/Control/SlotMachine
@onready var stat_label: Label = $CanvasLayer/StatLabel

# Сохраняем оригинальную позицию слот машины
var original_position: Vector2

# Информация о текущей крутке
var _current_stat_type: int
var _current_quality: int

func _ready():
	# Скрываем весь CanvasLayer изначально
	canvas_layer.visible = false
	
	# Сохраняем оригинальную позицию
	original_position = slot_machine.position
	
	# Подключаем сигналы слот-машины для управления паузой
	slot_machine.spin_started.connect(_on_spin_started)
	slot_machine.spin_finished.connect(_on_spin_finished)
	
	# Подключаем сигнал изменения монет
	Global.gambleStat.coins_changed.connect(_on_coins_changed)

# Проверяем условия для запуска слот-машины
func check_trigger_conditions() -> bool:
	if not trigger_config:
		return false
	
	var config = trigger_config as SlotMachineTriggerConfig
	if not config:
		return false
	
	# Проверяем, достаточно ли монет
	if Global.gambleStat.coins >= config.coins_required:
		return true
	
	return false

# Обработчик изменения количества монет
func _on_coins_changed(new_amount: int, old_amount: int):
	# Проверяем условия запуска при изменении монет
	if check_trigger_conditions():
		# Отладочная информация о времени
		Global.gambleStat.debug_time_info()
		# Запускаем слот-машину
		start()

func start():
	# Определяем качество крутки на основе времени с последней крутки
	var current_time = Global.gambleStat.get_current_game_time()
	var time_elapsed = current_time - Global.gambleStat.lastDepTime
	var config = trigger_config as SlotMachineTriggerConfig
	_current_quality = config.get_quality_from_time(time_elapsed)
	
	# Выбираем случайный стат для изменения
	_current_stat_type = stat_modifier.get_random_stat_type()
	
	# Отладочная информация
	print("=== Начало крутки ===")
	print("Текущее время игры: ", current_time, " секунд")
	print("Время последней крутки: ", Global.gambleStat.lastDepTime, " секунд")
	print("Время с последней крутки: ", time_elapsed, " секунд")
	print("Качество крутки: ", config.get_quality_name(_current_quality))
	print("Стат для изменения: ", stat_modifier.get_stat_name(_current_stat_type))
	print("=====================")
	
	# Показываем слот-машину с анимацией
	_show_slot_machine()
	slot_machine.start_spin()

func _show_slot_machine():
	# Показываем CanvasLayer
	canvas_layer.visible = true
	
	# Устанавливаем начальную позицию для анимации падения (выше экрана)
	slot_machine.position = original_position + Vector2(0, -FALL_DISTANCE)
	slot_machine.modulate.a = 0.0
	
	# Обновляем текст характеристики
	_update_stat_label()
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация затенения фона
	tween.tween_property(background_overlay, "color", BACKGROUND_DARK_COLOR, BACKGROUND_FADE_DURATION)
	
	# Анимация падения слот-машины с BounceEaseIn
	tween.tween_property(slot_machine, "position", original_position, FALL_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	# Анимация появления прозрачности
	tween.tween_property(slot_machine, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_OUT)

func _update_stat_label():
	# Обновляем текст с названием характеристики
	var stat_name = stat_modifier.get_stat_name(_current_stat_type)
	var config = trigger_config as SlotMachineTriggerConfig
	var quality_name = config.get_quality_name(_current_quality)
	var quality_color = stat_modifier.get_quality_color(_current_quality)
	
	stat_label.text = "Крутим: %s" % stat_name
	stat_label.modulate = quality_color
	stat_label.visible = true

func _hide_slot_machine():
	$"../GameManager".set_playing()
	canvas_layer.visible = false

func _on_spin_started():
	$"../GameManager".set_gambling()
	

func _on_spin_finished(result: bool):
	# Применяем изменение стата
	if stat_modifier:
		print("=== Применение изменения стата ===")
		print("Результат крутки: ", "Победа" if result else "Поражение")
		print("Тип стата: ", stat_modifier.get_stat_name(_current_stat_type))
		var config = trigger_config as SlotMachineTriggerConfig
		print("Качество: ", config.get_quality_name(_current_quality))
		
		var stat_info = stat_modifier.apply_stat_change(
			Global.playerStat, 
			_current_stat_type, 
			_current_quality, 
			result
		)
		print("Стат изменен: ", stat_info)
		if stat_info.has("min_value"):
			print("Минимальное значение для этого стата: ", stat_info.min_value)
		
		# Обновляем статы всех оружий в сцене
		_update_all_weapons()
		
		print("================================")
	
	# Сбрасываем количество монет в копилке
	var coins_before = Global.gambleStat.coins
	Global.gambleStat.coins = 0
	
	# Обновляем время последней крутки
	var current_time = Global.gambleStat.get_current_game_time()
	Global.gambleStat.lastDepTime = current_time
	
	print("Копилка сброшена: было ", coins_before, " монет, стало 0")
	print("Время последней крутки обновлено: ", current_time, " секунд")
	
	# Скрываем слот-машину через небольшую задержку
	await get_tree().create_timer(SPIN_DELAY).timeout
	_hide_slot_machine()

# Обновить статы всех оружий в сцене
func _update_all_weapons() -> void:
	# Ищем все оружия в сцене
	var weapons = get_tree().get_nodes_in_group("weapon")
	for weapon in weapons:
		if weapon.has_method("update_stats"):
			weapon.update_stats()
	
	# Также ищем оружия по типу
	var all_weapons = get_tree().get_nodes_in_group("weapon")
	for weapon in all_weapons:
		if weapon.has_method("update_stats"):
			weapon.update_stats()
	
	# Обновляем CharacterStat для игрока (если используется)
	_update_player_character_stats()

# Обновить CharacterStat для игрока
func _update_player_character_stats() -> void:
	# Ищем игрока с PlayerController
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		(player as Player).update()
		if player.has_method("_get_Stat"):
			var char_stat = player._get_Stat()
			if char_stat and char_stat.has_method("update_from_player_stat"):
				char_stat.update_from_player_stat(Global.playerStat)
	
	# Также ищем по типу PlayerController
	var all_players = get_tree().get_nodes_in_group("player")
	for player in all_players:
		if player is PlayerController:
			var char_stat = player._get_Stat()
			if char_stat and char_stat.has_method("update_from_player_stat"):
				char_stat.update_from_player_stat(Global.playerStat)
