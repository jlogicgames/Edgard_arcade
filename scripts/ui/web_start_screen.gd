extends CanvasLayer

# Web builds block audio until a user gesture (T3), so this screen sits in
# front of MainMenu and gates GameManager.audio_unlocked until Play is
# pressed. Non-web builds never see it.
@onready var play_button: Button = $Panel/CenterContainer/PlayButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.has_feature("web"):
		queue_free()
		return
	layer = 30
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()

func _on_play_pressed() -> void:
	GameManager.unlock_audio()
	GameManager.play_button_click()
	var main_menu: Node = get_parent().get_node_or_null("MainMenu")
	if main_menu != null and main_menu.has_method("focus_main"):
		main_menu.call("focus_main")
	queue_free()
