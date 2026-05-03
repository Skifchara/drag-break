extends CanvasLayer

## GameplayUI — иконки жизней (сердца) из GUI-пака + кнопка паузы.
## Оверлеи GameOver/LevelWon/Pause — отдельные сцены.

@export_group("Lives")
@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_spacing: int = 12
@export var lives_position_offset: Vector2 = Vector2(24, 32)

@export_group("Corrections")
@export var correction_dot_radius: float = 9.0
@export var correction_dot_spacing: float = 26.0
@export var correction_dot_color: Color = Color(0.2, 0.8, 1.0, 0.9)
@export var correction_dot_empty_color: Color = Color(0.2, 0.8, 1.0, 0.2)
@export var corrections_position_offset: Vector2 = Vector2(24, 68)

@export_group("Pause Button")
@export var pause_button_size: Vector2 = Vector2(64, 64)
@export var pause_button_margin: float = 20.0

@onready var _drawer: Control = $UidDrawer
@onready var _pause_button: Button = $PauseButton
@onready var _hearts_row: HBoxContainer = $HeartsRow

var _game_over_scene: PackedScene = preload("res://scenes/game_over_screen.tscn")
var _level_won_scene: PackedScene = preload("res://scenes/level_won_screen.tscn")
var _pause_scene: PackedScene = preload("res://scenes/pause_screen.tscn")

var _pause_screen: CanvasLayer = null
var _game_over_screen: CanvasLayer = null
var _level_won_screen: CanvasLayer = null

var _heart_full: Texture2D
var _heart_empty: Texture2D


func _ready():
	_heart_full = load(GUIHelper.HEART_FULL)
	_heart_empty = load(GUIHelper.HEART_EMPTY)

	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.corrections_changed.connect(_on_corrections_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_won.connect(_on_level_won)
	_pause_button.pressed.connect(_on_pause_pressed)

	_update_hearts()
	_drawer.queue_redraw()


func _update_hearts() -> void:
	if not _hearts_row:
		return
	for child in _hearts_row.get_children():
		child.queue_free()
	for i in range(GameManager.max_lives):
		var rect := TextureRect.new()
		rect.texture = _heart_full if i < GameManager.lives else _heart_empty
		rect.custom_minimum_size = heart_size
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		_hearts_row.add_child(rect)


func _on_lives_changed(_new_lives: int):
	_update_hearts()


func _on_corrections_changed(_remaining: int):
	_drawer.queue_redraw()


func _on_game_over():
	if _game_over_screen:
		return
	_game_over_screen = _game_over_scene.instantiate()
	get_tree().current_scene.add_child(_game_over_screen)


func _on_level_won():
	if _level_won_screen:
		return
	_level_won_screen = _level_won_scene.instantiate()
	get_tree().current_scene.add_child(_level_won_screen)


func _on_pause_pressed():
	if _pause_screen:
		return
	_pause_screen = _pause_scene.instantiate()
	get_tree().current_scene.add_child(_pause_screen)
	_pause_screen.show_pause()
