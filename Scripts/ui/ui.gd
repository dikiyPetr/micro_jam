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

	var tier = 'Uncommon';
	var tierSize = 100;
	CoinBar.max_value = tierSize;
	CoinBar.value = Global.gambleStat.coins;
	CoinBarText.text = Global.formatTier(tier, tierSize);

	WaveTime.text = Global.formatTime();
	
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
