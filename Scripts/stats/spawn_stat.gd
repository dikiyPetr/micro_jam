class_name SpawnStat
var spawn_every: float = 0.8            # раз в N секунд планируем спавн
var per_tick: int = 2	   # сколько попыток/точек за тик
var delay_min: float = 0.1                 # задержка появления (мин)
var delay_max: float = 0.5   
var max_alive_from_this_spawner: int = 15

func level2() -> void:
	spawn_every=0.7
	per_tick=3
	delay_min=0.1
	delay_min=0.4
	max_alive_from_this_spawner=25

func level3() -> void:
	spawn_every=0.5
	per_tick=4
	delay_min=0.1
	delay_min=0.3
	max_alive_from_this_spawner=30
	
func level4() -> void:
	spawn_every=0.3
	per_tick=5
	delay_min=0.1
	delay_min=0.3
	max_alive_from_this_spawner=35
	
func levelX(x:float) -> void:
	spawn_every=min(0.1,0,5-(0.1*x))
	per_tick=1+x
	delay_min=0.1
	delay_min=0.5-(0.5*x)
	max_alive_from_this_spawner=15+(5*x)
