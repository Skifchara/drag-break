extends Control

## UidDrawer — рисует точки коррекций.
## Жизни (сердца) — через HeartsRow в gameplay_ui.

var _ui: CanvasLayer


func _ready():
	_ui = get_parent()


func _draw():
	if not _ui:
		return

	_draw_dots_row(
		GameManager.corrections_remaining,
		GameManager.max_corrections,
		_ui.corrections_position_offset,
		_ui.correction_dot_radius,
		_ui.correction_dot_spacing,
		_ui.correction_dot_color,
		_ui.correction_dot_empty_color,
	)


func _draw_dots_row(
	current: int,
	maximum: int,
	offset: Vector2,
	radius: float,
	spacing: float,
	color_full: Color,
	color_empty: Color,
):
	for i in range(maximum):
		var x: float = offset.x + i * spacing
		var y: float = offset.y
		var c: Color = color_full if i < current else color_empty
		draw_circle(Vector2(x, y), radius, c)