## Standalone headless runner — generates forest1.tscn and forest.tscn
## Run with:  godot --headless --script res://scripts/tools/run_import.gd
extends SceneTree

const TMX_DIR := "/Users/amerezhanyi/Developer/edgard_in_kimeria/assets/tiles/"
const TILE_COLS := 20

func _init() -> void:
	_import_level("forest-1.tmx", "res://scenes/levels/forest1.tscn", 640)
	_import_level("forest.tmx",   "res://scenes/levels/forest.tscn",  1280)
	print("Done.")
	quit()

# ─────────────────────────────────────────────────────────────────────────────

func _import_level(tmx_file: String, out_path: String, level_width_px: int) -> void:
	print("Parsing: ", TMX_DIR + tmx_file)
	var parsed := _parse_tmx(TMX_DIR + tmx_file)
	if parsed.is_empty():
		push_error("Failed to parse: " + tmx_file)
		return

	var root := Node2D.new()
	root.name = "Level"
	root.set_script(load("res://scripts/level.gd"))
	root.set("level_width_px", level_width_px)

	# Background
	var bg := CanvasLayer.new()
	bg.name = "Background"
	bg.layer = -1
	root.add_child(bg)
	bg.owner = root

	var sky := TextureRect.new()
	sky.name = "Sky"
	sky.anchors_preset = Control.PRESET_FULL_RECT
	sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture = load("res://assets/sprites/background/sky.png")
	bg.add_child(sky)
	sky.owner = root

	# TileMapLayer
	var tileset := load("res://assets/tilesets/forest.tres") as TileSet
	var tile_map := TileMapLayer.new()
	tile_map.name = "TileMapLayer"
	tile_map.tile_set = tileset
	root.add_child(tile_map)
	tile_map.owner = root

	var csv: Array[int] = parsed.get("tile_data", [])
	var map_w: int = parsed.get("map_width", 40)
	for i in csv.size():
		var raw: int = csv[i]
		if raw == 0:
			continue
		var aid := raw - 1
		tile_map.set_cell(Vector2i(i % map_w, i / map_w), 0, Vector2i(aid % TILE_COLS, aid / TILE_COLS))

	# Collisions
	var coll_root := Node2D.new()
	coll_root.name = "Collisions"
	root.add_child(coll_root)
	coll_root.owner = root

	for idx in parsed.get("collision_objects", []).size():
		var obj: Dictionary = parsed["collision_objects"][idx]
		var otype: String = obj.get("type", "")
		var ox: float = obj["x"]
		var oy: float = obj["y"]
		var ow: float = maxf(float(obj.get("width", 16)), 1.0)
		var oh: float = maxf(float(obj.get("height", 16)), 1.0)

		var is_area := otype == "QuickSand"
		var one_way := otype == "Platform"
		var grp := _grp(otype)

		var body: CollisionObject2D = Area2D.new() if is_area else StaticBody2D.new()
		body.name = "Collision_%d" % idx
		body.position = Vector2(ox + ow * 0.5, oy + oh * 0.5)
		if grp != "":
			body.add_to_group(grp)
		coll_root.add_child(body)
		body.owner = root

		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(ow, oh)
		cs.shape = rect
		if one_way:
			cs.one_way_collision = true
		body.add_child(cs)
		cs.owner = root

	# SpawnPoints
	var sp_root := Node2D.new()
	sp_root.name = "SpawnPoints"
	root.add_child(sp_root)
	sp_root.owner = root

	for idx in parsed.get("spawn_objects", []).size():
		var obj: Dictionary = parsed["spawn_objects"][idx]
		var otype: String = obj.get("type", obj.get("name", "Unknown"))
		if otype.strip_edges() == "":
			otype = "Unknown"
		var marker := Marker2D.new()
		marker.name = "%s_%d" % [otype, idx]
		marker.position = Vector2(float(obj["x"]), float(obj["y"]))
		for pk in obj.get("properties", {}).keys():
			marker.set_meta(pk, obj["properties"][pk])
		sp_root.add_child(marker)
		marker.owner = root

	# HUD + Pause (embed instances by path — can't instantiate PackedScene in headless cleanly, so skip)
	# level.gd will load HUD/Pause if needed, or add them manually in the editor.

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		push_error("pack() failed: %d for %s" % [err, out_path])
		root.queue_free()
		return

	err = ResourceSaver.save(packed, out_path)
	if err != OK:
		push_error("save() failed: %d for %s" % [err, out_path])
	else:
		print("Saved: ", out_path)

	root.queue_free()

func _grp(t: String) -> String:
	match t:
		"Wall":      return "wall"
		"Platform":  return "platform"
		"QuickSand": return "quicksand"
		_:           return "solid"

func _parse_tmx(path: String) -> Dictionary:
	var xml := XMLParser.new()
	if xml.open(path) != OK:
		push_error("Cannot open: " + path)
		return {}

	var res := {
		"map_width": 0, "map_height": 0,
		"tile_data": [] as Array[int],
		"collision_objects": [],
		"spawn_objects": [],
	}
	var in_layer := false
	var in_objgrp := false
	var layer_name := ""
	var csv_buf := ""
	var cur_obj: Dictionary = {}
	var objgrp_offset_y := 0.0

	while xml.read() == OK:
		match xml.get_node_type():
			XMLParser.NODE_ELEMENT:
				var tag := xml.get_node_name()
				match tag:
					"map":
						res["map_width"]  = int(xml.get_named_attribute_value_safe("width"))
						res["map_height"] = int(xml.get_named_attribute_value_safe("height"))
					"layer":
						in_layer = true; layer_name = xml.get_named_attribute_value_safe("name"); csv_buf = ""
					"objectgroup":
						in_objgrp = true; layer_name = xml.get_named_attribute_value_safe("name")
						var offy := xml.get_named_attribute_value_safe("offsety")
						objgrp_offset_y = float(offy) if offy != "" else 0.0
					"object":
						if in_objgrp:
							var raw_y := float(xml.get_named_attribute_value_safe("y"))
							var t := xml.get_named_attribute_value_safe("type")
							var c := xml.get_named_attribute_value_safe("class")
							cur_obj = {
								"name": xml.get_named_attribute_value_safe("name"),
								"type": t if t != "" else c,
								"x": float(xml.get_named_attribute_value_safe("x")),
								"y": raw_y + objgrp_offset_y,
								"width": float(xml.get_named_attribute_value_safe("width")),
								"height": float(xml.get_named_attribute_value_safe("height")),
								"layer": layer_name,
								"properties": {},
							}
							# Self-closing <object/> — no NODE_ELEMENT_END fires, add immediately
							if xml.is_empty():
								_add_obj(cur_obj, res)
								cur_obj = {}
					"property":
						if not cur_obj.is_empty():
							var pn := xml.get_named_attribute_value_safe("name")
							var pv := xml.get_named_attribute_value_safe("value")
							var pt := xml.get_named_attribute_value_safe("type")
							match pt:
								"bool":  cur_obj["properties"][pn] = pv == "true"
								"int":   cur_obj["properties"][pn] = int(pv)
								"float": cur_obj["properties"][pn] = float(pv)
								_:       cur_obj["properties"][pn] = pv
			XMLParser.NODE_TEXT:
				if in_layer:
					csv_buf += xml.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				match xml.get_node_name():
					"layer":
						if in_layer:
							for token in csv_buf.strip_edges().split(","):
								var t := token.strip_edges()
								if t != "": res["tile_data"].append(int(t))
						in_layer = false; csv_buf = ""
					"objectgroup":
						in_objgrp = false; objgrp_offset_y = 0.0
					"object":
						if not cur_obj.is_empty():
							_add_obj(cur_obj, res)
							cur_obj = {}
	return res

func _add_obj(obj: Dictionary, res: Dictionary) -> void:
	if obj["layer"] == "Collisions":
		res["collision_objects"].append(obj)
	elif obj["layer"] == "SpawnPoints":
		res["spawn_objects"].append(obj)
