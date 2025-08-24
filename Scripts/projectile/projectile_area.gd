extends Area2D
class_name ProjectileArea
@export_group("Debug")
@export var debug_draw: bool = true
@onready var _shape: CollisionShape2D = $CollisionShape2D

func _physics_process(_delta: float) -> void:
	if debug_draw:
		queue_redraw()
		
func _on_area_exited(a: Area2D) -> void:
	if a.is_in_group(Groups.Projectile):
		a.queue_free()

func _draw() -> void:
	if not debug_draw:
		return
	# контур круглой области (берём радиус из CollisionShape2D, если это CircleShape2D)
	if _shape and _shape.shape is CircleShape2D:
		var r := (_shape.shape as CircleShape2D).radius
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(0.2, 0.7, 1, 0.25), 2.0, true)
