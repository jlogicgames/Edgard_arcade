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
	elif collectable_type == "Heart":
		GameManager.lives = mini(GameManager.lives + 1, GameManager.MAX_LIVES)
		GameManager.play_sfx("res://assets/sounds/collect.wav")
	queue_free()
