extends Node

signal quality_changed(quality: StringName)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "graphics"
const DEFAULT_QUALITY: StringName = &"balanced"
const QUALITY_VALUES: Array[StringName] = [&"low", &"balanced", &"high"]

var quality: StringName = DEFAULT_QUALITY

func _ready() -> void:
	_load()
	_apply()


func set_quality(next_quality: StringName) -> void:
	if not QUALITY_VALUES.has(next_quality):
		push_warning("Unknown graphics quality: %s" % next_quality)
		return
	quality = next_quality
	_apply()
	_save()
	quality_changed.emit(quality)


func get_quality() -> StringName:
	return quality


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		quality = DEFAULT_QUALITY
		return
	var raw: Variant = config.get_value(SECTION, "quality", String(DEFAULT_QUALITY))
	if raw is StringName:
		quality = raw
	elif raw is String:
		var raw_str: String = raw
		quality = StringName(raw_str)
	else:
		quality = DEFAULT_QUALITY
	if not QUALITY_VALUES.has(quality):
		quality = DEFAULT_QUALITY


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var _previous_state_loaded: int = config.load(SETTINGS_PATH)
	config.set_value(SECTION, "quality", String(quality))
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Failed to save graphics settings to %s" % SETTINGS_PATH)


func _apply() -> void:
	match quality:
		&"low":
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
		&"high":
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X)
		_:
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
