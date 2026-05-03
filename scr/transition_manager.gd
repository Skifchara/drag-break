extends CanvasLayer

## TransitionManager — autoload синглтон для переходов между сценами.
##
## Использование:
##   TransitionManager.transition_to("res://scenes/main_menu.tscn")
##
## Переход: factor 0→1 (затемнение) → смена сцены → factor 1→0 (раскрытие)
## Tween'ы работают даже при paused=true (process_mode = ALWAYS)

signal transition_finished

@export var transition_duration: float = 0.4
@export var base_color: Color = Color.BLACK
@export var shape_tiling: float = 32.0
@export var shape_feathering: float = 0.08

var _is_transitioning: bool = false
var _shader_mat: ShaderMaterial
var _color_rect: ColorRect


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Шейдер
	var shader: Shader = load("res://Godot Modular Transitions/shader/transition.gdshader")
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader

	# Линейный градиент (слева направо)
	var grad_tex := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0, 0, 0, 1), Color(1, 1, 1, 1)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad_tex.gradient = grad
	grad_tex.fill = 0  # FILL_HORIZONTAL
	grad_tex.fill_from = Vector2(0, 0.5)
	grad_tex.fill_to = Vector2(1, 0.5)
	grad_tex.width = 256
	grad_tex.height = 256
	_shader_mat.set_shader_parameter("gradient_texture", grad_tex)
	_shader_mat.set_shader_parameter("gradient_fixed", false)

	# Shape-текстура: кружки
	var shape_img := Image.create(64, 64, false, Image.FORMAT_L8)
	var shape_data := PackedByteArray()
	shape_data.resize(64 * 64)
	for y in range(64):
		for x in range(64):
			var dx: float = (x - 32) / 32.0
			var dy: float = (y - 32) / 32.0
			var dist: float = sqrt(dx * dx + dy * dy)
			var val: int = 255 if dist <= 0.45 else 0
			shape_data[y * 64 + x] = val
	shape_img.set_data(64, 64, false, Image.FORMAT_L8, shape_data)
	var shape_tex := ImageTexture.create_from_image(shape_img)
	_shader_mat.set_shader_parameter("shape_texture", shape_tex)

	_shader_mat.set_shader_parameter("shape_tiling", shape_tiling)
	_shader_mat.set_shader_parameter("shape_rotation", 0.0)
	_shader_mat.set_shader_parameter("shape_scroll", Vector2(0, 0))
	_shader_mat.set_shader_parameter("shape_feathering", shape_feathering)
	_shader_mat.set_shader_parameter("shape_treshold", 1.0)
	_shader_mat.set_shader_parameter("base_color", base_color)
	_shader_mat.set_shader_parameter("factor", 0.0)

	# ColorRect на весь экран
	_color_rect = ColorRect.new()
	_color_rect.material = _shader_mat
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.visible = false
	add_child(_color_rect)

	set_process(false)


func transition_to(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_color_rect.visible = true
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

	# Снимаем паузу ДО начала перехода — чтобы Tween работал
	get_tree().paused = false

	# Фаза 1: затемнение (factor 0→1)
	var tween1 := create_tween()
	tween1.tween_method(_set_factor, 0.0, 1.0, transition_duration)
	tween1.tween_callback(_on_covered.bind(scene_path))


func _set_factor(val: float) -> void:
	_shader_mat.set_shader_parameter("factor", val)


func _on_covered(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame

	# Фаза 2: раскрытие (factor 1→0)
	var tween2 := create_tween()
	tween2.tween_method(_set_factor, 1.0, 0.0, transition_duration)
	tween2.tween_callback(_on_uncovered)


func _on_uncovered() -> void:
	_color_rect.visible = false
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	set_process(false)
	transition_finished.emit()