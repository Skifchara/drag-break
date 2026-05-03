extends Control

## LevelSelect — сетка 4×6 с пагинацией.
## Использует Basic_GUI_Bundle для кнопок и иконок.

@export var grid_columns: int = 4
@export var grid_rows: int = 6
@export var total_levels: int = 50
@export var cell_size: Vector2 = Vector2(100, 100)
@export var grid_spacing: int = 14

@onready var _grid: GridContainer = $ScrollContainer/GridContainer
@onready var _back_button: Button = $BackButton
@onready var _pagination: HBoxContainer = $Pagination

var _current_page: int = 0
var _total_pages: int = 1
var _levels_per_page: int = 24


func _ready():
	_back_button.pressed.connect(_on_back_pressed)
	_levels_per_page = grid_columns * grid_rows
	_total_pages = ceili(float(total_levels) / float(_levels_per_page))
	_show_page(0)


func _show_page(page: int) -> void:
	_current_page = page
	# Очистка grid
	for child in _grid.get_children():
		child.queue_free()
	# Заполнение кнопками
	var start: int = page * _levels_per_page + 1
	for i in range(_levels_per_page):
		var level_num: int = start + i
		if level_num > total_levels:
			break
		var btn := _create_level_button(level_num)
		_grid.add_child(btn)
	_update_pagination()


func _create_level_button(level_num: int) -> Button:
	var unlocked: bool = SaveManager.is_level_unlocked(level_num)
	var completed: bool = SaveManager.is_level_unlocked(level_num)  # TODO: is_level_completed
	var stars: int = SaveManager.get_stars(level_num)

	var btn: Button
	if not unlocked:
		btn = GUIHelper.make_level_cell(level_num, false, false, 0, cell_size)
		btn.disabled = true
		# Серый фон для заблокированных — без flat
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 4
		style.content_margin_right = 4
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("disabled", style)
		btn.icon = load(GUIHelper.ICON_LOCK)
		btn.icon_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true
		btn.text = ""
	elif completed and stars > 0:
		btn = GUIHelper.make_level_cell(level_num, true, completed, stars, cell_size)
		btn.text = "%d\n%s" % [level_num, "★".repeat(stars)]
	else:
		btn = GUIHelper.make_level_cell(level_num, true, completed, stars, cell_size)

	# Растягивать кнопку по ячейке грида
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL

	btn.pressed.connect(_on_level_pressed.bind(level_num))
	return btn


func _update_pagination() -> void:
	for child in _pagination.get_children():
		child.queue_free()
	for i in range(_total_pages):
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(16, 16)
		if i == _current_page:
			dot.modulate = Color.WHITE
		else:
			dot.modulate = Color(0.4, 0.4, 0.4, 0.7)
		_pagination.add_child(dot)


func _on_level_pressed(level_num: int) -> void:
	var path: String
	if level_num == 1:
		path = "res://level_data/level_test1.tscn"
	else:
		path = "res://level_data/level_%d.tscn" % level_num
	# Проверяем что файл существует
	if not ResourceLoader.exists(path):
		# Файла уровня нет — сообщаем
		print("Level file not found: ", path)
		return
	GameManager.current_level = level_num
	GameManager.reset()
	TransitionManager.transition_to(path)


func _on_back_pressed() -> void:
	TransitionManager.transition_to("res://scenes/main_menu.tscn")


func _input(event: InputEvent) -> void:
	# Свайп между страницами
	if event is InputEventScreenDrag:
		if event.relative.x > 50:
			if _current_page > 0:
				_show_page(_current_page - 1)
		elif event.relative.x < -50:
			if _current_page < _total_pages - 1:
				_show_page(_current_page + 1)