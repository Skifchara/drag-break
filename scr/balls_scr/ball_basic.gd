extends RigidBody2D

enum State { IDLE, AIMING, FLYING, SLOWMO }

# ═══════════════════════════════════════════════
#  LAUNCH SETTINGS — всё в инспекторе
# ═══════════════════════════════════════════════

@export_group("Launch Settings")
## Сила выстрела (пиксели/сек)
@export var launch_power: float = 1500.0
## Макс. дистанция перетаскивания для пуска
@export var max_drag_distance: float = 400.0
## Мин. доля от launch_power (чтобы слабый дёрг не давал 0)
@export var min_launch_force_ratio: float = 0.15

@export_group("Correction (Slow-Mo)")
## Множитель времени в slow-mo
@export var slow_mo_scale: float = 0.05
## Сила корректирующего толчка
@export var correction_power: float = 1500.0
## Секунд кулдауна между slow-mo активациями
@export var slow_mo_cooldown: float = 1.5

@export_group("Trajectory Preview")
## Цвет начала предпоказа (максимальная альфа)
@export var preview_color_start: Color = Color(0.3, 0.8, 1.0, 0.8)
## Цвет конца предпоказа (альфа = 0 при fade)
@export var preview_color_end: Color = Color(0.3, 0.8, 1.0, 0.0)
## Цвет текущей траектории в slow-mo (фоновая)
@export var preview_current_color: Color = Color(1, 1, 1, 0.12)
## Толщина линии предпоказа
@export var preview_line_width: float = 4.0
## Радиус точек на траектории
@export var preview_dot_radius: float = 3.5
## Макс. шагов симуляции (качество кривой)
@export var preview_max_steps: int = 60
## Шаг времени на один шаг симуляции (сек)
@export var preview_step_dt: float = 0.025
## Лимит времени симуляции (сек) — насколько вперёд показывать
@export var preview_time_limit: float = 1.8

@export_group("Physics")
## gravity_scale во время полёта
@export var flight_gravity: float = 0.5

@export_group("Reset Bounds")
@export var reset_top: float = -200.0
@export var reset_bottom: float = 2100.0
@export var reset_left: float = -200.0
@export var reset_right: float = 1280.0

@export_group("Proximity")
## Радиус, в котором клик считается "по мячу" для запуска
@export var grab_radius: float = 200.0

@export_group("Ball Scale & Physics")
## Масштаб шарика (визуал + коллизия + кольцо)
@export var ball_scale: float = 1.0:
	set(v):
		ball_scale = v
		if is_inside_tree():
			_apply_ball_scale()
## Прыгучесть шарика (bounce)
@export var ball_bounce: float = 0.8:
	set(v):
		ball_bounce = v
		if is_inside_tree():
			_apply_bounce()

@export_group("Ring Indicator")
## Минимальный масштаб кольца при сильном натяжении
@export var ring_min_scale: float = 0.3
## Чувствительность сжатия кольца к дистанции драга
@export var ring_compress_speed: float = 2.0

# ═══════════════════════════════════════════════
#  STATE
# ═══════════════════════════════════════════════

var _state: State = State.IDLE
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _initial_pos: Vector2 = Vector2.ZERO
var _slow_mo_cooldown_timer: float = 0.0
var _trajectory: PackedVector2Array = []       # коррекция / запуск
var _current_traj: PackedVector2Array = []     # текущая траектория (slow-mo фон)
var _gravity_2d: float = 980.0

# ── Ring Indicator ──────────────────────────────
@onready var _ring_container: Node2D = $RingContainer
@onready var _ring_indicator: Node2D = $RingContainer/RingIndicator
@onready var _ring_anim: AnimationPlayer = $RingContainer/AnimationPlayer
var _ring_pull_idle_running: bool = false
var _ring_wobble_started: bool = false
var _virtual_drag: bool = false
var _base_collision_radius: float = 48.0
var _base_ring_radius: float = 56.0

# ── Scale helpers ────────────────────────────────
@onready var _ball_sprite: Sprite2D = $Sprite2D
@onready var _ball_collision: CollisionShape2D = $CollisionShape2D


func _ready():
	_state = State.IDLE
	gravity_scale = 0.0
	freeze = true
	_initial_pos = global_position
	body_entered.connect(_on_body_entered)
	_gravity_2d = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	_apply_bounce()
	_apply_ball_scale()


func _input(event: InputEvent):
	match _state:
		State.IDLE, State.AIMING:
			_handle_idle_aim_input(event)
		State.FLYING:
			_handle_flying_input(event)
		State.SLOWMO:
			_handle_slowmo_input(event)


# ── IDLE / AIMING: slingshot + кривая предпоказа ─

func _handle_idle_aim_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_near_ball(get_global_mouse_position()):
			_state = State.AIMING
			_drag_start = global_position
			_drag_current = get_global_mouse_position()
			_dragging = true
			_update_trajectory()
			queue_redraw()
		elif _dragging:
			_dragging = false
			_launch()

	if event is InputEventMouseMotion and _dragging and _state == State.AIMING:
		_drag_current = get_global_mouse_position()
		_update_trajectory()
		queue_redraw()


# ── FLYING: ЛКМ (в любом месте) → slow-mo ──────

func _handle_flying_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _slow_mo_cooldown_timer <= 0.0:
			var mouse_pos := get_global_mouse_position()
			_virtual_drag = not _is_near_ball(mouse_pos)
			_state = State.SLOWMO
			Engine.time_scale = slow_mo_scale
			if _virtual_drag:
				_drag_start = mouse_pos           # виртуальная точка привязки
			else:
				_drag_start = global_position      # захват за мяч
			_drag_current = mouse_pos
			_dragging = true
			_ring_wobble_started = false
			_ring_container.scale = Vector2(1, 1)
			_ring_indicator.modulate = Color(0, 1, 0.3, 0.9)
			_update_trajectory()
			_simulate_current()
			queue_redraw()
		elif event.pressed and _slow_mo_cooldown_timer > 0.0:
			_ring_deny()


# ── SLOWMO: drag & pull slingshot + отпускание → коррекция + выход ─

func _handle_slowmo_input(event: InputEvent):
	if event is InputEventMouseMotion and _dragging:
		_drag_current = get_global_mouse_position()
		_update_trajectory()
		_ring_compress(_drag_start.distance_to(_drag_current))
		if not _ring_wobble_started:
			_ring_wobble_started = true
			_ring_drag_start()
		queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if _dragging:
				_dragging = false
				_apply_correction()
				_ring_release()
			_exit_slow_mo()


# ── Симуляция траектории ────────────────────────

func _gravity() -> float:
	return _gravity_2d * flight_gravity


# ── Ball scale & bounce ─────────────────────────

func _apply_ball_scale():
	# Масштаб спрайта
	if _ball_sprite:
		_ball_sprite.scale = Vector2(0.05 * ball_scale, 0.05 * ball_scale)
	# Масштаб коллизии
	if _ball_collision and _ball_collision.shape is CircleShape2D:
		_ball_collision.shape.radius = _base_collision_radius * ball_scale
	# Масштаб кольца
	if _ring_indicator:
		_ring_indicator.call("set_radius", _base_ring_radius * ball_scale)
	# Масштаб контейнера кольца сбрасываем (анимации работают относительно него)
	if _ring_container:
		_ring_container.scale = Vector2(1, 1)


func _apply_bounce():
	if physics_material_override:
		physics_material_override.bounce = ball_bounce
	else:
		var mat := PhysicsMaterial.new()
		mat.bounce = ball_bounce
		physics_material_override = mat


# ── Ring Indicator Control ──────────────────────

func _ring_show_available():
	if not _ring_container or not _ring_anim:
		return
	_ring_container.visible = true
	_ring_anim.play("show")


func _ring_drag_start():
	if not _ring_anim:
		return
	_ring_anim.play("pull_wobble")
	_ring_pull_idle_running = false


func _ring_compress(dist: float):
	if not _ring_container:
		return
	var ratio: float = clampf(dist / max_drag_distance, 0.0, 1.0)
	var s: float = 1.0 - ratio * (1.0 - ring_min_scale)
	_ring_container.scale = Vector2(s, s)


func _ring_release():
	if not _ring_indicator or not _ring_anim:
		return
	_ring_anim.stop()
	_ring_indicator.rotation = 0.0
	_ring_container.scale = Vector2(1, 1)
	_ring_wobble_started = false
	_ring_anim.play("release")


func _ring_hide():
	if not _ring_anim or not _ring_container:
		return
	_ring_anim.stop()
	_ring_indicator.scale = Vector2(1, 1)
	_ring_indicator.rotation = 0.0
	_ring_container.scale = Vector2(1, 1)
	_ring_anim.play("hide")
	_ring_container.visible = false


func _ring_deny():
	"""Красная вспышка + спазм кольца при попытке коррекции во время кулдауна"""
	if not _ring_anim or not _ring_container:
		return
	if not _ring_container.visible:
		_ring_container.visible = true
	_ring_anim.stop()
	_ring_container.scale = Vector2(1, 1)
	_ring_anim.play("deny")


func _ring_ready():
	"""Быстрый зелёный пульс — кулдаун кончился"""
	if not _ring_anim or not _ring_container:
		return
	if not _ring_container.visible:
		_ring_container.visible = true
	_ring_anim.stop()
	_ring_container.scale = Vector2(1, 1)
	_ring_anim.play("ready")


func _update_trajectory():
	var dir: Vector2 = (_drag_start - _drag_current)   # slingshot: противоположное направление
	if dir.length_squared() < 1.0:
		_trajectory.clear()
		return
	dir = dir.normalized()
	var dist: float = clampf(_drag_start.distance_to(_drag_current), 0.0, max_drag_distance)
	var force_ratio: float = maxf(dist / max_drag_distance, min_launch_force_ratio)
	var power: float = correction_power if _state == State.SLOWMO else launch_power
	var speed: float = force_ratio * power
	_trajectory = _simulate(global_position, dir * speed)


func _simulate_current():
	if linear_velocity.length_squared() < 1.0:
		_current_traj.clear()
		return
	_current_traj = _simulate(global_position, linear_velocity)


func _simulate(start_pos: Vector2, start_vel: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var grav: float = _gravity()
	var pos: Vector2 = start_pos
	var vel: Vector2 = start_vel
	var elapsed: float = 0.0
	out.append(pos)
	for i in range(preview_max_steps):
		elapsed += preview_step_dt
		if elapsed > preview_time_limit:
			break
		vel.y += grav * preview_step_dt
		pos += vel * preview_step_dt
		out.append(pos)
	return out


# ── Коррекция (drag & pull slingshot) ───────────

func _apply_correction():
	var dir: Vector2 = (_drag_start - _drag_current)
	if dir.length_squared() < 5.0:
		return
	dir = dir.normalized()
	var dist: float = clampf(_drag_start.distance_to(_drag_current), 0.0, max_drag_distance)
	var force_ratio: float = maxf(dist / max_drag_distance, min_launch_force_ratio)
	linear_velocity = dir * (force_ratio * correction_power)


func _exit_slow_mo():
	Engine.time_scale = 1.0
	_state = State.FLYING
	_slow_mo_cooldown_timer = slow_mo_cooldown
	_clear_previews()
	_ring_show_available()
	queue_redraw()


# ── Запуск (drag & pull slingshot) ──────────────

func _launch():
	var dir: Vector2 = (_drag_start - _drag_current)
	if dir.length_squared() < 1.0:
		_state = State.IDLE
		_clear_previews()
		queue_redraw()
		return
	dir = dir.normalized()
	var dist: float = clampf(_drag_start.distance_to(_drag_current), 0.0, max_drag_distance)
	var force_ratio: float = maxf(dist / max_drag_distance, min_launch_force_ratio)
	_state = State.FLYING
	gravity_scale = flight_gravity
	freeze = false
	linear_velocity = dir * (force_ratio * launch_power)
	_slow_mo_cooldown_timer = 0.0
	_clear_previews()
	_ring_show_available()
	queue_redraw()


func _reset_to_idle():
	Engine.time_scale = 1.0
	_state = State.IDLE
	freeze = true
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	global_position = _initial_pos
	_slow_mo_cooldown_timer = 0.0
	_dragging = false
	_virtual_drag = false
	_clear_previews()
	_ring_hide()
	queue_redraw()


func _clear_previews():
	_trajectory.clear()
	_current_traj.clear()


func _is_near_ball(pos: Vector2) -> bool:
	return global_position.distance_to(pos) < grab_radius


# ── Отрисовка кривой траектории ─────────────────

func _draw():
	# Компенсируем вращение RigidBody2D — траектория всегда прямо
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)

	# Фоновая текущая траектория (только в SLOWMO)
	if _current_traj.size() >= 2:
		_draw_trajectory(_current_traj, preview_current_color, preview_current_color)

	# Основная траектория (запуск или коррекция) с градиентом
	if _trajectory.size() >= 2:
		for i in range(_trajectory.size() - 1):
			var t: float = float(i) / float(_trajectory.size() - 1)
			var c: Color = preview_color_start.lerp(preview_color_end, t)
			var p1: Vector2 = _trajectory[i] - global_position
			var p2: Vector2 = _trajectory[i + 1] - global_position
			draw_line(p1, p2, c, preview_line_width, true)
			var dot_r: float = preview_dot_radius * (1.0 - t * 0.6)
			draw_circle(p2, maxf(dot_r, 1.0), c)


func _draw_trajectory(traj: PackedVector2Array, c_start: Color, c_end: Color):
	for i in range(traj.size() - 1):
		var t: float = float(i) / float(traj.size() - 1)
		var c: Color = c_start.lerp(c_end, t)
		var p1: Vector2 = traj[i] - global_position
		var p2: Vector2 = traj[i + 1] - global_position
		draw_line(p1, p2, c, preview_line_width * 0.5, true)


# ── Столкновения ────────────────────────────────

func _on_body_entered(body: Node):
	if body.is_in_group("blocks"):
		var block = body as StaticBody2D
		if block and block.has_method("hit"):
			block.hit()


func _physics_process(delta: float):
	var was_on_cooldown: bool = _slow_mo_cooldown_timer > 0.0
	if _slow_mo_cooldown_timer > 0.0:
		_slow_mo_cooldown_timer -= delta * Engine.time_scale
		if _slow_mo_cooldown_timer < 0.0:
			_slow_mo_cooldown_timer = 0.0
	if was_on_cooldown and _slow_mo_cooldown_timer <= 0.0:
		_ring_ready()

	if _state == State.IDLE or _state == State.AIMING:
		return

	if global_position.y > reset_bottom or global_position.y < reset_top \
		or global_position.x < reset_left or global_position.x > reset_right:
		_reset_to_idle()
