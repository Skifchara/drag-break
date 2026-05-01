extends StaticBody2D

## Сила толчка вверх (пиксели/сек)
@export var jump_force: float = 1800.0
## Толчок строго по оси Y или по нормали платформы?
@export var strict_up: bool = true
## Задержка перед повторным срабатыванием (сек)
@export var cooldown: float = 0.15

var _ready_to_jump: bool = true

@onready var _area: Area2D = $Area2D as Area2D
@onready var _sprite: Sprite2D = $Sprite2D as Sprite2D


func _ready():
	_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node):
	if not _ready_to_jump:
		return
	if not body is RigidBody2D:
		return

	var ball := body as RigidBody2D
	var vel := ball.linear_velocity

	if strict_up:
		vel.y = -jump_force
	else:
		# Сохраняем горизонтальную скорость, меняем вертикаль
		vel.y = -jump_force

	ball.linear_velocity = vel
	_ready_to_jump = false
	_bounce_visual()

	# Кулдаун
	await get_tree().create_timer(cooldown).timeout
	if is_inside_tree() and not is_queued_for_deletion():
		_ready_to_jump = true


func _bounce_visual():
	# Лёгкий визуальный отклик — можно расширить
	if _sprite:
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(_sprite, "scale", Vector2(-0.15, 0.01), 0.08)
		tween.tween_property(_sprite, "scale", Vector2(-0.12, 0.02), 0.15)
