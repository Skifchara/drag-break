extends CanvasLayer

## LevelWonScreen — появляется при прохождении уровня.
## Показывает звёзды (иконки из GUI-пака) на основе оставшихся жизней.
## process_mode = ALWAYS — работает при паузе.

@onready var _stars_row: HBoxContainer = $Overlay/PanelCenter/VBoxContainer/StarsRow
@onready var _next_button: Button = $Overlay/PanelCenter/VBoxContainer/NextButton
@onready var _retry_button: Button = $Overlay/PanelCenter/VBoxContainer/RetryButton
@onready var _select_button: Button = $Overlay/PanelCenter/VBoxContainer/SelectButton


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_next_button.pressed.connect(_on_next)
	_retry_button.pressed.connect(_on_retry)
	_select_button.pressed.connect(_on_select)

	# Звёзды на основе оставшихся жизней
	var stars: int = clampi(GameManager.lives, 1, 3)
	_fill_stars(stars)

	get_tree().paused = true


func _fill_stars(count: int) -> void:
	# Очистить ряд звёзд
	for child in _stars_row.get_children():
		child.queue_free()
	# Добавить иконки звёзд
	var star_full: Texture2D = load(GUIHelper.STAR_FULL)
	var star_grey: Texture2D = load(GUIHelper.STAR_GREY)
	var star_size: Vector2 = Vector2(56, 56)
	for i in range(3):
		var rect := TextureRect.new()
		rect.texture = star_full if i < count else star_grey
		rect.custom_minimum_size = star_size
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_stars_row.add_child(rect)


func _on_next() -> void:
	get_tree().paused = false
	var next: int = GameManager.current_level + 1
	if next <= SaveManager.total_levels and SaveManager.is_level_unlocked(next):
		GameManager.current_level = next
		var path: String = "res://level_data/level_%d.tscn" % next
		if next == 1:
			path = "res://level_data/level_test1.tscn"
		TransitionManager.transition_to(path)
	else:
		TransitionManager.transition_to("res://scenes/level_select.tscn")


func _on_retry() -> void:
	get_tree().paused = false
	var current: String = get_tree().current_scene.scene_file_path
	TransitionManager.transition_to(current)


func _on_select() -> void:
	get_tree().paused = false
	TransitionManager.transition_to("res://scenes/level_select.tscn")