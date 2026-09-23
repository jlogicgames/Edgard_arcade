extends Node2D

@export var intensity: int = 80
@export var target_id: String = ""

@onready var flame: CPUParticles2D = $FlameParticles
@onready var embers: CPUParticles2D = $EmberParticles
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	_setup_light()
	light.energy = intensity / 100.0
	flame.amount = maxi(4, intensity / 10)
	embers.amount = maxi(2, intensity / 20)
	if target_id != "":
		add_to_group("actionable_" + target_id)

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

func perform_action() -> void:
	flame.emitting = not flame.emitting
	embers.emitting = not embers.emitting
	light.visible = not light.visible
