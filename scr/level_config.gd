extends Node

## Количество жизней на этом уровне
@export var level_lives: int = 3
## Сколько раз можно скорректировать траекторию за один запуск
@export var level_corrections: int = 3


func _ready():
	# Откладываем, чтобы UI точно успел подписаться
	call_deferred("_do_configure")


func _do_configure():
	GameManager.configure(level_lives, level_corrections)
	print("[LEVEL_CONFIG] configured: lives=", level_lives, " corrections=", level_corrections)
