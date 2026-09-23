extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	GameManager.play_sfx("res://assets/sounds/explosion.wav")
	var explosion := (load("res://scenes/effects/bomb_explosion.tscn") as PackedScene).instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	queue_free()
	(body as Player).take_hit()
