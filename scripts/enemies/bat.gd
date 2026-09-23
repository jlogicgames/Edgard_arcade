class_name Bat
extends Area2D

@export var is_vertical: bool = false
@export var off_neg: float = 3.0
@export var off_pos: float = 3.0

const MOVE_SPEED := 50.0
const TILE_SIZE := 16.0

var range_neg: float
var range_pos: float
var move_dir: float = 1.0
var is_dead := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_zone: Area2D = $DetectionZone

func _ready() -> void:
	if is_vertical:
		range_neg = global_position.y - off_neg * TILE_SIZE
		range_pos = global_position.y + off_pos * TILE_SIZE
	else:
		range_neg = global_position.x - off_neg * TILE_SIZE
		range_pos = global_position.x + off_pos * TILE_SIZE
	sprite.play("idle")
	body_entered.connect(_on_player_entered)
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if is_vertical:
		position.y += move_dir * MOVE_SPEED * delta
		sprite.flip_v = move_dir > 0.0
		if global_position.y >= range_pos:
			move_dir = -1.0
		elif global_position.y <= range_neg:
			move_dir = 1.0
	else:
		position.x += move_dir * MOVE_SPEED * delta
		sprite.flip_h = move_dir < 0.0
		if global_position.x >= range_pos:
			move_dir = -1.0
		elif global_position.x <= range_neg:
			move_dir = 1.0

	sprite.play("run" if abs(move_dir) > 0.0 else "idle")

func _on_player_entered(body: Node2D) -> void:
	if body.has_method("take_hit"):
		body.take_hit()

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Player:
		Engine.time_scale = 0.5

func _on_detection_body_exited(body: Node2D) -> void:
	if body is Player:
		Engine.time_scale = 1.0

func get_hit() -> void:
	if is_dead:
		return
	is_dead = true
	Engine.time_scale = 1.0
	monitoring = false
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
