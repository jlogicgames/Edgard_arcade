class_name MenuBackdrop
extends CanvasLayer

## Fog + 18 gold fireflies behind the Main/About/Options menu screens,
## reusing the same effect scenes gameplay ambience uses (see level.gd).
const FIREFLY_COUNT := 18
const FIREFLY_COLOR := Color("ffcc33")

func _ready() -> void:
	# FogOverlay pins itself to layer 4 (see fog_overlay.gd, shared with
	# gameplay ambience), so fireflies sit just under it to stay visible
	# beneath the fog haze, both well under the menu UI's layer 20.
	layer = 3
	var area := Vector2(640.0, 360.0)
	for i in FIREFLY_COUNT:
		var fly := (load("res://scenes/effects/firefly.tscn") as PackedScene).instantiate()
		fly.set("area", area)
		fly.set("firefly_color", FIREFLY_COLOR)
		add_child(fly)
	add_child((load("res://scenes/effects/fog_overlay.tscn") as PackedScene).instantiate())
