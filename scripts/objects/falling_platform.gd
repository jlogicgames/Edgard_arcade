class_name FallingPlatform
extends AnimatableBody2D

const FALL_DELAY := 1.0
const FALL_DURATION := 1.5
const FALL_DISTANCE := 200.0

var triggered := false
var trigger_timer := 0.0
var fall_elapsed := 0.0
var _warning_torch: Torch = null
var _torch_extinguished := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not triggered:
		return
	trigger_timer += delta
	if trigger_timer < FALL_DELAY:
		return
	if not _torch_extinguished:
		_torch_extinguished = true
		_warning_torch.set_lit(false)
	fall_elapsed += delta
	move_and_collide(Vector2(0.0, FALL_DISTANCE * delta / FALL_DURATION))
	if fall_elapsed >= FALL_DURATION:
		if is_instance_valid(_warning_torch):
			_warning_torch.queue_free()
		queue_free()

func trigger_fall() -> void:
	if triggered:
		return
	triggered = true
	sprite.play("shaking")
	_warning_torch = (load("res://scenes/objects/torch.tscn") as PackedScene).instantiate() as Torch
	_warning_torch.intensity = 5
	get_parent().add_child(_warning_torch)
	_warning_torch.global_position = global_position + Vector2(16.0, 5.0)
