extends Area2D

## Сколько единиц жизней отнимает шип
@export var damage: int = 1


func _ready():
	print("[SPIKE] _ready, collision_mask=", collision_mask, " layers=", collision_layer)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node):
	print("[SPIKE] body_entered: ", body.name, " type=", body.get_class())
	if not body is RigidBody2D:
		print("[SPIKE] not RigidBody2D, skip")
		return
	var ball = body as RigidBody2D
	if ball.has_method("_on_hit_spike"):
		print("[SPIKE] calling _on_hit_spike(damage=", damage, ")")
		ball._on_hit_spike(damage)
	else:
		print("[SPIKE] _on_hit_spike method not found")
