extends Node

signal analytics_event_queued(event_name: String, data: Dictionary)

const STARTUP_TIMEOUT_SEC := 20.0

var enabled := false
var startup_ready := false
var startup_stage := &"booting"

var _boot_started_at_msec := 0
var _pending_events: Array[Dictionary] = []
var _sdk_initialized := false
var _startup_watchdog: Timer


func _project_setting_as_string(setting_path: String) -> String:
	if not ProjectSettings.has_setting(setting_path):
		return ""
	var value = ProjectSettings.get_setting_with_override(setting_path)
	return "" if value == null else str(value)


func _ready() -> void:
	_boot_started_at_msec = Time.get_ticks_msec()
	_start_startup_watchdog()

	# Credentials are intentionally not stored in the base project.
	var game_key := _project_setting_as_string("analytics/game_key")
	var secret_key := _project_setting_as_string("analytics/secret_key")
	var has_keys := game_key != "" and secret_key != ""
	var has_singleton := Engine.has_singleton("GameAnalytics")
	enabled = has_keys and has_singleton
	get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_report_existing_main_scene_if_ready")

	track_boot_stage("autoload_ready", {
		"analytics_keys_configured": has_keys,
		"analytics_singleton_available": has_singleton,
		"main_scene": _project_setting_as_string("application/run/main_scene"),
		"platform": OS.get_name(),
		"web": OS.has_feature("web"),
		"mobile": OS.has_feature("mobile"),
	})
	if not enabled:
		var reason := "missing credentials and GameAnalytics singleton"
		if has_keys and not has_singleton:
			reason = "GameAnalytics singleton unavailable"
		elif has_singleton and not has_keys:
			reason = "analytics credentials missing"
		DebugLog.warn("Analytics disabled: %s." % reason)
		return
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("configureBuild"):
		sdk.configureBuild(_project_setting_as_string("application/config/version"))
	if sdk != null and sdk.has_method("init"):
		sdk.init(game_key, secret_key)
		_sdk_initialized = true
	elif sdk != null and sdk.has_method("initialize"):
		sdk.initialize(game_key, secret_key)
		_sdk_initialized = true
	else:
		DebugLog.warn("Analytics singleton is present but exposes no init method.")
	track_boot_stage("analytics_initialized")
	_flush_pending_events()


func track_event(event_name: String, data: Dictionary = {}) -> void:
	analytics_event_queued.emit(event_name, data)
	if not enabled:
		return
	if not _sdk_initialized:
		_pending_events.append({
			"event_name": event_name,
			"data": data.duplicate(true),
		})
		return
	_send_event(event_name, data)


func track_boot_stage(stage: String, data: Dictionary = {}) -> void:
	startup_stage = StringName(stage)
	var payload := _boot_payload(data)
	payload["stage"] = stage
	DebugLog.event("boot_stage", payload)
	track_event("boot:%s" % stage, payload)


func track_error(error_name: String, data: Dictionary = {}) -> void:
	var payload := _boot_payload(data)
	payload["error_name"] = error_name
	DebugLog.error("Analytics boot error: %s %s" % [error_name, JSON.stringify(payload)])
	track_event("boot_error:%s" % error_name, payload)


func report_main_scene_ready(scene_name: String, data: Dictionary = {}) -> void:
	startup_ready = true
	if _startup_watchdog != null:
		_startup_watchdog.stop()
	var payload := data.duplicate(true)
	payload["scene_name"] = scene_name
	payload["cross_origin_isolated"] = _get_web_bool("window.crossOriginIsolated === true")
	payload["shared_array_buffer"] = _get_web_bool("typeof SharedArrayBuffer !== 'undefined'")
	track_boot_stage("main_scene_ready", payload)
	_mark_web_ready(payload)


func _start_startup_watchdog() -> void:
	_startup_watchdog = Timer.new()
	_startup_watchdog.wait_time = STARTUP_TIMEOUT_SEC
	_startup_watchdog.one_shot = true
	_startup_watchdog.timeout.connect(_on_startup_watchdog_timeout)
	add_child(_startup_watchdog)
	_startup_watchdog.start()


func _on_tree_node_added(node: Node) -> void:
	if startup_ready:
		return
	var main_scene_path := _project_setting_as_string("application/run/main_scene")
	if main_scene_path == "":
		return
	if node.scene_file_path != main_scene_path:
		return
	if node.is_node_ready():
		report_main_scene_ready(node.scene_file_path, {
			"root_name": node.name,
		})
		return
	node.ready.connect(func() -> void:
		if startup_ready:
			return
		report_main_scene_ready(node.scene_file_path, {
			"root_name": node.name,
		})
	, CONNECT_ONE_SHOT)


func _report_existing_main_scene_if_ready() -> void:
	if startup_ready:
		return
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var main_scene_path := _project_setting_as_string("application/run/main_scene")
	if current_scene.scene_file_path != main_scene_path:
		return
	report_main_scene_ready(current_scene.scene_file_path, {
		"root_name": current_scene.name,
	})


func _on_startup_watchdog_timeout() -> void:
	if startup_ready:
		return
	track_error("startup_timeout", {
		"timeout_seconds": STARTUP_TIMEOUT_SEC,
		"last_stage": String(startup_stage),
	})


func _boot_payload(data: Dictionary) -> Dictionary:
	var payload := {
		"boot_ms": Time.get_ticks_msec() - _boot_started_at_msec,
		"engine_version": Engine.get_version_info().get("string", ""),
		"game_version": _project_setting_as_string("application/config/version"),
		"platform": OS.get_name(),
		"web": OS.has_feature("web"),
		"mobile": OS.has_feature("mobile"),
	}
	payload.merge(data, true)
	return payload


func _flush_pending_events() -> void:
	for pending_event in _pending_events:
		_send_event(str(pending_event.get("event_name", "")), pending_event.get("data", {}))
	_pending_events.clear()


func _send_event(event_name: String, data: Dictionary) -> void:
	var sdk := Engine.get_singleton("GameAnalytics")
	if sdk != null and sdk.has_method("addDesignEvent"):
		if data.is_empty():
			sdk.addDesignEvent(event_name)
			return
		sdk.addDesignEvent(event_name, {
			"fields": JSON.stringify(data),
		})


func _get_web_bool(expression: String) -> bool:
	if not OS.has_feature("web"):
		return false
	var result = JavaScriptBridge.eval(expression, true)
	return result == true


func _mark_web_ready(data: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"window.__godotMarkReady && window.__godotMarkReady(%s);" % JSON.stringify(data),
		true,
	)
