class_name EnemyStat
var damage :float= 1
var hp := 1
var max_speed: float = 100.0

func level2() -> void:
	damage=1
	hp=3
	max_speed=130

func level3() -> void:
	damage=2
	hp=5
	max_speed=140
	
func level4() -> void:
	damage=2
	hp=10
	max_speed=150
	
# 
func levelX(x:float) -> void:
	damage = 1 + 0.5 * x
	hp = 1 + 2 * x
	max_speed=100+10*x
