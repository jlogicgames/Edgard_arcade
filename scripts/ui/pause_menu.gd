extends CanvasLayer

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready() -> void:
	add_to_group("pause_menu")
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	for button: Button in [resume_button, quit_button]:
		button.mouse_entered.connect(GameManager.play_button_hover)
		button.focus_entered.connect(GameManager.play_button_hover)
	resume_button.pressed.connect(_on_resume)
	quit_button.pressed.connect(_on_quit)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume()

func _on_resume() -> void:
	GameManager.play_button_click()
	GameManager.toggle_pause()

func _on_quit() -> void:
	GameManager.play_button_click()
	GameManager.reset_state()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")
