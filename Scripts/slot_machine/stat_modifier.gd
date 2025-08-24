class_name StatModifier
extends Resource

# Качество круток
enum Quality {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Возможные статы для изменения
enum StatType {
	MAX_HP,
	MAX_SPEED,
	DAMAGE,
	FIRE_RATE
}

# Конфигурация
@export var config: Resource

# Получить качество крутки на основе количества монет
func get_quality_from_coins(coin_count: int) -> int:
	if not config:
		return Quality.COMMON
		
	if coin_count >= config.legendary_threshold:
		return Quality.LEGENDARY
	elif coin_count >= config.epic_threshold:
		return Quality.EPIC
	elif coin_count >= config.rare_threshold:
		return Quality.RARE
	else:
		return Quality.COMMON

# Получить случайный тип стата для изменения
func get_random_stat_type() -> int:
	var stat_types = StatType.values()
	return stat_types[randi() % stat_types.size()]

# Применить изменение стата
func apply_stat_change(player_stat: PlayerStat, stat_type: int, quality: int, is_win: bool) -> Dictionary:
	if not config:
		return {}
		
	var change_value = config.get_stat_change(quality, stat_type)
	var actual_change = 0.0
	
	if is_win:
		# При победе - увеличиваем параметр
		actual_change = change_value
	else:
		# При поражении - уменьшаем параметр с множителем
		actual_change = -change_value * config.get_lose_multiplier()
	
	# Отладочная информация
	print("=== Изменение стата ===")
	print("Тип стата: ", get_stat_name(stat_type))
	print("Качество: ", get_quality_name(quality))
	print("Базовое изменение: ", change_value)
	print("Фактическое изменение: ", actual_change)
	print("Результат: ", "Победа" if is_win else "Поражение")
	
	match stat_type:
		StatType.MAX_HP:
			print("HP до: ", player_stat.maxHp, " / ", player_stat.currentHp)
			player_stat.maxHp += int(actual_change)
			player_stat.currentHp += int(actual_change) # Также изменяем текущее HP
			print("HP после: ", player_stat.maxHp, " / ", player_stat.currentHp)
		StatType.MAX_SPEED:
			print("Скорость до: ", player_stat.maxSpeed)
			player_stat.maxSpeed += actual_change
			print("Скорость после: ", player_stat.maxSpeed)
		StatType.DAMAGE:
			print("Урон до: ", Global.weaponStat.damage)
			Global.weaponStat.damage += actual_change
			print("Урон после: ", Global.weaponStat.damage)
		StatType.FIRE_RATE:
			print("Скорострельность до: ", Global.weaponStat.fire_rate)
			Global.weaponStat.fire_rate += actual_change
			print("Скорострельность после: ", Global.weaponStat.fire_rate)
	
	print("=====================")
	
	return {
		"stat_type": stat_type,
		"quality": quality,
		"change": actual_change,
		"is_win": is_win
	}

# Получить название стата для отображения
func get_stat_name(stat_type: int) -> String:
	match stat_type:
		StatType.MAX_HP:
			return "Макс. HP"
		StatType.MAX_SPEED:
			return "Скорость"
		StatType.DAMAGE:
			return "Урон"
		StatType.FIRE_RATE:
			return "Скорострельность"
		_:
			return "Неизвестно"

# Получить название качества для отображения
func get_quality_name(quality: int) -> String:
	match quality:
		Quality.COMMON:
			return "Обычное"
		Quality.RARE:
			return "Редкое"
		Quality.EPIC:
			return "Эпическое"
		Quality.LEGENDARY:
			return "Легендарное"
		_:
			return "Неизвестно"

# Получить цвет качества для отображения
func get_quality_color(quality: int) -> Color:
	match quality:
		Quality.COMMON:
			return Color.WHITE
		Quality.RARE:
			return Color.BLUE
		Quality.EPIC:
			return Color.PURPLE
		Quality.LEGENDARY:
			return Color.ORANGE
		_:
			return Color.WHITE
