extends Node

signal quality_changed(quality: StringName)

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "graphics"
const DEFAULT_QUALITY := &"balanced"
const QUALITY_VALUES := [&"low", &"balanced", &"high"]

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
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		quality = DEFAULT_QUALITY
		return
	quality = StringName(config.get_value(SECTION, "quality", String(DEFAULT_QUALITY)))
	if not QUALITY_VALUES.has(quality):
		quality = DEFAULT_QUALITY


func _save() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, "quality", String(quality))
	config.save(SETTINGS_PATH)


func _apply() -> void:
	match quality:
		&"low":
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_DISABLED)
		&"high":
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_4X)
		_:
			RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), RenderingServer.VIEWPORT_MSAA_2X)
