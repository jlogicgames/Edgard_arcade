extends Node

const MAX_LIVES := 3

var coins: int = 0
var lives: int = MAX_LIVES
var player: CharacterBody2D = null
var current_level_index: int = 0
var invulnerable: bool = false
var debug_draw: bool = false
var language: String = "en"
# Multiplier the level's player and enemies fold into their own delta while
# a bat is near, so bullet-time stays scoped to the simulation and leaves
# Engine.time_scale (UI, music, tweens) untouched.
var level_time_scale: float = 1.0

const LEVELS: Array[String] = [
	"res://scenes/levels/forest1.tscn",
	"res://scenes/levels/forest.tscn",
]

func load_next_level() -> void:
	current_level_index = (current_level_index + 1) % LEVELS.size()
	get_tree().change_scene_to_file(LEVELS[current_level_index])

# Resets run state without changing scene, for callers (like Exit to Menu)
# that navigate elsewhere themselves.
func reset_state() -> void:
	coins = 0
	lives = MAX_LIVES
	current_level_index = 0
	level_time_scale = 1.0

func reset() -> void:
	reset_state()
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
