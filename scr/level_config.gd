extends Node

## Конфигурация уровня — висит на корне сцены уровня.
## Настраивается через инспектор.

## Количество жизней на этом уровне
@export var level_lives: int = 3
## Сколько раз можно скорректировать траекторию за один запуск
@export var level_corrections: int = 3
## Номер уровня (для SaveManager)
@export var level_number: int = 1


func _ready():
	# Откладываем, чтобы UI точно успел подписаться
	call_deferred("_do_configure")


func _do_configure():
	GameManager.current_level = level_number
	GameManager.configure(level_lives, level_corrections)
