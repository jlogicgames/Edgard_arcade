class_name Firefly
extends Node2D

## Port of the reference's Firefly: a dot that flies a short bezier curve,
## then hides and repicks a spot, anywhere within `area`.
@export var area: Vector2 = Vector2(640.0, 360.0)
@export var firefly_color: Color = Color.BLACK

var _timer := 0.0
var _hide_time := 0.0
var _fly_time := 0.0
var _flying := false
var _start := Vector2.ZERO
var _end := Vector2.ZERO
var _control := Vector2.ZERO
var _radius := 2.0

func _ready() -> void:
	_start_hide()

func _process(delta: float) -> void:
	_timer += delta
	if _flying and _timer > _fly_time:
		_start_hide()
	elif not _flying and _timer > _hide_time:
		_start_fly()
	queue_redraw()

func _start_fly() -> void:
	_timer = 0.0
	_flying = true
	_fly_time = 3.0 + randf() * 4.0
	_start = Vector2(randf() * area.x, randf() * area.y)
	_control = _start + Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
	_end = _start + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	_radius = 2.0 + randf()

func _start_hide() -> void:
	_timer = 0.0
	_flying = false
	_hide_time = 1.0 + randf()

func _draw() -> void:
	if not _flying:
		return
	var t: float = clampf(_timer / _fly_time, 0.0, 1.0)
	var mt := 1.0 - t
	var pos: Vector2 = _start * (mt * mt) + _control * (2.0 * mt * t) + _end * (t * t)
	var alpha: float = t * 2.0 if t < 0.5 else (1.0 - t) * 2.0
	var col := firefly_color
	col.a = alpha
	draw_circle(pos, _radius, col)
