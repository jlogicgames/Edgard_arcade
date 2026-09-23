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

func _ready() -> void:
	add_to_group("bat")
	if is_vertical:
		range_neg = global_position.y - off_neg * TILE_SIZE
		range_pos = global_position.y + off_pos * TILE_SIZE
	else:
		range_neg = global_position.x - off_neg * TILE_SIZE
		range_pos = global_position.x + off_pos * TILE_SIZE
	sprite.play("idle")
	body_entered.connect(_on_player_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	delta *= GameManager.level_time_scale
	sprite.speed_scale = GameManager.level_time_scale
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
	if is_dead:
		return
	if body is Player:
		var player := body as Player
		if player.velocity.y > 0.0 and player.global_position.y < global_position.y:
			get_hit()
			return
	if body.has_method("take_hit"):
		body.take_hit()

func get_hit() -> void:
	if is_dead:
		return
	is_dead = true
	monitoring = false
	GameManager.play_sfx("res://assets/sounds/bounce.wav")
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
