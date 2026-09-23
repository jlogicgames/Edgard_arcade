class_name Collectable
extends Area2D

@export var collectable_type: String = "Coin"

var is_collected := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play(collectable_type.to_lower())
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not body is Player:
		return
	is_collected = true
	if collectable_type == "Coin":
		GameManager.coins += 1
		GameManager.play_sfx("res://assets/sounds/collect.wav")
		_spawn_effect(0.75, 300.0, 12.0, Color("ffe27a"))
	elif collectable_type == "Heart":
		GameManager.lives = mini(GameManager.lives + 1, GameManager.MAX_LIVES)
		GameManager.play_sfx("res://assets/sounds/collect.wav")
		_spawn_effect(0.6, 64.0, 8.0, Color(1.0, 0.949, 0.698))
	queue_free()

func _spawn_effect(duration: float, max_radius: float, ring_width: float, color: Color) -> void:
	var fx := (load("res://scenes/effects/shockwave_effect.tscn") as PackedScene).instantiate() as ShockwaveEffect
	fx.duration = duration
	fx.max_radius = max_radius
	fx.ring_width = ring_width
	fx.color = color
	get_parent().add_child(fx)
	fx.global_position = global_position
