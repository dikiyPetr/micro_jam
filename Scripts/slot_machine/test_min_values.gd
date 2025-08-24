extends Node

# Тестовый скрипт для проверки минимальных значений статов
class_name TestMinValues

func test_min_values():
	print("=== Тест минимальных значений ===")
	
	# Загружаем конфигурацию
	var config = load("res://Scripts/slot_machine/slot_machine_config.tres")
	if not config:
		print("ОШИБКА: Не удалось загрузить конфигурацию")
		return
	
	# Загружаем модификатор статов
	var stat_modifier = load("res://Scripts/slot_machine/stat_modifier.tres")
	if not stat_modifier:
		print("ОШИБКА: Не удалось загрузить модификатор статов")
		return
	
	# Создаем тестовые статы игрока
	var test_player_stat = PlayerStat.new()
	test_player_stat.maxHp = 10
	test_player_stat.currentHp = 10
	test_player_stat.maxSpeed = 100.0
	
	# Создаем тестовые статы оружия
	var test_weapon_stat = WeaponStat.new()
	test_weapon_stat.damage = 5.0
	test_weapon_stat.fire_rate = 0.5
	
	# Сохраняем оригинальные значения
	Global.weaponStat = test_weapon_stat
	
	print("Начальные значения:")
	print("HP: ", test_player_stat.maxHp)
	print("Скорость: ", test_player_stat.maxSpeed)
	print("Урон: ", test_weapon_stat.damage)
	print("Скорострельность: ", test_weapon_stat.fire_rate)
	print()
	
	# Тестируем минимальные значения для каждого стата
	var stat_types = [0, 1, 2, 3] # MAX_HP, MAX_SPEED, DAMAGE, FIRE_RATE
	
	for stat_type in stat_types:
		print("--- Тест стата ", stat_modifier.get_stat_name(stat_type), " ---")
		
		# Устанавливаем очень низкие значения
		match stat_type:
			0: # HP
				test_player_stat.maxHp = 1
				test_player_stat.currentHp = 1
				print("Установлено: maxHP=1, currentHP=1")
			1: # Speed
				test_player_stat.maxSpeed = 10.0
			2: # Damage
				test_weapon_stat.damage = 0.1
			3: # Fire rate
				test_weapon_stat.fire_rate = 0.01
		
		print("Значение до изменения: ", _get_current_stat_value(stat_type, test_player_stat, test_weapon_stat))
		
		# Пытаемся уменьшить стат (поражение)
		var result = stat_modifier.apply_stat_change(test_player_stat, stat_type, 0, false) # Common, поражение
		
		print("Значение после изменения: ", _get_current_stat_value(stat_type, test_player_stat, test_weapon_stat))
		if stat_type == 0: # HP
			print("MaxHP после: ", test_player_stat.maxHp, ", CurrentHP после: ", test_player_stat.currentHp)
		print("Минимальное значение: ", config.get_min_stat_value(stat_type))
		print("Результат применения: ", result)
		print()

func _get_current_stat_value(stat_type: int, player_stat: PlayerStat, weapon_stat: WeaponStat) -> float:
	match stat_type:
		0: return float(player_stat.maxHp)
		1: return player_stat.maxSpeed
		2: return weapon_stat.damage
		3: return weapon_stat.fire_rate
		_: return 0.0

# Функция для запуска теста из редактора
func run_test():
	test_min_values()
	test_hp_death_scenario()

# Дополнительный тест для проверки возможности смерти игрока
func test_hp_death_scenario():
	print("\n=== Тест сценария смерти игрока ===")
	
	# Загружаем модификатор статов
	var stat_modifier = load("res://Scripts/slot_machine/stat_modifier.tres")
	if not stat_modifier:
		print("ОШИБКА: Не удалось загрузить модификатор статов")
		return
	
	# Создаем тестовые статы игрока
	var test_player_stat = PlayerStat.new()
	test_player_stat.maxHp = 5
	test_player_stat.currentHp = 2  # Низкое текущее HP
	
	print("Начальное состояние: maxHP=", test_player_stat.maxHp, ", currentHP=", test_player_stat.currentHp)
	
	# Пытаемся уменьшить HP (поражение)
	var result = stat_modifier.apply_stat_change(test_player_stat, 0, 0, false) # HP, Common, поражение
	
	print("После изменения: maxHP=", test_player_stat.maxHp, ", currentHP=", test_player_stat.currentHp)
	print("Может ли игрок умереть? ", test_player_stat.currentHp <= 0)
	print("================================")
