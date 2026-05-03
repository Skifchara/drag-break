extends Area2D

## Цель уровня — мяч касается триггера → уровень пройден.
##
## Размещается в сцене уровня как Area2D с CollisionShape2D (или Polygon).
## collision_mask должна включать слой мяча (по умолчанию 1).

signal level_completed

@export_group("Effects")
@export var flash_color: Color = Color(1, 1, 0.5, 0.3)
@export var flash_duration: float = 0.4

var _triggered: bool = false


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node):
	if _triggered:
		return
	if not body is RigidBody2D:
		return
	_triggered = true
	level_completed.emit()
	GameManager.complete_level()


func reset():
	_triggered = false
