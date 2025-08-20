extends Node
class_name CharacterStat
@export_group("Move")
@export var MaxSpeed: float = 160.0
@export var Accel: float = 1200.0
@export var Decel: float = 1400.0
@export var AirControl: float = 0.6

@export_group("Jump")
@export var JumpVelocity: float = -300.0
@export var LowJumpMultiplier: float = 1.6
@export var Gravity: float = 900.0
@export var CoyoteTime: float = 0.12
@export var JumpBufferTime: float = 0.12
