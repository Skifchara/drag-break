extends Node

## Начальное количество жизней
var max_lives: int = 3
## Сколько раз можно скорректировать траекторию за один запуск
var max_corrections: int = 3

var lives: int = 3
var corrections_remaining: int = 3
var current_level: int = 1

signal lives_changed(new_lives: int)
signal corrections_changed(remaining: int)
signal game_over()
signal level_won()


func _ready():
	# Не эмитим — сцены ещё не загружены
	pass


func reset():
	lives = max_lives
	corrections_remaining = max_corrections
	lives_changed.emit(lives)
	corrections_changed.emit(corrections_remaining)


func take_damage(amount: int = 1) -> bool:
	lives -= amount
	if lives < 0:
		lives = 0
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		return true
	return false


func use_correction() -> bool:
	if corrections_remaining <= 0:
		return false
	corrections_remaining -= 1
	corrections_changed.emit(corrections_remaining)
	return true


func refund_correction():
	corrections_remaining = mini(corrections_remaining + 1, max_corrections)
	corrections_changed.emit(corrections_remaining)


func refill_corrections():
	corrections_remaining = max_corrections
	corrections_changed.emit(corrections_remaining)


func configure(new_lives: int, new_corrections: int):
	max_lives = new_lives
	max_corrections = new_corrections
	reset()


func complete_level():
	# Звёзды: на основе оставшихся жизней (1 звезда = 1 жизнь, макс 3)
	var stars: int = clampi(lives, 1, 3)
	SaveManager.complete_level(current_level, stars)
	level_won.emit()
