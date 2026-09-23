extends CanvasLayer

@onready var retry_button: Button = $Panel/VBoxContainer/RetryButton

func _ready() -> void:
	retry_button.mouse_entered.connect(GameManager.play_button_hover)
	retry_button.focus_entered.connect(GameManager.play_button_hover)
	retry_button.pressed.connect(_on_retry)
	retry_button.grab_focus()

func _on_retry() -> void:
	GameManager.play_button_click()
	GameManager.reset()
