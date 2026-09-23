extends Area2D

@export var checkpoint_size: Vector2 = Vector2(16, 32)

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = checkpoint_size
	shape.shape = rect
	# Spawn position is the Tiled object's top-left corner, but a collision
	# shape is centred on its own transform, so offset it by half the size.
	shape.position = checkpoint_size * 0.5
	color_rect.size = checkpoint_size
	color_rect.visible = GameManager.debug_draw
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# Invisible in the reference; only shown under the F1 debug toggle.
	color_rect.visible = GameManager.debug_draw

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player)._reached_checkpoint()
