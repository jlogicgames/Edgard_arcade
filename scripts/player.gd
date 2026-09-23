class_name Player
extends CharacterBody2D

signal life_lost(lives_remaining: int)
signal died
signal checkpoint_reached

const WALK_SPEED := 100.0
const JUMP_FORCE := -260.0
const TERMINAL_VELOCITY := 300.0
const COYOTE_TIME := 0.15
const FALL_OFF_Y := 380.0
const WALL_JUMP_VY := JUMP_FORCE * 0.7
const WALL_JUMP_VX := 130.0
const CAMERA_LOOKAHEAD_SPEED := 1400.0
const CAMERA_OFFSET_RIGHT := 107.0
const CAMERA_OFFSET_LEFT := -113.0

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

	_update_camera_lookahead(delta)
	delta *= GameManager.level_time_scale
	sprite.speed_scale = GameManager.level_time_scale
	_apply_gravity(delta)
	_handle_coyote(delta)
	_handle_movement()
	_handle_jump()
	_handle_attack()
	_handle_interact()
	move_and_slide()
	_update_wall_clamber()
	_check_fall_off()
	_check_falling_platforms()
	_update_animation()

func _apply_gravity(delta: float) -> void:
	if is_in_quicksand:
		# Reference treats quicksand as ground: no sinking, no gravity.
		velocity.y = 0.0
		return
	if not is_on_floor():
		velocity.y += 588.0 * delta
		if is_clambering:
			velocity.y *= 0.1
		velocity.y = minf(velocity.y, TERMINAL_VELOCITY)

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
	if is_wall_jumping or is_attacking:
		velocity.x = 0.0
		return
	var dir := Input.get_axis("move_left", "move_right")
	var speed_mul := 0.1 if is_in_quicksand else 1.0
	velocity.x = dir * WALK_SPEED * speed_mul * GameManager.level_time_scale
	if dir > 0.0:
		is_facing_right = true
		sprite.flip_h = false
	elif dir < 0.0:
		is_facing_right = false
		sprite.flip_h = true

func _handle_jump() -> void:
	var grounded := is_on_floor() or coyote_timer > 0.0 or is_in_quicksand
	if Input.is_action_pressed("jump") and grounded:
		velocity.y = JUMP_FORCE * (0.1 if is_in_quicksand else 1.0)
		coyote_timer = 0.0
		sfx.stream = load("res://assets/sounds/jump.wav")
		sfx.play()
	elif Input.is_action_just_pressed("jump") and is_clambering:
		_do_wall_jump()

func _do_wall_jump() -> void:
	is_wall_jumping = true
	velocity.y = WALL_JUMP_VY
	velocity.x = WALL_JUMP_VX * (1.0 if not is_facing_right else -1.0)
	get_tree().create_timer(0.1).timeout.connect(func(): is_wall_jumping = false)

func _handle_attack() -> void:
	if is_attacking:
		return
	if Input.is_action_just_pressed("attack") and is_on_floor() and not is_clambering:
		_start_attack()

func _start_attack() -> void:
	is_attacking = true
	velocity.x = 0.0
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
	if Input.is_action_just_pressed("pause"):
		GameManager.toggle_pause()

func _update_wall_clamber() -> void:
	is_clambering = false
	if is_on_floor() or velocity.y < 0.0:
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col == null or absf(col.get_normal().x) < 0.5:
			continue
		var collider := col.get_collider()
		if collider is Node and (collider as Node).is_in_group("wall"):
			is_clambering = true
			return

func _update_camera_lookahead(delta: float) -> void:
	var target_x := CAMERA_OFFSET_RIGHT if is_facing_right else CAMERA_OFFSET_LEFT
	camera.offset.x = move_toward(camera.offset.x, target_x, CAMERA_LOOKAHEAD_SPEED * delta)

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
	if is_got_hit or is_reached_checkpoint or GameManager.invulnerable:
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
	GameManager.lives -= 1
	emit_signal("life_lost", GameManager.lives)
	sprite.play("hit")
	await sprite.animation_finished
	if GameManager.lives <= 0:
		emit_signal("died")
		return
	global_position = starting_position
	is_facing_right = true
	sprite.flip_h = false
	camera.offset.x = CAMERA_OFFSET_RIGHT
	camera.reset_smoothing()
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
