extends StaticBody2D

## Сколько попаданий выдерживает блок (0 = бесконечно)
@export var hit_points: int = 1
## Прибавлять к счёту при уничтожении
@export var score_value: int = 10
## true — блок исчезает, false — только меняет цвет
@export var destroy_on_death: bool = true
## Цвета по убыванию HP (первый = полный HP, последний = 1 HP).
## Если пусто — генерируются автоматически от зелёного к красному
@export var hp_colors: Array[Color] = []

var _current_hp: int = 1
var _palette: Array[Color] = []


func _ready():
	_current_hp = hit_points
	add_to_group("blocks")
	_build_palette()
	_apply_color()


func _build_palette():
	if hp_colors.is_empty():
		_palette.clear()
		for i in range(hit_points):
			var t: float = float(i) / maxf(hit_points - 1, 1.0)
			var r: float = lerpf(0.3, 0.9, t)
			var g: float = lerpf(0.9, 0.2, t)
			var b: float = lerpf(0.3, 0.2, t)
			_palette.append(Color(r, g, b, 1.0))
		if _palette.is_empty():
			_palette.append(Color(0.5, 0.5, 0.5))
	else:
		_palette = hp_colors.duplicate()


func hit():
	_current_hp -= 1
	if _current_hp <= 0:
		_destroy()
	else:
		_apply_color()


func _apply_color():
	var sprite := $Sprite2D if has_node("Sprite2D") else null
	if sprite and sprite is Sprite2D and _palette.size() > 0:
		var taken: int = hit_points - _current_hp
		var idx: int = clampi(taken, 0, _palette.size() - 1)
		sprite.modulate = _palette[idx]


func _destroy():
	if destroy_on_death:
		queue_free()
	else:
		$CollisionShape2D.disabled = true
		hide()
