class_name Escalator
extends AnimatableBody2D

@export var is_vertical: bool = false
@export var off_neg: float = 0.0
@export var off_pos: float = 0.0

const MOVE_SPEED := 50.0
const TILE_SIZE := 32.0

var range_neg: float
var range_pos: float
var move_dir: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	if is_vertical:
		range_neg = global_position.y - off_neg * TILE_SIZE
		range_pos = global_position.y + off_pos * TILE_SIZE
	else:
		range_neg = global_position.x - off_neg * TILE_SIZE
		range_pos = global_position.x + off_pos * TILE_SIZE
	sprite.play("run")

func _physics_process(delta: float) -> void:
	var motion := Vector2.ZERO
	if is_vertical:
		if global_position.y >= range_pos:
			move_dir = -1
		elif global_position.y <= range_neg:
			move_dir = 1
		motion.y = move_dir * MOVE_SPEED * delta
	else:
		if global_position.x >= range_pos:
			move_dir = -1
		elif global_position.x <= range_neg:
			move_dir = 1
		motion.x = move_dir * MOVE_SPEED * delta
	move_and_collide(motion)
