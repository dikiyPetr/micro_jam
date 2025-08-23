extends Node

var PlayerHP = 10;
var MaxPlayerHP = 15;
var PlayerCoins = 75;
var WaveTime = 0;

func formatHP() -> String:
	var fstr = '%d / %d';
	return fstr % [PlayerHP, MaxPlayerHP]

func formatTier(tier: String, need: int) -> String:
	var fstr = '%s - %d';
	var res = fstr % [tier, (float(PlayerCoins) / need) * 100];
	return res + '%';

func formatTime() -> String:
	var fstr = '%ds';
	return fstr % WaveTime;
