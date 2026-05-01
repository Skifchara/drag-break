extends CanvasLayer

@onready var _lives_label: Label = $LivesLabel
@onready var _corrections_label: Label = $CorrectionsLabel


func _ready():
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.corrections_changed.connect(_on_corrections_changed)
	GameManager.game_over.connect(_on_game_over)

	# Синхронизация после подписки — если LevelConfig уже вызвал configure()
	_sync()


func _sync():
	_lives_label.text = "Lives: %d" % GameManager.lives
	_corrections_label.text = "Corrections: %d" % GameManager.corrections_remaining


func _on_lives_changed(new_lives: int):
	_lives_label.text = "Lives: %d" % new_lives


func _on_corrections_changed(remaining: int):
	_corrections_label.text = "Corrections: %d" % remaining


func _on_game_over():
	_lives_label.text = "GAME OVER"
	_corrections_label.text = ""
