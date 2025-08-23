extends Node
var playerStat : PlayerStat = PlayerStat.new()
var gambleStat : GambleStat = GambleStat.new()
var waveStat : WaveStat = WaveStat.new()
var enemyStat: EnemyStat = EnemyStat.new()
var weaponStat: WeaponStat = WeaponStat.new()
var dropStat: DropStat = DropStat.new()
var spawnStat: SpawnStat = SpawnStat.new()

func reset() -> void:
	playerStat = PlayerStat.new()
	gambleStat = GambleStat.new()
	waveStat = WaveStat.new()
	enemyStat = EnemyStat.new()
	weaponStat = WeaponStat.new()
	dropStat = DropStat.new()
	spawnStat = SpawnStat.new()
	
func formatHP() -> String:
	var fstr = '%d / %d';
	return fstr % [playerStat.currentHp, playerStat.maxHp]

func formatTier(tier: String, need: int) -> String:
	var fstr = '%s - %d';
	var res = fstr % [tier, (float(gambleStat.coins) / need) * 100];
	return res + '%';

func formatTime() -> String:
	var fstr = '%ds';
	return fstr % waveStat.timeLeft;
