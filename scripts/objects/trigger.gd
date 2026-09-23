extends Area2D

@export var target_id: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).current_trigger_id = target_id

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		if (body as Player).current_trigger_id == target_id:
			(body as Player).current_trigger_id = ""
