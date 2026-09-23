extends CanvasLayer

func _ready() -> void:
	$Panel/VBoxContainer/RetryButton.pressed.connect(_on_retry)

func _on_retry() -> void:
	GameManager.reset()
