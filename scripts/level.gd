class_name Level
extends Node2D

enum Ambience { NONE, RAIN, FIREFLIES_FOG }

@export var level_width_px: int = 640
@export var ambience: Ambience = Ambience.NONE

@onready var spawn_root: Node2D = $SpawnPoints

func _ready() -> void:
	add_to_group("level")
	get_tree().debug_collisions_hint = GameManager.debug_draw
	_spawn_objects()
	_connect_quicksand()
	_setup_ambience()

func _process(_delta: float) -> void:
	_update_level_time_scale()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		GameManager.debug_draw = not GameManager.debug_draw
		get_tree().debug_collisions_hint = GameManager.debug_draw

func _update_level_time_scale() -> void:
	var player := GameManager.player
	if player == null:
		GameManager.level_time_scale = 1.0
		return
	var near_bat := false
	for bat: Bat in get_tree().get_nodes_in_group("bat"):
		if not bat.is_dead and bat.global_position.distance_to(player.global_position) < 50.0:
			near_bat = true
			break
	GameManager.level_time_scale = 0.5 if near_bat else 1.0

func _spawn_objects() -> void:
	var player_instance: Player = null

	for marker: Node in spawn_root.get_children():
		var pos: Vector2 = (marker as Node2D).position
		var meta := {}
		for key in marker.get_meta_list():
			meta[key] = marker.get_meta(key)

		var type := marker.name.split("_")[0]
		var tiled_name: String = meta.get("tiled_name", "")
		var tiled_size: Vector2 = meta.get("tiled_size", Vector2(16, 16))

		match type:
			"Player", "PlayerSpawn":
				player_instance = (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
				player_instance.global_position = pos
				add_child(player_instance)
				GameManager.player = player_instance
				player_instance.set_level_camera_limits(level_width_px)
				player_instance.checkpoint_reached.connect(GameManager.load_next_level)
				player_instance.died.connect(_on_player_died)

			"Checkpoint":
				var cp := (load("res://scenes/objects/checkpoint.tscn") as PackedScene).instantiate()
				cp.global_position = pos
				cp.set("checkpoint_size", tiled_size)
				add_child(cp)

			"Escalator":
				var esc := (load("res://scenes/objects/escalator.tscn") as PackedScene).instantiate()
				esc.global_position = pos
				esc.set("is_vertical", meta.get("isVertical", false))
				esc.set("off_neg", float(meta.get("offNeg", meta.get("off_neg", 0))))
				esc.set("off_pos", float(meta.get("offPos", meta.get("off_pos", 0))))
				esc.set("target_id", tiled_name)
				add_child(esc)

			"FallingPlatform":
				var fp := (load("res://scenes/objects/falling_platform.tscn") as PackedScene).instantiate()
				fp.global_position = pos
				add_child(fp)

			"Actionable":
				# Can be Torch or Wall depending on "type" property
				var sub_type: String = meta.get("type", "")
				if sub_type == "Torch":
					var torch := (load("res://scenes/objects/torch.tscn") as PackedScene).instantiate()
					torch.global_position = pos
					torch.set("intensity", int(meta.get("Intensity", meta.get("intensity", 0))))
					torch.set("target_id", tiled_name)
					add_child(torch)
				elif sub_type == "Wall":
					var wall := (load("res://scenes/objects/actionable_wall.tscn") as PackedScene).instantiate()
					wall.global_position = pos
					wall.set("target_id", tiled_name)
					wall.set("wall_size", tiled_size)
					add_child(wall)

			"Torch":
				var torch := (load("res://scenes/objects/torch.tscn") as PackedScene).instantiate()
				torch.global_position = pos
				torch.set("intensity", int(meta.get("Intensity", meta.get("intensity", 0))))
				add_child(torch)

			"Trigger":
				var trig := (load("res://scenes/objects/trigger.tscn") as PackedScene).instantiate()
				trig.global_position = pos
				trig.set("target_id", tiled_name)
				trig.set("trigger_size", tiled_size)
				add_child(trig)

			"Wall":
				var wall := (load("res://scenes/objects/actionable_wall.tscn") as PackedScene).instantiate()
				wall.global_position = pos
				wall.set("target_id", tiled_name)
				wall.set("wall_size", tiled_size)
				add_child(wall)

			"RedMob":
				var mob := (load("res://scenes/enemies/red_mob.tscn") as PackedScene).instantiate()
				mob.global_position = pos
				mob.set("off_neg", float(meta.get("offNeg", meta.get("off_neg", 5))))
				mob.set("off_pos", float(meta.get("offPos", meta.get("off_pos", 5))))
				add_child(mob)

			"YellowMob":
				var mob := (load("res://scenes/enemies/yellow_mob.tscn") as PackedScene).instantiate()
				mob.global_position = pos
				mob.set("off_neg", float(meta.get("offNeg", meta.get("off_neg", 5))))
				mob.set("off_pos", float(meta.get("offPos", meta.get("off_pos", 5))))
				add_child(mob)

			"Bat":
				var bat := (load("res://scenes/enemies/bat.tscn") as PackedScene).instantiate()
				bat.global_position = pos
				bat.set("is_vertical", meta.get("isVertical", meta.get("is_vertical", false)))
				bat.set("off_neg", float(meta.get("offNeg", meta.get("off_neg", 3))))
				bat.set("off_pos", float(meta.get("offPos", meta.get("off_pos", 3))))
				add_child(bat)

			"Collectable":
				var col := (load("res://scenes/objects/collectable.tscn") as PackedScene).instantiate()
				col.global_position = pos
				col.set("collectable_type", tiled_name if tiled_name != "" else "Coin")
				add_child(col)

			"Bomb":
				var bomb := (load("res://scenes/objects/bomb.tscn") as PackedScene).instantiate()
				bomb.global_position = pos
				add_child(bomb)

	add_child((load("res://scenes/ui/hud.tscn") as PackedScene).instantiate())
	add_child((load("res://scenes/ui/pause_menu.tscn") as PackedScene).instantiate())

func _setup_ambience() -> void:
	match ambience:
		Ambience.RAIN:
			var rain := (load("res://scenes/effects/rain.tscn") as PackedScene).instantiate()
			rain.set("level_width", float(level_width_px))
			rain.set("level_height", 360.0)
			add_child(rain)
		Ambience.FIREFLIES_FOG:
			for i in 24:
				var fly := (load("res://scenes/effects/firefly.tscn") as PackedScene).instantiate()
				fly.set("area", Vector2(level_width_px, 360.0))
				add_child(fly)
			add_child((load("res://scenes/effects/fog_overlay.tscn") as PackedScene).instantiate())

func _connect_quicksand() -> void:
	var player := GameManager.player
	if not player:
		return
	var collisions_node := find_child("Collisions") as Node
	if not collisions_node:
		return
	for child in collisions_node.get_children():
		if child is Area2D:
			var area := child as Area2D
			area.collision_mask = 2
			area.body_entered.connect(func(body: Node2D) -> void:
				if body == player:
					player.is_in_quicksand = true)
			area.body_exited.connect(func(body: Node2D) -> void:
				if body == player:
					player.is_in_quicksand = false)

func _on_player_died() -> void:
	var go_scene := load("res://scenes/ui/game_over.tscn") as PackedScene
	if go_scene:
		add_child(go_scene.instantiate())
