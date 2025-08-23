extends CanvasLayer

@export var HealthBar: ProgressBar;
@export var HealthBarText: Label;
@export var CoinBar: ProgressBar;
@export var CoinBarText: Label;
@export var WaveTime: Label;

func _process(delta):
	HealthBar.max_value = Global.MaxPlayerHP;
	HealthBar.value = Global.PlayerHP;
	HealthBarText.text = Global.formatHP();

	var tier = 'Uncommon';
	var tierSize = 100;
	CoinBar.max_value = tierSize;
	CoinBar.value = Global.PlayerCoins;
	CoinBarText.text = Global.formatTier(tier, tierSize);

	WaveTime.text = Global.formatTime();
