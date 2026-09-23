class_name Player
extends CharacterBody2D

signal life_lost(lives_remaining: int)
signal died
signal checkpoint_reached

const WALK_SPEED := 100.0
const JUMP_FORCE := -260.0
const TERMINAL_VELOCITY := 300.0
const COYOTE_TIME := 0.15
const FALL_OFF_Y := 350.0

var lives := 3
var is_attacking := false
var is_got_hit := false
var is_reached_checkpoint := false
var is_facing_right := true
var is_clambering := false
var is_wall_jumping := false
var coyote_timer := 0.0
var was_on_floor := false
var starting_position := Vector2.ZERO
var current_trigger_id := ""
var is_in_quicksand := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var sfx: AudioStreamPlayer = $AudioStreamPlayer
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	starting_position = global_position
	attack_hitbox.monitoring = false
	add_to_group("player")
	attack_hitbox.area_entered.connect(func(area: Area2D) -> void:
		if area.has_method("get_hit"): area.get_hit())
	attack_hitbox.body_entered.connect(func(body: Node2D) -> void:
		if body.has_method("get_hit"): body.get_hit())

func _physics_process(delta: float) -> void:
	_handle_pause()
	if is_got_hit or is_reached_checkpoint:
		move_and_slide()
		return

	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_movement()
	_handle_jump()
	_handle_attack()
	_handle_interact()
	move_and_slide()
	_clamp_velocity()
	_check_fall_off()
	_check_falling_platforms()
	_update_animation()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 588.0 * delta
		if is_clambering:
			velocity.y *= 0.1
		var term_vel := 30.0 if is_in_quicksand else TERMINAL_VELOCITY
		velocity.y = minf(velocity.y, term_vel)

func _handle_coyote(delta: float) -> void:
	if is_on_floor():
		coyote_timer = 0.0
	elif was_on_floor and velocity.y >= 0.0:
		# Just left the floor by walking off (not jumping up) — start coyote window
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = maxf(coyote_timer - delta, 0.0)
	was_on_floor = is_on_floor()

func _handle_movement() -> void:
	if is_wall_jumping:
		return
	var dir := Input.get_axis("move_left", "move_right")
	var speed_mul := 0.1 if (is_in_quicksand and not is_on_floor()) else 1.0
	velocity.x = dir * WALK_SPEED * speed_mul
	if dir > 0.0:
		is_facing_right = true
		sprite.flip_h = false
	elif dir < 0.0:
		is_facing_right = false
		sprite.flip_h = true

func _handle_jump() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if is_on_floor() or coyote_timer > 0.0 or is_in_quicksand:
		velocity.y = JUMP_FORCE
		coyote_timer = 0.0
		sfx.stream = load("res://assets/sounds/jump.wav")
		sfx.play()
	elif is_clambering:
		_do_wall_jump()

func _do_wall_jump() -> void:
	is_wall_jumping = true
	velocity.y = JUMP_FORCE * 0.7
	velocity.x = WALK_SPEED * 3.0 * (1.0 if not is_facing_right else -1.0)
	get_tree().create_timer(0.1).timeout.connect(func(): is_wall_jumping = false)

func _handle_attack() -> void:
	if is_attacking:
		return
	if Input.is_action_just_pressed("attack"):
		_start_attack()

func _start_attack() -> void:
	is_attacking = true
	sprite.play("attacking")
	attack_hitbox.position.x = 28.0 if is_facing_right else 20.0
	attack_hitbox.monitoring = true
	await sprite.animation_finished
	attack_hitbox.monitoring = false
	is_attacking = false

func _handle_interact() -> void:
	if Input.is_action_just_pressed("interact") and current_trigger_id != "":
		get_tree().call_group("actionable_" + current_trigger_id, "perform_action")

func _handle_pause() -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		GameManager.toggle_pause()

func _clamp_velocity() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	is_clambering = is_on_wall() and not is_on_floor() and velocity.y >= 0.0 and absf(dir) > 0.1

func _check_fall_off() -> void:
	if global_position.y > FALL_OFF_Y:
		_respawn()

func _check_falling_platforms() -> void:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null:
			continue
		if col.get_normal().y < -0.5:
			var collider := col.get_collider()
			if collider != null and collider.has_method("trigger_fall"):
				collider.trigger_fall()

func _update_animation() -> void:
	if is_attacking:
		return
	if is_clambering:
		sprite.play("climbing")
	elif is_in_quicksand:
		sprite.play("idle")
	elif not is_on_floor():
		if velocity.y < 0.0:
			sprite.play("jumping")
		else:
			sprite.play("falling")
	elif abs(velocity.x) > 1.0:
		sprite.play("running")
	else:
		sprite.play("idle")

func take_hit() -> void:
	if is_got_hit or is_reached_checkpoint:
		return
	_respawn()

func _respawn() -> void:
	if is_got_hit:
		return
	is_got_hit = true
	is_in_quicksand = false
	velocity = Vector2.ZERO
	sfx.stream = load("res://assets/sounds/hurt.wav")
	sfx.play()
	lives -= 1
	emit_signal("life_lost", lives)
	sprite.play("hit")
	await sprite.animation_finished
	if lives <= 0:
		emit_signal("died")
		return
	global_position = starting_position
	sprite.play("appearing")
	await sprite.animation_finished
	is_got_hit = false
	sprite.play("idle")

func _reached_checkpoint() -> void:
	if is_reached_checkpoint:
		return
	is_reached_checkpoint = true
	velocity = Vector2.ZERO
	GameManager.play_sfx("res://assets/sounds/disappear.wav")
	sprite.play("disappearing")
	await get_tree().create_timer(3.0).timeout
	emit_signal("checkpoint_reached")

func set_level_camera_limits(level_width: int) -> void:
	camera.limit_right = level_width
