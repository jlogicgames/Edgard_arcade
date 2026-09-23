class_name FallingPlatform
extends AnimatableBody2D

const FALL_DELAY := 1.0
const FALL_DURATION := 1.5
const FALL_DISTANCE := 200.0

var triggered := false
var trigger_timer := 0.0
var fall_elapsed := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not triggered:
		return
	trigger_timer += delta
	if trigger_timer < FALL_DELAY:
		return
	fall_elapsed += delta
	move_and_collide(Vector2(0.0, FALL_DISTANCE * delta / FALL_DURATION))
	if fall_elapsed >= FALL_DURATION:
		queue_free()

func trigger_fall() -> void:
	if triggered:
		return
	triggered = true
	sprite.play("shaking")
