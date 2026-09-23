extends Node

const MAX_LIVES := 3
const MUSIC_FADE_IN := 2.0
const MUSIC_FADE_OUT := 1.0
const NATIVE_LANGUAGE_NAMES := {"en": "English", "uk": "Українська"}

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

var _menu_music_active: bool = false
var _menu_music_volume: float = 0.0
var _menu_music_player: AudioStreamPlayer
var _fps_label: Label
var _fade_rect: ColorRect

const LEVELS: Array[String] = [
	"res://scenes/levels/forest1.tscn",
	"res://scenes/levels/forest.tscn",
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	TranslationServer.set_locale(language)
	_setup_menu_music()
	_setup_fps_counter()
	_setup_fade_overlay()

func _process(delta: float) -> void:
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	_update_menu_music(delta)

func set_menu_music_active(active: bool) -> void:
	_menu_music_active = active

func toggle_language() -> void:
	language = "uk" if language == "en" else "en"
	TranslationServer.set_locale(language)

func native_language_name() -> String:
	return NATIVE_LANGUAGE_NAMES.get(language, language)

func load_next_level() -> void:
	current_level_index = (current_level_index + 1) % LEVELS.size()
	_transition_to_scene(LEVELS[current_level_index])

# Resets run state without changing scene, for callers (like Exit to Menu)
# that navigate elsewhere themselves.
func reset_state() -> void:
	coins = 0
	lives = MAX_LIVES
	current_level_index = 0
	level_time_scale = 1.0

func reset() -> void:
	reset_state()
	_transition_to_scene(LEVELS[0])

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	var pause_menu: Node = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu != null:
		pause_menu.set("visible", get_tree().paused)

func play_sfx(path: String, volume_scale: float = 1.0) -> void:
	var asp := AudioStreamPlayer.new()
	asp.stream = load(path)
	asp.volume_db = linear_to_db(maxf(volume_scale, 0.0001))
	asp.autoplay = true
	asp.connect("finished", asp.queue_free)
	add_child(asp)

func play_button_click() -> void:
	play_sfx("res://assets/sounds/button_click.wav")

# Quiet hover/focus blip, distinct from button_click's louder press sound.
func play_button_hover() -> void:
	play_sfx("res://assets/sounds/button_click.wav", 0.35)

func _setup_menu_music() -> void:
	_menu_music_player = AudioStreamPlayer.new()
	var stream: AudioStreamMP3 = load("res://assets/sounds/main_menu.mp3") as AudioStreamMP3
	stream.loop = true
	_menu_music_player.stream = stream
	_menu_music_player.volume_db = linear_to_db(0.0001)
	add_child(_menu_music_player)

func _update_menu_music(delta: float) -> void:
	var target := 1.0 if _menu_music_active else 0.0
	if _menu_music_volume < target:
		_menu_music_volume = minf(target, _menu_music_volume + delta / MUSIC_FADE_IN)
	elif _menu_music_volume > target:
		_menu_music_volume = maxf(target, _menu_music_volume - delta / MUSIC_FADE_OUT)
	if _menu_music_volume > 0.0 and not _menu_music_player.playing:
		_menu_music_player.play()
	if _menu_music_volume <= 0.0 and _menu_music_player.playing:
		_menu_music_player.stop()
	_menu_music_player.volume_db = linear_to_db(maxf(_menu_music_volume, 0.0001))

func _setup_fps_counter() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_fps_label = Label.new()
	_fps_label.add_theme_font_size_override("font_size", 9)
	_fps_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1.0))
	_fps_label.anchor_left = 1.0
	_fps_label.anchor_right = 1.0
	_fps_label.offset_left = -70.0
	_fps_label.offset_right = -6.0
	_fps_label.offset_top = 4.0
	_fps_label.offset_bottom = 20.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fps_label)

func _setup_fade_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 99
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade_rect)

# 1 s delay before a level (re)loads, with a fade to black in between.
func _transition_to_scene(path: String) -> void:
	var tw := create_tween()
	tw.tween_property(_fade_rect, "color:a", 1.0, 0.3)
	await tw.finished
	await get_tree().create_timer(0.4).timeout
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_fade_rect, "color:a", 0.0, 0.3)
