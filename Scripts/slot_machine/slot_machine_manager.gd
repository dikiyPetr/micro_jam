extends Node2D
class_name SlotMachineManager

# Константы для анимаций
const FALL_DISTANCE: float = 200.0
const FALL_DURATION: float = 0.8
const FADE_DURATION: float = 0.5
const BACKGROUND_FADE_DURATION: float = 0.8
const SPIN_DELAY: float = 1.0

# Цвета
const BACKGROUND_DARK_COLOR: Color = Color(0, 0, 0, 0.7)
const BACKGROUND_CLEAR_COLOR: Color = Color(0, 0, 0, 0)

# Система изменения статов
@export var stat_modifier: Resource

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

func start():
	# Определяем качество крутки на основе количества монет
	var coin_count = Global.gambleStat.coins
	_current_quality = stat_modifier.get_quality_from_coins(coin_count)
	
	# Выбираем случайный стат для изменения
	_current_stat_type = stat_modifier.get_random_stat_type()
	
	# Отладочная информация
	print("=== Начало крутки ===")
	print("Монет в копилке: ", coin_count)
	print("Качество крутки: ", stat_modifier.get_quality_name(_current_quality))
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
	var quality_name = stat_modifier.get_quality_name(_current_quality)
	var quality_color = stat_modifier.get_quality_color(_current_quality)
	
	stat_label.text = "Крутим: %s" % stat_name
	stat_label.modulate = quality_color
	stat_label.visible = true

func _hide_slot_machine():
	# Скрываем слот-машину и затенение
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация взлета слот-машины с ElasticEaseOut
	tween.tween_property(slot_machine, "position", original_position + Vector2(0, -FALL_DISTANCE), FALL_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	
	# Анимация исчезновения прозрачности (синхронизирована с взлетом)
	tween.tween_property(slot_machine, "modulate:a", 0.0, FALL_DURATION).set_ease(Tween.EASE_IN)
	
	# Анимация осветления фона
	tween.tween_property(background_overlay, "color", BACKGROUND_CLEAR_COLOR, BACKGROUND_FADE_DURATION)
	
	# Скрываем label с характеристикой
	stat_label.visible = false
	
	# Ждем завершения анимации перед скрытием CanvasLayer
	await tween.finished
	canvas_layer.visible = false

func _on_spin_started():
	# Паузим игру при начале спина
	get_tree().paused = true

func _on_spin_finished(result: bool):
	# Применяем изменение стата
	if stat_modifier:
		print("=== Применение изменения стата ===")
		print("Результат крутки: ", "Победа" if result else "Поражение")
		print("Тип стата: ", stat_modifier.get_stat_name(_current_stat_type))
		print("Качество: ", stat_modifier.get_quality_name(_current_quality))
		
		var stat_info = stat_modifier.apply_stat_change(
			Global.playerStat, 
			_current_stat_type, 
			_current_quality, 
			result
		)
		print("Стат изменен: ", stat_info)
		
		# Обновляем статы всех оружий в сцене
		_update_all_weapons()
		
		print("================================")
	
	# Сбрасываем количество монет в копилке
	var coins_before = Global.gambleStat.coins
	Global.gambleStat.coins = 0
	print("Копилка сброшена: было ", coins_before, " монет, стало 0")
	
	# Скрываем слот-машину через небольшую задержку
	await get_tree().create_timer(SPIN_DELAY).timeout
	_hide_slot_machine()

	# Возобновляем игру при завершении спина
	get_tree().paused = false

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
