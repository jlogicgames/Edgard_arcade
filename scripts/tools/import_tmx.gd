## One-shot TMX → Godot scene converter.
## Run from Godot Editor: Script Editor → File → Run (while this file is open)
## After both scenes are created, delete this file.
@tool
extends EditorScript

const TMX_DIR := "res://assets/tiles/"
const TILE_COLS := 20
const TmxParser := preload("res://scripts/tools/tmx_parser.gd")

func _run() -> void:
	_import_level("forest-1.tmx", "res://scenes/levels/forest1.tscn", 640)
	_import_level("forest.tmx",   "res://scenes/levels/forest.tscn",  1280)
	print("TMX import complete. Reload the Godot project to see the new scenes.")

# ─────────────────────────────────────────────────────────────────────────────

func _import_level(tmx_file: String, out_res_path: String, level_width_px: int) -> void:
	var tmx_path := TMX_DIR + tmx_file
	print("Parsing: ", tmx_path)

	var parsed := TmxParser.parse(tmx_path)
	if parsed.is_empty():
		push_error("Failed to parse: " + tmx_path)
		return

	var root := Node2D.new()
	root.name = "Level"
	var script := load("res://scripts/level.gd") as Script
	root.set_script(script)
	root.set("level_width_px", level_width_px)

	# ── Background ──────────────────────────────────────────────────────────
	var bg_canvas := CanvasLayer.new()
	bg_canvas.name = "Background"
	bg_canvas.layer = -1
	root.add_child(bg_canvas)
	bg_canvas.owner = root

	var sky_tex := TextureRect.new()
	sky_tex.name = "Sky"
	sky_tex.anchors_preset = Control.PRESET_FULL_RECT
	sky_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_tex.stretch_mode = TextureRect.STRETCH_SCALE
	sky_tex.texture = load("res://assets/sprites/background/sky.png")
	bg_canvas.add_child(sky_tex)
	sky_tex.owner = root

	# ── TileMapLayer ────────────────────────────────────────────────────────
	var tile_map := TileMapLayer.new()
	tile_map.name = "TileMapLayer"
	tile_map.tile_set = load("res://assets/tilesets/forest.tres")
	root.add_child(tile_map)
	tile_map.owner = root

	var csv_data: Array[int] = parsed.get("tile_data", [])
	var map_w: int = parsed.get("map_width", 40)
	for i in csv_data.size():
		var raw: int = csv_data[i]
		if raw == 0:
			continue
		var atlas_id := raw - 1
		var acol := atlas_id % TILE_COLS
		var arow := atlas_id / TILE_COLS
		var mcol := i % map_w
		var mrow := i / map_w
		tile_map.set_cell(Vector2i(mcol, mrow), 0, Vector2i(acol, arow))

	# ── Collisions ──────────────────────────────────────────────────────────
	var coll_root := Node2D.new()
	coll_root.name = "Collisions"
	root.add_child(coll_root)
	coll_root.owner = root

	var coll_idx := 0
	for obj in parsed.get("collision_objects", []):
		var otype: String = obj.get("type", "")
		var ox: float = obj["x"]
		var oy: float = obj["y"]
		var ow: float = maxf(obj.get("width", 16.0), 1.0)
		var oh: float = maxf(obj.get("height", 16.0), 1.0)

		var is_area := otype == "QuickSand"
		var one_way := otype == "Platform"
		var grp := _collision_group(otype)

		var body: CollisionObject2D
		if is_area:
			body = Area2D.new()
		else:
			body = StaticBody2D.new()
		body.name = "Collision_%d" % coll_idx
		body.position = Vector2(ox + ow * 0.5, oy + oh * 0.5)
		if grp != "":
			body.add_to_group(grp)
		coll_root.add_child(body)
		body.owner = root

		var shape_node := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(ow, oh)
		shape_node.shape = rect
		if one_way:
			shape_node.one_way_collision = true
		body.add_child(shape_node)
		shape_node.owner = root

		coll_idx += 1

	# ── SpawnPoints ─────────────────────────────────────────────────────────
	var spawn_root := Node2D.new()
	spawn_root.name = "SpawnPoints"
	root.add_child(spawn_root)
	spawn_root.owner = root

	var spawn_idx := 0
	for obj in parsed.get("spawn_objects", []):
		var otype: String = obj.get("type", obj.get("name", "Unknown"))
		if otype == "":
			otype = "Unknown"
		var ox: float = obj["x"]
		var oy: float = obj["y"]
		var props: Dictionary = obj.get("properties", {})

		var marker := Marker2D.new()
		marker.name = "%s_%d" % [otype, spawn_idx]
		marker.position = Vector2(ox, oy)
		for pk in props.keys():
			marker.set_meta(pk, props[pk])
		marker.set_meta("tiled_name", obj.get("name", ""))
		marker.set_meta("tiled_size", Vector2(obj.get("width", 16.0), obj.get("height", 16.0)))
		spawn_root.add_child(marker)
		marker.owner = root
		spawn_idx += 1

	# ── HUD ─────────────────────────────────────────────────────────────────
	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_scene:
		var hud := hud_scene.instantiate()
		root.add_child(hud)
		hud.owner = root

	# ── PauseMenu ───────────────────────────────────────────────────────────
	var pm_scene := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pm_scene:
		var pm := pm_scene.instantiate()
		root.add_child(pm)
		pm.owner = root

	# ── Pack & Save ─────────────────────────────────────────────────────────
	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("PackedScene.pack() failed with error %d for %s" % [err, out_res_path])
		root.queue_free()
		return

	err = ResourceSaver.save(packed, out_res_path)
	if err != OK:
		push_error("ResourceSaver.save() failed with error %d for %s" % [err, out_res_path])
	else:
		print("Saved: ", out_res_path)

	root.queue_free()

# ─────────────────────────────────────────────────────────────────────────────

func _collision_group(type: String) -> String:
	match type:
		"Wall":   return "wall"
		"Platform": return "platform"
		"QuickSand": return "quicksand"
		_:        return "solid"
