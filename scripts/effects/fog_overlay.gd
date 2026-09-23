class_name FogOverlay
extends CanvasLayer

var _time := 0.0

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	layer = 4
	var vp := get_viewport().get_visible_rect().size
	rect.size = vp
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_size", vp)

func _process(delta: float) -> void:
	_time += delta
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_time", _time)
