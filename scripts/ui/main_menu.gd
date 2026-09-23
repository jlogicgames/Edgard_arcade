extends CanvasLayer

func _ready() -> void:
	$Panel/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.reset()
