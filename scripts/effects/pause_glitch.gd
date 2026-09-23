class_name PauseGlitch
extends CanvasLayer

# T1: chromatic-aberration glitch shown only while paused, above the world
# and sky (default canvas + layer -1) and below the HUD (10) and pause menu
# (20). process_mode ALWAYS keeps its idle shake animating while the tree
# itself is paused.
const INTENSITY := 1.0
const SHIFT := 0.01

var _time := 0.0

@onready var rect: ColorRect = $ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	visible = false
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_intensity", INTENSITY)
	mat.set_shader_parameter("u_shift", SHIFT)

func _process(delta: float) -> void:
	visible = get_tree().paused
	if not visible:
		return
	_time += delta
	var mat := rect.material as ShaderMaterial
	mat.set_shader_parameter("u_time", _time)
