extends StaticBody2D

@export var target_id: String = ""
@export var wall_size: Vector2 = Vector2(16.0, 16.0)

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if target_id != "":
		add_to_group("actionable_" + target_id)
	var rect := RectangleShape2D.new()
	rect.size = wall_size
	shape.shape = rect
	# Spawn position is the Tiled object's top-left corner, but a collision
	# shape is centred on its own transform, so offset it by half the size.
	shape.position = wall_size * 0.5

func perform_action() -> void:
	set_deferred("disabled", not shape.disabled)
	visible = not visible
