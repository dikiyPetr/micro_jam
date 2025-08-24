class_name SlotMachineTriggerConfig
extends Resource

# Количество монет для запуска слот-машины
@export_group("Условия запуска")
@export var coins_required: int = 50

# Настройки времени для определения качества крутки
@export_group("Временные пороги для качества")
@export var legendary_time_threshold: float = 30.0  # секунд для легендарного качества
@export var epic_time_threshold: float = 60.0       # секунд для эпического качества
@export var rare_time_threshold: float = 120.0      # секунд для редкого качества
@export var common_time_threshold: float = 300.0    # секунд для обычного качества

# Получить качество крутки на основе времени
func get_quality_from_time(time_elapsed: float) -> int:
	if time_elapsed <= legendary_time_threshold:
		return 3  # Legendary
	elif time_elapsed <= epic_time_threshold:
		return 2  # Epic
	elif time_elapsed <= rare_time_threshold:
		return 1  # Rare
	elif time_elapsed <= common_time_threshold:
		return 0  # Common
	else:
		return 0  # Common (по умолчанию)

# Получить название качества
func get_quality_name(quality: int) -> String:
	match quality:
		0: return "Обычное"
		1: return "Редкое"
		2: return "Эпическое"
		3: return "Легендарное"
		_: return "Обычное"
