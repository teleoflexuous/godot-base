extends Node

signal preferences_changed(preferences: CameraUserPreferences)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "camera"

var preferences: CameraUserPreferences = CameraUserPreferences.new()


func _ready() -> void:
	load_settings()


func get_preferences() -> CameraUserPreferences:
	return preferences


func replace_preferences(next_preferences: CameraUserPreferences, persist: bool = true) -> bool:
	if next_preferences == null:
		return false
	preferences = next_preferences.duplicate(true) as CameraUserPreferences
	preferences.sanitize()
	if persist and not save_settings():
		return false
	preferences_changed.emit(preferences)
	return true


func update_values(values: Dictionary, persist: bool = true) -> bool:
	preferences.apply_dictionary(values)
	if persist and not save_settings():
		return false
	preferences_changed.emit(preferences)
	return true


func reset_defaults(persist: bool = true) -> bool:
	preferences = CameraUserPreferences.new()
	if persist and not save_settings():
		return false
	preferences_changed.emit(preferences)
	return true


func load_settings(path: String = SETTINGS_PATH) -> void:
	preferences = CameraUserPreferences.new()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) != OK:
		return
	var values: Dictionary = {}
	for key: String in preferences.to_dictionary():
		if config.has_section_key(SECTION, key):
			values[key] = config.get_value(SECTION, key)
	preferences.apply_dictionary(values)


func save_settings(path: String = SETTINGS_PATH) -> bool:
	var config: ConfigFile = ConfigFile.new()
	var _load_result: Error = config.load(path)
	var values: Dictionary = preferences.to_dictionary()
	for key: String in values:
		config.set_value(SECTION, key, values[key])
	return config.save(path) == OK
