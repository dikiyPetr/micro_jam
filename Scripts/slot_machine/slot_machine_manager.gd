extends Node2D
class_name SlotMachineManager

@onready var canvas_layer: CanvasLayer = $CanvasLayer

@onready var background_overlay: ColorRect = $CanvasLayer/BackgroundOverlay
@onready var slot_machine: Node2D = $CanvasLayer/SlotMachine


func _ready():
	# Скрываем весь CanvasLayer изначально
	canvas_layer.visible = false
	
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
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация затенения фона
	tween.tween_property(background_overlay, "color", Color(0, 0, 0, 0.7), 0.3)
	
	# Анимация появления слот-машины
	tween.tween_property(slot_machine, "modulate:a", 1.0, 0.3)

func _hide_slot_machine():
	# Скрываем слот-машину и затенение
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Анимация исчезновения слот-машины
	tween.tween_property(slot_machine, "modulate:a", 0.0, 0.3)
	
	# Анимация осветления фона
	tween.tween_property(background_overlay, "color", Color(0, 0, 0, 0), 0.3)
	
	# Скрываем CanvasLayer после анимации
	tween.tween_callback(func(): canvas_layer.visible = false)

func _on_spin_started():
	# Паузим игру при начале спина
	get_tree().paused = true

func _on_spin_finished(_result: bool):
	# Скрываем слот-машину через небольшую задержку
	await get_tree().create_timer(1.0).timeout
	_hide_slot_machine()

	# Возобновляем игру при завершении спина
	get_tree().paused = false
