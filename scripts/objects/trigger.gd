extends Area2D

@export var target_id: String = ""
@export var trigger_size: Vector2 = Vector2(16, 32)

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = trigger_size
	shape.shape = rect
	# Spawn position is the Tiled object's top-left corner, but a collision
	# shape is centred on its own transform, so offset it by half the size.
	shape.position = trigger_size * 0.5
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).current_trigger_id = target_id

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if (body as Player).current_trigger_id == target_id:
			(body as Player).current_trigger_id = ""
