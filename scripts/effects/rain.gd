class_name Rain
extends Node2D

## Port of the reference's RainDrop: 48 falling line streaks that respawn
## above the camera once they land, sharing one random wind offset.
const DROP_COUNT := 48

@export var level_width: float = 640.0
@export var level_height: float = 360.0

class Drop:
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	var duration := 1.0
	var elapsed := 0.0

var _drops: Array[Drop] = []
var _wind: float = 0.0

func _ready() -> void:
	_wind = randf_range(-24.0, 24.0)
	for i in DROP_COUNT:
		var d := Drop.new()
		_start_rain(d)
		_drops.append(d)

func _camera_x() -> float:
	var player: Player = GameManager.player
	if player == null:
		return 0.0
	return player.camera.get_screen_center_position().x

func _start_rain(d: Drop) -> void:
	var x_start := randf() * level_width - level_width * 0.5 + _camera_x()
	d.start = Vector2(x_start, -20.0)
	d.end = Vector2(d.start.x + _wind, level_height + 40.0)
	var fall_distance := d.end.y - d.start.y
	var speed := 400.0 + randf() * 80.0
	d.duration = fall_distance / speed
	d.elapsed = 0.0

func _process(delta: float) -> void:
	for d in _drops:
		d.elapsed += delta
		if d.elapsed >= d.duration:
			_start_rain(d)
	queue_redraw()

func _draw() -> void:
	for d in _drops:
		var t: float = clampf(d.elapsed / d.duration, 0.0, 1.0)
		var pos: Vector2 = d.start.lerp(d.end, t)
		draw_rect(Rect2(pos.x - 0.6, pos.y - 7.0, 1.2, 14.0), Color.BLACK)
