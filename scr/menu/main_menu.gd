extends Control

## MainMenu — главный экран игры.

@onready var _play_button: Button = $VBoxContainer/PlayButton


func _ready():
	_play_button.pressed.connect(_on_play_pressed)


func _on_play_pressed() -> void:
	TransitionManager.transition_to("res://scenes/level_select.tscn")