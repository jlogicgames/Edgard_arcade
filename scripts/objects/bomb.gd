extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	GameManager.play_sfx("res://assets/sounds/explosion.wav")
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 32
	particles.lifetime = 0.8
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 200)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.connect("finished", particles.queue_free)
	queue_free()
	(body as Player).take_hit()
