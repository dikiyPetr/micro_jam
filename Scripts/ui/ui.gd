extends CanvasLayer

@export var HealthBar: ProgressBar;
@export var HealthBarText: Label;
@export var CoinBar: ProgressBar;
@export var CoinBarText: Label;
@export var WaveTime: Label;
@export var StatsContainer: VBoxContainer;

func _process(delta):
	HealthBar.max_value = Global.playerStat.maxHp;
	HealthBar.value = Global.playerStat.currentHp;
	HealthBarText.text = Global.formatHP();

	# Определяем качество крутки на основе времени
	var current_time = Global.gambleStat.get_current_game_time()
	var time_elapsed = current_time - Global.gambleStat.lastDepTime
	
	# Получаем конфигурацию триггера слот-машины
	var trigger_config = get_node("../SlotMachineManager").trigger_config
	var quality = 0
	var quality_name = "Common"
	var quality_color = Color.WHITE
	
	if trigger_config:
		quality = trigger_config.get_quality_from_time(time_elapsed)
		quality_name = trigger_config.get_quality_name(quality)
		# Получаем цвет качества из stat_modifier
		var slot_manager = get_node("../SlotMachineManager")
		if slot_manager and slot_manager.stat_modifier:
			quality_color = slot_manager.stat_modifier.get_quality_color(quality)
	
	var tierSize = Global.gambleStat.coins_required;
	CoinBar.max_value = tierSize;
	CoinBar.value = Global.gambleStat.coins;
	
	# Отображаем качество крутки
	CoinBarText.text = quality_name
	CoinBarText.modulate = quality_color

	WaveTime.text ='%d$' % Global.gambleStat.totalCoins
	
	# Обновляем характеристики персонажа
	update_stats();

func update_stats():
	# Получаем дочерние элементы StatsContainer
	var hp_stat = StatsContainer.get_node("HPStat");
	var speed_stat = StatsContainer.get_node("SpeedStat");
	var damage_stat = StatsContainer.get_node("DamageStat");
	var fire_rate_stat = StatsContainer.get_node("FireRateStat");
	
	# Обновляем текст характеристик
	hp_stat.text = "HP: %d" % Global.playerStat.maxHp;
	speed_stat.text = "Speed: %.0f" % Global.playerStat.maxSpeed;
	damage_stat.text = "Damage: %d" % Global.weaponStat.damage;
	fire_rate_stat.text = "Fire Rate: %.1f" % Global.weaponStat.fire_rate;
