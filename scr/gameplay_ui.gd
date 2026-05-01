extends CanvasLayer

@onready var _lives_label: Label = $LivesLabel
@onready var _score_label: Label = $ScoreLabel


func _ready():
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.game_over.connect(_on_game_over)

	# Изначальное состояние
	_lives_label.text = "Lives: %d" % GameManager.lives
	_score_label.text = "Score: %d" % GameManager.score


func _on_lives_changed(new_lives: int):
	_lives_label.text = "Lives: %d" % new_lives


func _on_score_changed(new_score: int):
	_score_label.text = "Score: %d" % new_score


func _on_game_over():
	# Простая заглушка — можно расширить
	_lives_label.text = "GAME OVER"
