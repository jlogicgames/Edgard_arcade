class_name BombExplosionEffect
extends Node2D

@export var duration: float = 0.7
@export var explosion_size: float = 64.0

var _elapsed := 0.0

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	rect.size = Vector2(explosion_size, explosion_size)
	rect.position = -rect.size * 0.5
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_size", rect.size)

func _process(delta: float) -> void:
	_elapsed += delta
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_time", _elapsed)
	mat.set_shader_parameter("u_progress", clampf(_elapsed / duration, 0.0, 1.0))
	if _elapsed >= duration:
		queue_free()
