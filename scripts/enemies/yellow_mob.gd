class_name YellowMob
extends CharacterBody2D

@export var off_neg: float = 5.0
@export var off_pos: float = 5.0

const RUN_SPEED := 80.0
const BOUNCE_HEIGHT := -260.0
const TILE_SIZE := 16.0
const GRAVITY := 588.0

var range_neg: float
var range_pos: float
var move_dir: float = 1.0
var got_hit := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	range_neg = global_position.x - off_neg * TILE_SIZE
	range_pos = global_position.x + off_pos * TILE_SIZE
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if got_hit:
		return
	delta *= GameManager.level_time_scale
	sprite.speed_scale = GameManager.level_time_scale

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 300.0)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and _is_player_in_range(player):
		var dir: float = sign(player.global_position.x - global_position.x)
		move_dir = lerpf(move_dir, dir, 0.1)
	else:
		if global_position.x >= range_pos:
			move_dir = -1.0
		elif global_position.x <= range_neg:
			move_dir = 1.0

	velocity.x = move_dir * RUN_SPEED * GameManager.level_time_scale
	sprite.flip_h = move_dir < 0.0
	move_and_slide()
	sprite.play("run" if abs(velocity.x) > 1.0 else "idle")
	_check_stomp(player)

func _is_player_in_range(player: Player) -> bool:
	return player.global_position.x >= range_neg \
		and player.global_position.x <= range_pos \
		and player.global_position.y + 32.0 > global_position.y \
		and player.global_position.y < global_position.y + 32.0

func _check_stomp(player: Player) -> void:
	if not player:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_collider() == player:
			if player.velocity.y > 0.0 and player.global_position.y < global_position.y:
				player.velocity.y = BOUNCE_HEIGHT
				_get_hit()
				return
			else:
				player.take_hit()

func get_hit() -> void:
	_get_hit()

func _get_hit() -> void:
	if got_hit:
		return
	got_hit = true
	GameManager.play_sfx("res://assets/sounds/bounce.wav")
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
