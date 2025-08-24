class_name SlotMachineConfig
extends Resource

# Настройки качества круток
@export_group("Качество круток")
@export var common_threshold: int = 10
@export var rare_threshold: int = 25
@export var epic_threshold: int = 50
@export var legendary_threshold: int = 100

# Множители поражения (параметры уменьшаются меньше, чем увеличиваются)
@export_group("Множители поражения")
@export var lose_multiplier: float = 0.5  # При поражении параметры уменьшаются в 2 раза меньше

# Настройки изменения статов для каждого качества
@export_group("Обычное качество")
@export var common_hp_change: int = 2
@export var common_speed_change: float = 10.0
@export var common_damage_change: float = 5.0
@export var common_fire_rate_change: float = 0.1

@export_group("Редкое качество")
@export var rare_hp_change: int = 4
@export var rare_speed_change: float = 20.0
@export var rare_damage_change: float = 10.0
@export var rare_fire_rate_change: float = 0.2

@export_group("Эпическое качество")
@export var epic_hp_change: int = 8
@export var epic_speed_change: float = 40.0
@export var epic_damage_change: float = 20.0
@export var epic_fire_rate_change: float = 0.4

@export_group("Легендарное качество")
@export var legendary_hp_change: int = 15
@export var legendary_speed_change: float = 80.0
@export var legendary_damage_change: float = 40.0
@export var legendary_fire_rate_change: float = 0.8

# Получить порог для качества
func get_threshold(quality: int) -> int:
	match quality:
		0: return common_threshold
		1: return rare_threshold
		2: return epic_threshold
		3: return legendary_threshold
		_: return common_threshold

# Получить изменение стата для качества
func get_stat_change(quality: int, stat_type: int) -> float:
	var hp_change = 0
	var speed_change = 0.0
	var damage_change = 0.0
	var fire_rate_change = 0.0
	
	match quality:
		0: # Common
			hp_change = common_hp_change
			speed_change = common_speed_change
			damage_change = common_damage_change
			fire_rate_change = common_fire_rate_change
		1: # Rare
			hp_change = rare_hp_change
			speed_change = rare_speed_change
			damage_change = rare_damage_change
			fire_rate_change = rare_fire_rate_change
		2: # Epic
			hp_change = epic_hp_change
			speed_change = epic_speed_change
			damage_change = epic_damage_change
			fire_rate_change = epic_fire_rate_change
		3: # Legendary
			hp_change = legendary_hp_change
			speed_change = legendary_speed_change
			damage_change = legendary_damage_change
			fire_rate_change = legendary_fire_rate_change
	
	match stat_type:
		0: return float(hp_change)
		1: return speed_change
		2: return damage_change
		3: return fire_rate_change
		_: return 0.0

# Получить множитель для поражения
func get_lose_multiplier() -> float:
	return lose_multiplier
