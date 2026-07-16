extends Node

signal volume_changed(bus_name: StringName, linear_value: float)

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "audio"
const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const EFFECTS_BUS: StringName = &"Effects"
const SETTING_BUSES: Array[StringName] = [MASTER_BUS, MUSIC_BUS, EFFECTS_BUS]

var volumes: Dictionary[StringName, float] = {}

func _ready() -> void:
	_load()
	_apply_all()


func set_master_volume(linear_value: float) -> void:
	_set_bus_volume(MASTER_BUS, linear_value)


func set_music_volume(linear_value: float) -> void:
	_set_bus_volume(MUSIC_BUS, linear_value)


func set_effects_volume(linear_value: float) -> void:
	_set_bus_volume(EFFECTS_BUS, linear_value)


func get_master_volume() -> float:
	return get_bus_volume(MASTER_BUS)


func get_music_volume() -> float:
	return get_bus_volume(MUSIC_BUS)


func get_effects_volume() -> float:
	return get_bus_volume(EFFECTS_BUS)


func get_bus_volume(bus_name: StringName) -> float:
	return volumes.get(bus_name, 1.0)


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	volumes[bus_name] = clamped
	_apply_bus(bus_name, clamped)
	_save()
	volume_changed.emit(bus_name, clamped)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	volumes.clear()
	if config.load(SETTINGS_PATH) != OK:
		for bus_name: StringName in SETTING_BUSES:
			volumes[bus_name] = 1.0
		return
	for bus_name: StringName in SETTING_BUSES:
		var raw: Variant = config.get_value(SECTION, String(bus_name), 1.0)
		if raw is float:
			var raw_float: float = raw
			volumes[bus_name] = clampf(raw_float, 0.0, 1.0)
		elif raw is int:
			var raw_int: int = raw
			volumes[bus_name] = clampf(float(raw_int), 0.0, 1.0)
		else:
			volumes[bus_name] = 1.0


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	var _previous_state_loaded: int = config.load(SETTINGS_PATH)
	for bus_name: StringName in SETTING_BUSES:
		config.set_value(SECTION, String(bus_name), volumes[bus_name])
	if config.save(SETTINGS_PATH) != OK:
		push_warning("Failed to save audio settings to %s" % SETTINGS_PATH)


func _apply_all() -> void:
	for bus_name: StringName in SETTING_BUSES:
		_apply_bus(bus_name, volumes[bus_name])


func _apply_bus(bus_name: StringName, linear_value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear_value, 0.0001)))
	AudioServer.set_bus_mute(index, linear_value <= 0.0)
