extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F1:
			GameManager.debug_draw = not GameManager.debug_draw
			get_tree().debug_collisions_hint = GameManager.debug_draw
		KEY_F2:
			GameManager.invulnerable = not GameManager.invulnerable
		KEY_F3:
			_spawn_debug_effects()
		KEY_F4:
			GameManager.load_next_level()
		KEY_F5:
			_trigger_checkpoint()

func _spawn_debug_effects() -> void:
	var player: Node2D = GameManager.player
	if player == null:
		return
	_spawn_effect(player.global_position, 0.75, 300.0, 12.0, Color("ffe27a"))
	_spawn_effect(player.global_position, 0.6, 64.0, 8.0, Color(1.0, 0.949, 0.698))

func _spawn_effect(pos: Vector2, duration: float, max_radius: float, ring_width: float, color: Color) -> void:
	var fx := (load("res://scenes/effects/shockwave_effect.tscn") as PackedScene).instantiate() as ShockwaveEffect
	fx.duration = duration
	fx.max_radius = max_radius
	fx.ring_width = ring_width
	fx.color = color
	get_tree().current_scene.add_child(fx)
	fx.global_position = pos

func _trigger_checkpoint() -> void:
	var player: Node = GameManager.player
	if player != null and player.has_method("_reached_checkpoint"):
		player.call("_reached_checkpoint")
