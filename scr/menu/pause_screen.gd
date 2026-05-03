extends CanvasLayer

## PauseScreen — пауза во время геймплея.
## Использует Basic_GUI_Bundle ассеты.
## process_mode = ALWAYS — работает при паузе.

@onready var _resume_button: Button = $Overlay/PanelCenter/VBoxContainer/ResumeButton
@onready var _retry_button: Button = $Overlay/PanelCenter/VBoxContainer/RetryButton
@onready var _select_button: Button = $Overlay/PanelCenter/VBoxContainer/SelectButton


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(_on_resume)
	_retry_button.pressed.connect(_on_retry)
	_select_button.pressed.connect(_on_select)


func show_pause() -> void:
	visible = true
	get_tree().paused = true


func _on_resume() -> void:
	get_tree().paused = false
	visible = false
	queue_free()


func _on_retry() -> void:
	get_tree().paused = false
	var current: String = get_tree().current_scene.scene_file_path
	TransitionManager.transition_to(current)


func _on_select() -> void:
	get_tree().paused = false
	TransitionManager.transition_to("res://scenes/level_select.tscn")