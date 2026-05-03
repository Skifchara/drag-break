extends CanvasLayer

## GameOverScreen — появляется при проигрыше.
## process_mode = ALWAYS — работает при паузе.

@onready var _retry_button: Button = $Overlay/PanelCenter/VBoxContainer/RetryButton
@onready var _select_button: Button = $Overlay/PanelCenter/VBoxContainer/SelectButton


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_retry_button.pressed.connect(_on_retry)
	_select_button.pressed.connect(_on_select)
	get_tree().paused = true


func _on_retry() -> void:
	get_tree().paused = false
	var current: String = get_tree().current_scene.scene_file_path
	TransitionManager.transition_to(current)


func _on_select() -> void:
	get_tree().paused = false
	TransitionManager.transition_to("res://scenes/level_select.tscn")