## Shared TMX parser used by import_tmx.gd (editor) and run_import.gd (headless).
class_name TmxParser
extends RefCounted

static func parse(path: String) -> Dictionary:
	var xml := XMLParser.new()
	if xml.open(path) != OK:
		push_error("Cannot open: " + path)
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
						result["map_width"] = int(xml.get_named_attribute_value_safe("width"))
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
							var t := xml.get_named_attribute_value_safe("type")
							var c := xml.get_named_attribute_value_safe("class")
							current_obj = {
								"name": xml.get_named_attribute_value_safe("name"),
								"type": t if t != "" else c,
								"x": float(xml.get_named_attribute_value_safe("x")),
								"y": raw_y + obj_group_offset_y,
								"width": float(xml.get_named_attribute_value_safe("width")),
								"height": float(xml.get_named_attribute_value_safe("height")),
								"layer": current_layer_name,
								"properties": {},
							}
							# Self-closing <object/> has no matching NODE_ELEMENT_END, so
							# it must be flushed immediately.
							if xml.is_empty():
								_add_obj(current_obj, result)
								current_obj = {}
					"property":
						if not current_obj.is_empty():
							var pname := xml.get_named_attribute_value_safe("name")
							var pval := xml.get_named_attribute_value_safe("value")
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
							_add_obj(current_obj, result)
							current_obj = {}

	return result

static func _add_obj(obj: Dictionary, result: Dictionary) -> void:
	var layer: String = obj["layer"]
	if layer == "Collisions":
		result["collision_objects"].append(obj)
	elif layer == "SpawnPoints":
		result["spawn_objects"].append(obj)

static func _parse_csv(csv: String, out: Array[int]) -> void:
	for token in csv.strip_edges().split(","):
		var t := token.strip_edges()
		if t != "":
			out.append(int(t))
