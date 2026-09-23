extends Node

var coins: int = 0
var player: CharacterBody2D = null
var current_level_index: int = 0

const LEVELS: Array[String] = [
	"res://scenes/levels/forest1.tscn",
	"res://scenes/levels/forest.tscn",
]

func load_next_level() -> void:
	current_level_index = (current_level_index + 1) % LEVELS.size()
	get_tree().change_scene_to_file(LEVELS[current_level_index])

func reset() -> void:
	coins = 0
	current_level_index = 0
	get_tree().change_scene_to_file(LEVELS[0])

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	var pause_menu: Node = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu != null:
		pause_menu.set("visible", get_tree().paused)

func play_sfx(path: String) -> void:
	var asp := AudioStreamPlayer.new()
	asp.stream = load(path)
	asp.autoplay = true
	asp.connect("finished", asp.queue_free)
	add_child(asp)
