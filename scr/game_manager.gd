extends Node

## Начальное количество жизней
@export var max_lives: int = 3
## Текущий счёт
@export var score: int = 0

var lives: int = 3

signal lives_changed(new_lives: int)
signal score_changed(new_score: int)
signal game_over()


func _ready():
	reset()


func reset():
	lives = max_lives
	score = 0
	lives_changed.emit(lives)
	score_changed.emit(score)


func take_damage(amount: int = 1) -> bool:
	lives -= amount
	if lives < 0:
		lives = 0
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		return true
	return false


func add_score(points: int):
	score += points
	score_changed.emit(score)
