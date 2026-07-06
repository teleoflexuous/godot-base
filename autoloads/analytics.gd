extends Node

signal analytics_event_queued(event_name: String, data: Dictionary)

var enabled := false


func _project_setting_as_string(setting_path: String) -> String:
	if not ProjectSettings.has_setting(setting_path):
		return ""
	var value = ProjectSettings.get_setting_with_override(setting_path)
	return "" if value == null else str(value)


func _ready() -> void:
	# Credentials are intentionally not stored in the base project.
	var game_key := _project_setting_as_string("analytics/game_key")
	var secret_key := _project_setting_as_string("analytics/secret_key")
	enabled = game_key != "" and secret_key != "" and Engine.has_singleton("GameAnalytics")
	if not enabled:
		return
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("configureBuild"):
		sdk.configureBuild(_project_setting_as_string("application/config/version"))


func track_event(event_name: String, data: Dictionary = {}) -> void:
	analytics_event_queued.emit(event_name, data)
	if not enabled:
		return
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("addDesignEvent"):
		sdk.addDesignEvent(event_name, data)
