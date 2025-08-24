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

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var background_overlay: ColorRect = $CanvasLayer/BackgroundOverlay
@onready var slot_machine: Node2D = $CanvasLayer/SlotMachine

# Сохраняем оригинальную позицию слот машины
var original_position: Vector2

func _ready():
	# Скрываем весь CanvasLayer изначально
	canvas_layer.visible = false
	
	# Сохраняем оригинальную позицию
	original_position = slot_machine.position
	
	# Подключаем сигналы слот-машины для управления паузой
	slot_machine.spin_started.connect(_on_spin_started)
	slot_machine.spin_finished.connect(_on_spin_finished)

func start():
	# Показываем слот-машину с анимацией
	_show_slot_machine()
	slot_machine.start_spin()

func _show_slot_machine():
	# Показываем CanvasLayer
	canvas_layer.visible = true
	
	# Устанавливаем начальную позицию для анимации падения (выше экрана)
	slot_machine.position = original_position + Vector2(0, -FALL_DISTANCE)
	slot_machine.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация затенения фона
	tween.tween_property(background_overlay, "color", BACKGROUND_DARK_COLOR, BACKGROUND_FADE_DURATION)
	
	# Анимация падения слот-машины с BounceEaseIn
	tween.tween_property(slot_machine, "position", original_position, FALL_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	
	# Анимация появления прозрачности
	tween.tween_property(slot_machine, "modulate:a", 1.0, FADE_DURATION)

func _hide_slot_machine():
	# Скрываем слот-машину и затенение
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация взлета слот-машины с ElasticEaseOut
	tween.tween_property(slot_machine, "position", original_position + Vector2(0, -FALL_DISTANCE), FALL_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_ELASTIC)
	
	# Анимация исчезновения прозрачности (синхронизирована с взлетом)
	tween.tween_property(slot_machine, "modulate:a", 0.0, FALL_DURATION)
	
	# Анимация осветления фона
	tween.tween_property(background_overlay, "color", BACKGROUND_CLEAR_COLOR, BACKGROUND_FADE_DURATION)
	
	# Ждем завершения анимации перед скрытием CanvasLayer
	await tween.finished
	canvas_layer.visible = false

func _on_spin_started():
	# Паузим игру при начале спина
	get_tree().paused = true

func _on_spin_finished(_result: bool):
	# Скрываем слот-машину через небольшую задержку
	await get_tree().create_timer(SPIN_DELAY).timeout
	_hide_slot_machine()

	# Возобновляем игру при завершении спина
	get_tree().paused = false
