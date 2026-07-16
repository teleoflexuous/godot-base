extends Node

signal state_changed(previous: GameState, current: GameState)
signal pause_changed(is_paused: bool)
signal time_scale_changed(value: float)
signal game_finished(did_win: bool)

enum GameState { MAIN_MENU, PLAYING, PAUSED, GAME_OVER, WON }

var state: GameState = GameState.MAIN_MENU
var _resume_state: GameState = GameState.PLAYING


func start_game() -> void:
	_set_state(GameState.PLAYING)


func pause() -> void:
	if state != GameState.PLAYING:
		return
	_resume_state = state
	get_tree().paused = true
	_set_state(GameState.PAUSED)
	pause_changed.emit(true)


func resume() -> void:
	if state != GameState.PAUSED:
		return
	get_tree().paused = false
	_set_state(_resume_state)
	pause_changed.emit(false)


func end_game() -> void:
	get_tree().paused = false
	_set_state(GameState.GAME_OVER)
	game_finished.emit(false)


func win_game() -> void:
	get_tree().paused = false
	_set_state(GameState.WON)
	game_finished.emit(true)


func return_to_menu() -> void:
	get_tree().paused = false
	_set_state(GameState.MAIN_MENU)


func set_time_scale(value: float) -> void:
	Engine.time_scale = maxf(value, 0.0)
	time_scale_changed.emit(Engine.time_scale)


func _set_state(next_state: GameState) -> void:
	if state == next_state:
		return
	var previous: GameState = state
	state = next_state
	state_changed.emit(previous, state)
