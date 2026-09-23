extends CanvasLayer

@onready var coin_label: Label = $HBoxContainer/CoinLabel
@onready var lives_container: HBoxContainer = $LivesContainer

var _last_lives: int = -1

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	coin_label.text = str(GameManager.coins)
	var lives := 0
	if GameManager.player:
		lives = maxi(GameManager.player.lives, 0)
	if lives != _last_lives:
		_last_lives = lives
		_update_lives(lives)

func _update_lives(count: int) -> void:
	for child in lives_container.get_children():
		child.queue_free()
	var items_tex: Texture2D = load("res://assets/sprites/Items.png")
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = items_tex
		atlas.region = Rect2(0, 16, 16, 16)
		var tr := TextureRect.new()
		tr.texture = atlas
		tr.custom_minimum_size = Vector2(16, 16)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lives_container.add_child(tr)
