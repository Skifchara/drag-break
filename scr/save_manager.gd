extends Node

## SaveManager — autoload синглтон для хранения прогресса.
##
## Сохраняет: какие уровни пройдены, сколько звёзд.
## Формат: JSON в user://save_data.json
##
## Звёзды: на основе оставшихся жизней при завершении уровня.
##   3 жизни = 3 звезды, 2 = 2 звезды, 1 = 1 звезда.

signal save_changed

const SAVE_PATH: String = "user://save_data.json"

## Сколько всего уровней в игре
var total_levels: int = 50

## Множество пройденных уровней
var _completed: Dictionary = {}  # level_number -> true
## Звёзды по уровню: level_number -> stars (1-3)
var _stars: Dictionary = {}  # level_number -> int


func _ready():
	load_data()


func is_level_unlocked(level: int) -> bool:
	if level <= 0:
		return false
	# Уровень 1 всегда открыт
	if level == 1:
		return true
	# Уровень N открыт если N-1 пройден
	return _completed.has(level - 1)


func is_level_completed(level: int) -> bool:
	return _completed.has(level)


func get_stars(level: int) -> int:
	if _stars.has(level):
		return _stars[level]
	return 0


func complete_level(level: int, stars: int) -> void:
	stars = clampi(stars, 1, 3)
	_completed[level] = true
	# Сохраняем лучшие звёзды (не хуже предыдущего)
	if _stars.has(level):
		_stars[level] = maxi(_stars[level], stars)
	else:
		_stars[level] = stars
	save_data()
	save_changed.emit()


func reset_progress() -> void:
	_completed.clear()
	_stars.clear()
	save_data()
	save_changed.emit()


func save_data() -> void:
	var data: Dictionary = {
		"completed": _completed.keys(),
		"stars": _stars,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_completed.clear()
		_stars.clear()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data: Dictionary = json.data
	if data.has("completed"):
		for level in data["completed"]:
			_completed[int(level)] = true
	if data.has("stars"):
		var stars_data: Dictionary = data["stars"]
		for key in stars_data:
			_stars[int(key)] = int(stars_data[key])