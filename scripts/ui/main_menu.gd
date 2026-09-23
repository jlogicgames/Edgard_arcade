extends CanvasLayer

enum Screen { MAIN, ABOUT, OPTIONS }

@onready var main_panel: Panel = $MainPanel
@onready var about_panel: Panel = $AboutPanel
@onready var options_panel: Panel = $OptionsPanel

@onready var play_button: Button = $MainPanel/CenterContainer/VBoxContainer/PlayButton
@onready var about_button: Button = $MainPanel/CenterContainer/VBoxContainer/AboutButton
@onready var options_button: Button = $MainPanel/CenterContainer/VBoxContainer/OptionsButton
@onready var exit_button: Button = $MainPanel/CenterContainer/VBoxContainer/ExitButton
@onready var about_back_button: Button = $AboutPanel/VBoxContainer/BackButton
@onready var language_button: Button = $OptionsPanel/VBoxContainer/LanguageButton
@onready var display_button: Button = $OptionsPanel/VBoxContainer/DisplayButton
@onready var options_back_button: Button = $OptionsPanel/VBoxContainer/BackButton

var _current_screen: int = Screen.MAIN

func _ready() -> void:
	GameManager.set_menu_music_active(true)
	_connect_button(play_button, GameManager.reset)
	_connect_button(about_button, func() -> void: _show_screen(Screen.ABOUT))
	_connect_button(options_button, func() -> void: _show_screen(Screen.OPTIONS))
	_connect_button(exit_button, get_tree().quit)
	_connect_button(about_back_button, func() -> void: _show_screen(Screen.MAIN))
	_connect_button(options_back_button, func() -> void: _show_screen(Screen.MAIN))
	_connect_button(language_button, _on_language_pressed)
	_connect_button(display_button, _on_display_pressed)
	display_button.visible = not OS.has_feature("web")
	_update_language_label()
	_update_display_label()
	_show_screen(Screen.MAIN)

func _exit_tree() -> void:
	GameManager.set_menu_music_active(false)

func _connect_button(button: Button, action: Callable) -> void:
	button.pressed.connect(func() -> void:
		GameManager.play_button_click()
		action.call())
	button.mouse_entered.connect(GameManager.play_button_hover)
	button.focus_entered.connect(GameManager.play_button_hover)

func _show_screen(screen: int) -> void:
	_current_screen = screen
	main_panel.visible = screen == Screen.MAIN
	about_panel.visible = screen == Screen.ABOUT
	options_panel.visible = screen == Screen.OPTIONS
	match screen:
		Screen.MAIN:
			play_button.grab_focus()
		Screen.ABOUT:
			about_back_button.grab_focus()
		Screen.OPTIONS:
			language_button.grab_focus()

func _on_language_pressed() -> void:
	GameManager.toggle_language()
	_update_language_label()

func _update_language_label() -> void:
	language_button.text = tr("LANGUAGE_LABEL") + ": " + GameManager.native_language_name()

func _on_display_pressed() -> void:
	GameManager.toggle_fullscreen()
	_update_display_label()

func _update_display_label() -> void:
	var mode_key := "DISPLAY_FULLSCREEN" if GameManager.fullscreen else "DISPLAY_WINDOWED"
	display_button.text = tr("DISPLAY_LABEL") + ": " + tr(mode_key)

# Called by WebStartScreen after its own Play button is dismissed, so
# keyboard/gamepad focus lands back on the menu underneath.
func focus_main() -> void:
	_show_screen(Screen.MAIN)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _current_screen != Screen.MAIN:
		GameManager.play_button_click()
		_show_screen(Screen.MAIN)
