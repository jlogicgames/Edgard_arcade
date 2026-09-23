class_name Torch
extends Node2D

@export var intensity: int = 0
@export var target_id: String = ""

@onready var flame: CPUParticles2D = $FlameParticles
@onready var embers: CPUParticles2D = $EmberParticles
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	_setup_light()
	if target_id != "":
		add_to_group("actionable_" + target_id)
	# Intensity 0 or absent starts unlit; a burning torch keeps its own
	# Tiled-authored intensity until something toggles it (see set_lit).
	_apply_intensity()

func _setup_light() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.85, 0.4, 1.0), Color(1.0, 0.4, 0.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	light.texture = tex
	light.texture_scale = 3.0

func _apply_intensity() -> void:
	var lit := intensity > 0
	flame.emitting = lit
	embers.emitting = lit
	light.visible = lit
	light.energy = intensity / 100.0
	flame.amount = maxi(4, intensity / 10)
	embers.amount = maxi(2, intensity / 20)

## Matches the reference's toggleFire: jumps straight to 0 or 200,
## regardless of the torch's original authored intensity.
func set_lit(lit: bool) -> void:
	intensity = 200 if lit else 0
	_apply_intensity()

func perform_action() -> void:
	set_lit(intensity == 0)
