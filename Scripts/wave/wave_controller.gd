extends Node
class_name WaveController

signal wave_started(index: int)
signal wave_ended(index: int)
signal break_started(index: int)       # индекс только что завершившейся волны
signal break_ended(next_index: int)    # индекс следующей волны после перерыва
signal tick(state: WaveController.State, time_left: float)  # раз в сек: состояние и оставшееся время

@export_group("Timing")
@export var start_delay: float = 0.0           # задержка перед самой первой волной   # длительность перерыва
@export var auto_start: bool = true
@export var tick_interval: float = 1.0         # частота сигнала tick (0 = выключить)

@export_group("Waves")       
@export var difficulty_step: float = 1.0   

enum State { IDLE, PREP, WAVE, BREAK }
var _state: State = State.IDLE
var _wave_index: int = 0                       # начинается с 1 у первой волны
var _time_left: float = 0.0

var _timer: Timer
var _ticker: Timer
var _stat: WaveStat

func _ready() -> void:
	_stat = Global.waveStat
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

	_ticker = Timer.new()
	_ticker.one_shot = false
	add_child(_ticker)
	if tick_interval > 0:
		_ticker.wait_time = tick_interval
		_ticker.timeout.connect(_on_ticker)
		_ticker.start()

	if auto_start:
		start()

# --- публичные методы ---
func start() -> void:
	if _state != State.IDLE:
		return
	if start_delay > 0.0:
		_set_state(State.PREP, start_delay)
	else:
		_begin_wave()

func stop() -> void:
	_timer.stop()
	_ticker.stop()
	_set_state(State.IDLE, 0.0)

func skip_to_break() -> void:
	if _state != State.WAVE: return
	_end_wave()

func skip_break() -> void:
	if _state != State.BREAK: return
	_end_break()

func get_time_left() -> float:
	return _time_left

func get_wave_index() -> int:
	return _wave_index

# --- внутренняя логика ---
func _on_timer_timeout() -> void:
	match _state:
		State.PREP:
			_begin_wave()
		State.WAVE:
			_end_wave()
		State.BREAK:
			_end_break()

func _on_ticker() -> void:
	if _time_left > 0.0 and _state != State.IDLE:
		_time_left = max(0.0, _time_left - _ticker.wait_time)
	tick.emit(_state, _time_left)
	Global.waveStat.timeLeft = _time_left
	if _state == State.WAVE:
		Global.gambleStat.totalWaveTime = Global.gambleStat.totalWaveTime+1

func _set_state(s: State, duration: float) -> void:
	_state = s
	_time_left = duration
	if duration > 0.0:
		_timer.wait_time = duration
		_timer.start()
	else:
		_timer.stop()
func onChangeWaveIndex(index: int) -> void:
	if index == 1:
		pass
	elif index == 2:
		Global.level2()
	elif index == 3:
		Global.level3()
	elif index == 4:
		Global.level4()
	else:
		Global.levelX(index)
		
func _begin_wave() -> void:
	_wave_index += 1
	onChangeWaveIndex(_wave_index)
	# включаем спавнеры
	_set_spawners_active(true)

	_set_state(State.WAVE, max(0.1, _stat.wave_duration))
	wave_started.emit(_wave_index)

func _end_wave() -> void:
	# выключаем спавнеры и оповещаем
	_set_spawners_active(false)
	_start_slot_machine()
	wave_ended.emit(_wave_index)

	if _stat.break_duration > 0.0:
		_set_state(State.BREAK, _stat.break_duration)
		break_started.emit(_wave_index)
	else:
		# сразу следующая волна
		_begin_wave()

func _end_break() -> void:
	break_ended.emit(_wave_index + 1)
	_begin_wave()

func _set_spawners_active(active: bool) -> void:
	# По группе "spawners" пытаемся вызвать любой из методов, если он есть:
	#   set_active(bool)   или   set_spawning_enabled(bool)   или   set_process(bool)
	for n in get_tree().get_nodes_in_group(Groups.Spawner):
		if n is EnemySpawnArea:
			n.set_is_active(active)
			
func _start_slot_machine():
	for n in get_tree().get_nodes_in_group(Groups.SlotMachine):
		if n is SlotMachineManager:
			n.start()
