extends CharacterBase
class_name PlayerController

@export var CoyoteTimerCoyoteTimer: Timer 
@export var JumpBufferTimer: Timer
@export var Anim: CharacterAnimation
@export var ChStat: CharacterStat
func _get_Animator() -> CharacterAnimation:
	return Anim
func _get_Stat() -> CharacterStat:
	return ChStat
	
func collect_intents() -> void:
	var input := 0.0
	if Input.is_action_pressed(PlayerInput.Right):
		input += 1.0
	if Input.is_action_pressed(PlayerInput.Left):
		input -= 1.0

	moveX = input

func update_anim() -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			if _get_Animator(): _get_Animator().jump()
		else:
			if _get_Animator(): _get_Animator().fall()
	elif absf(velocity.x) > 5.0:
		if _get_Animator(): _get_Animator().run()
	else:
		if _get_Animator(): _get_Animator().idle()
