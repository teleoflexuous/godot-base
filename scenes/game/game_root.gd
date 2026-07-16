extends Control

@onready var main_menu: Control = %MainMenu
@onready var game_view: Control = %GameView
@onready var pause_menu: Control = %PauseMenu
@onready var game_over: Control = %GameOver
@onready var win_screen: Control = %WinScreen
@onready var settings: Control = %Settings
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var quality_option: OptionButton = %QualityOption
@onready var profile_option: OptionButton = %ProfileOption
@onready var debug_overlay: DebugOverlay = $DebugOverlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for quality: StringName in GraphicsSettings.QUALITY_VALUES:
		quality_option.add_item(String(quality))
	quality_option.select(GraphicsSettings.QUALITY_VALUES.find(GraphicsSettings.get_quality()))
	for profile: StringName in InputProfiles.PROFILE_IDS:
		profile_option.add_item(String(profile))
	profile_option.select(InputProfiles.PROFILE_IDS.find(InputProfiles.get_active_profile()))
	master_slider.value = AudioManager.get_master_volume()
	music_slider.value = AudioManager.get_music_volume()
	effects_slider.value = AudioManager.get_effects_volume()
	var _state_connection: Error = GameManager.state_changed.connect(_on_game_state_changed) as Error
	var _debug_connection: Error = debug_overlay.skip_scene_requested.connect(GameManager.win_game) as Error
	_show_state(GameManager.state)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if GameManager.state == GameManager.GameState.PLAYING:
			GameManager.pause()
		elif GameManager.state == GameManager.GameState.PAUSED:
			GameManager.resume()
		get_viewport().set_input_as_handled()


func _on_game_state_changed(_previous: GameManager.GameState, current: GameManager.GameState) -> void:
	_show_state(current)


func _show_state(current: GameManager.GameState) -> void:
	main_menu.visible = current == GameManager.GameState.MAIN_MENU
	game_view.visible = current == GameManager.GameState.PLAYING or current == GameManager.GameState.PAUSED
	pause_menu.visible = current == GameManager.GameState.PAUSED
	game_over.visible = current == GameManager.GameState.GAME_OVER
	win_screen.visible = current == GameManager.GameState.WON
	settings.visible = false


func _on_start_pressed() -> void:
	GameManager.start_game()


func _on_resume_pressed() -> void:
	GameManager.resume()


func _on_retry_pressed() -> void:
	GameManager.start_game()


func _on_menu_pressed() -> void:
	GameManager.return_to_menu()


func _on_settings_pressed() -> void:
	settings.visible = true


func _on_settings_back_pressed() -> void:
	settings.visible = false


func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)


func _on_effects_changed(value: float) -> void:
	AudioManager.set_effects_volume(value)


func _on_quality_selected(index: int) -> void:
	GraphicsSettings.set_quality(GraphicsSettings.QUALITY_VALUES[index])


func _on_profile_selected(index: int) -> void:
	var _saved: bool = InputProfiles.set_active_profile(InputProfiles.PROFILE_IDS[index])
