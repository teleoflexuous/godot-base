extends Node

signal analytics_event_queued(event_name: String, data: Dictionary)

var enabled := false

func _ready() -> void:
	# Credentials are intentionally not stored in the base project.
	var game_key := str(ProjectSettings.get_setting("analytics/game_key", ""))
	var secret_key := str(ProjectSettings.get_setting("analytics/secret_key", ""))
	enabled = game_key != "" and secret_key != "" and Engine.has_singleton("GameAnalytics")
	if not enabled:
		return
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("configureBuild"):
		sdk.configureBuild(str(ProjectSettings.get_setting("application/config/version", "0.1.0")))


func track_event(event_name: String, data: Dictionary = {}) -> void:
	analytics_event_queued.emit(event_name, data)
	if not enabled:
		return
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("addDesignEvent"):
		sdk.addDesignEvent(event_name, data)
