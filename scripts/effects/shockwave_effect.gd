class_name ShockwaveEffect
extends Node2D

@export var duration: float = 0.6
@export var max_radius: float = 64.0
@export var ring_width: float = 8.0
@export var color: Color = Color(1.0, 0.949, 0.698)

var _elapsed := 0.0

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	rect.size = Vector2(max_radius, max_radius) * 2.0
	rect.position = -rect.size * 0.5
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_size", rect.size)
	mat.set_shader_parameter("u_width", ring_width / (max_radius * 2.0))
	mat.set_shader_parameter("u_color", Vector3(color.r, color.g, color.b))

func _process(delta: float) -> void:
	_elapsed += delta
	var progress: float = clampf(_elapsed / duration, 0.0, 1.0)
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_time", _elapsed)
	mat.set_shader_parameter("u_progress", progress)
	if _elapsed >= duration:
		queue_free()
