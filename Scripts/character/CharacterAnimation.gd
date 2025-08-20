extends AnimationPlayer
class_name CharacterAnimation

@export var Sprite: AnimatedSprite2D

@export var IdleAnim: StringName = "idle"
@export var RunAnim: StringName = "run"
@export var JumpAnim: StringName = "jump"
@export var FallAnim: StringName = "fall"

func _ready() -> void:
	if Sprite:
		Sprite.play()

func set_facing(x_dir: float) -> void:
	if not Sprite:
		return
	if x_dir != 0.0:
		Sprite.flip_h = x_dir < 0.0

func idle() -> void: play(IdleAnim)
func run() -> void: play(RunAnim)
func jump() -> void: play(JumpAnim)
func fall() -> void: play(FallAnim)
