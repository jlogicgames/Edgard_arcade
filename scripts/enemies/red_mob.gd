class_name RedMob
extends CharacterBody2D

@export var off_neg: float = 5.0
@export var off_pos: float = 5.0

const RUN_SPEED := 80.0
const BOUNCE_HEIGHT := -260.0
const ATTACK_RANGE := 65.0
const TILE_SIZE := 16.0
const GRAVITY := 588.0

var range_neg: float
var range_pos: float
var move_dir: float = 1.0
var got_hit := false
var is_attacking := false
var is_returning := false
var spawn_x: float

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	spawn_x = global_position.x
	range_neg = global_position.x - off_neg * TILE_SIZE
	range_pos = global_position.x + off_pos * TILE_SIZE
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if got_hit or is_attacking or is_returning:
		return
	delta *= GameManager.level_time_scale
	sprite.speed_scale = GameManager.level_time_scale

	if not is_on_floor():
		velocity.y = min(velocity.y + GRAVITY * delta, 300.0)

	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and _is_player_in_range(player):
		var dx: float = abs(player.global_position.x - global_position.x)
		if dx < ATTACK_RANGE:
			_start_attack()
			return
		var dir: float = sign(player.global_position.x - global_position.x)
		move_dir = lerpf(move_dir, dir, 0.1)
		velocity.x = move_dir * RUN_SPEED * GameManager.level_time_scale
	else:
		velocity.x = 0.0

	sprite.flip_h = move_dir < 0.0
	move_and_slide()
	sprite.play("run" if abs(velocity.x) > 1.0 else "idle")
	_check_player_contact()

func _is_player_in_range(player: Player) -> bool:
	return player.global_position.x >= range_neg \
		and player.global_position.x <= range_pos \
		and player.global_position.y + 32.0 > global_position.y \
		and player.global_position.y < global_position.y + 32.0

func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	sprite.play("attack")
	# Reference deals damage on every frame of the attack, not once.
	while sprite.animation == "attack" and sprite.is_playing():
		_check_attack_damage()
		await get_tree().physics_frame
	is_attacking = false
	await _return_to_spawn()
	sprite.play("idle")

func _check_attack_damage() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and _is_player_in_range(player):
		var dx: float = abs(player.global_position.x - global_position.x)
		if dx < ATTACK_RANGE:
			player.take_hit()

func _return_to_spawn() -> void:
	if got_hit:
		return
	is_returning = true
	sprite.play("run")
	while not got_hit and absf(global_position.x - spawn_x) > 2.0:
		var dir := signf(spawn_x - global_position.x)
		sprite.flip_h = dir < 0.0
		velocity.x = dir * RUN_SPEED * GameManager.level_time_scale
		if not is_on_floor():
			velocity.y = min(velocity.y + GRAVITY * get_physics_process_delta_time(), 300.0)
		move_and_slide()
		_check_player_contact()
		await get_tree().physics_frame
	velocity.x = 0.0
	is_returning = false

func _check_player_contact() -> void:
	if got_hit:
		return
	for body in hurtbox.get_overlapping_bodies():
		if body is Player:
			var player := body as Player
			if player.velocity.y > 0.0 and player.global_position.y < global_position.y:
				player.velocity.y = BOUNCE_HEIGHT
				_get_hit()
			else:
				player.take_hit()
			return

func get_hit() -> void:
	_get_hit()

func _get_hit() -> void:
	if got_hit:
		return
	got_hit = true
	is_attacking = false
	is_returning = false
	GameManager.play_sfx("res://assets/sounds/bounce.wav")
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
