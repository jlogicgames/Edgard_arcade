## One-shot TMX → Godot scene converter.
## Run from Godot Editor: Script Editor → File → Run (while this file is open)
## After both scenes are created, delete this file.
@tool
extends EditorScript

const TMX_DIR := "/Users/amerezhanyi/Developer/edgard_in_kimeria/assets/tiles/"
const TILE_COLS := 20

func _run() -> void:
	_import_level("forest-1.tmx", "res://scenes/levels/forest1.tscn", 640)
	_import_level("forest.tmx",   "res://scenes/levels/forest.tscn",  1280)
	print("TMX import complete. Reload the Godot project to see the new scenes.")

# ─────────────────────────────────────────────────────────────────────────────

func _import_level(tmx_file: String, out_res_path: String, level_width_px: int) -> void:
	var tmx_path := TMX_DIR + tmx_file
	print("Parsing: ", tmx_path)

	var parsed := _parse_tmx(tmx_path)
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

func _parse_tmx(path: String) -> Dictionary:
	var xml := XMLParser.new()
	if xml.open(path) != OK:
		return {}

	var result := {
		"map_width": 0,
		"map_height": 0,
		"tile_data": [] as Array[int],
		"collision_objects": [],
		"spawn_objects": [],
	}

	var in_tile_layer := false
	var in_objectgroup := false
	var current_layer_name := ""
	var csv_buffer := ""
	var current_obj: Dictionary = {}
	var obj_group_offset_y := 0.0

	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var tag := xml.get_node_name()
				match tag:
					"map":
						result["map_width"]  = int(xml.get_named_attribute_value_safe("width"))
						result["map_height"] = int(xml.get_named_attribute_value_safe("height"))
					"layer":
						in_tile_layer = true
						current_layer_name = xml.get_named_attribute_value_safe("name")
						csv_buffer = ""
					"objectgroup":
						in_objectgroup = true
						current_layer_name = xml.get_named_attribute_value_safe("name")
						var offy_str := xml.get_named_attribute_value_safe("offsety")
						obj_group_offset_y = float(offy_str) if offy_str != "" else 0.0
					"object":
						if in_objectgroup:
							var raw_y := float(xml.get_named_attribute_value_safe("y"))
							current_obj = {
								"name":   xml.get_named_attribute_value_safe("name"),
								"type":   xml.get_named_attribute_value_safe("type"),
								"class_": xml.get_named_attribute_value_safe("class"),
								"x":      float(xml.get_named_attribute_value_safe("x")),
								"y":      raw_y + obj_group_offset_y,
								"width":  float(xml.get_named_attribute_value_safe("width")),
								"height": float(xml.get_named_attribute_value_safe("height")),
								"layer":  current_layer_name,
								"properties": {},
							}
							# Merge "class" into "type" if type is empty (Tiled 1.9+)
							if current_obj["type"] == "" and current_obj["class_"] != "":
								current_obj["type"] = current_obj["class_"]
					"property":
						if not current_obj.is_empty():
							var pname := xml.get_named_attribute_value_safe("name")
							var pval  := xml.get_named_attribute_value_safe("value")
							var ptype := xml.get_named_attribute_value_safe("type")
							match ptype:
								"bool":  current_obj["properties"][pname] = pval == "true"
								"int":   current_obj["properties"][pname] = int(pval)
								"float": current_obj["properties"][pname] = float(pval)
								_:       current_obj["properties"][pname] = pval

			XMLParser.NODE_TEXT:
				if in_tile_layer:
					csv_buffer += xml.get_node_data()

			XMLParser.NODE_ELEMENT_END:
				var tag := xml.get_node_name()
				match tag:
					"layer":
						if in_tile_layer:
							_parse_csv(csv_buffer, result["tile_data"])
						in_tile_layer = false
						csv_buffer = ""
					"objectgroup":
						in_objectgroup = false
						obj_group_offset_y = 0.0
					"object":
						if not current_obj.is_empty():
							var layer := current_obj["layer"]
							if layer == "Collisions":
								result["collision_objects"].append(current_obj)
							elif layer == "SpawnPoints":
								result["spawn_objects"].append(current_obj)
							current_obj = {}

	return result

func _parse_csv(csv: String, out: Array[int]) -> void:
	for token in csv.strip_edges().split(","):
		var t := token.strip_edges()
		if t != "":
			out.append(int(t))
