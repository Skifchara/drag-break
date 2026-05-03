extends Node

## AppTheme — autoload синглтон.
## Создаёт Theme с LazyFox Pixel Font 2 и применяет глобально.

const FONT_PATH: String = "res://LazyFox Pixel Font 2/LazyFox Pixel Font 2.ttf"
const DEFAULT_FONT_SIZE: int = 24
const LABEL_FONT_SIZE: int = 22
const BUTTON_FONT_SIZE: int = 28
const TITLE_FONT_SIZE: int = 48

var theme: Theme


func _ready():
	theme = _create_theme()
	# Применяем на viewport — все узлы наследуют
	get_tree().root.theme = theme


func _create_theme() -> Theme:
	var t := Theme.new()
	var font: FontFile = FontFile.new()
	font.font_data = load(FONT_PATH)

	# Default font
	t.default_font = font
	t.default_font_size = DEFAULT_FONT_SIZE

	# Label
	t.set_font("font", "Label", font)
	t.set_font_size("font_size", "Label", LABEL_FONT_SIZE)
	t.set_color("font_color", "Label", Color.WHITE)

	# Button
	t.set_font("font", "Button", font)
	t.set_font_size("font_size", "Button", BUTTON_FONT_SIZE)
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color(0.9, 0.95, 1.0))

	# Large button for menus
	t.set_font_size("font_size", "MenuButton", BUTTON_FONT_SIZE)

	return t